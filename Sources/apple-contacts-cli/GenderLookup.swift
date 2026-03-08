import Foundation
import SQLite3

/// Reads X-GENDER and pronouns (X-CUSTOM) from the macOS AddressBook SQLite database.
/// The CNContact API doesn't expose these fields, so we read them directly.
final class GenderLookup {
    private var genderMap: [String: String] = [:]
    private var pronounsMap: [String: String] = [:]

    init() {
        loadFromDB()
    }

    /// Look up gender for a CNContact identifier (e.g. "F73437D8-...:ABPerson").
    /// Returns "male", "female", or "non-binary".
    func gender(for identifier: String) -> String? {
        if let g = genderMap[identifier] { return g }
        // Infer from pronouns if X-GENDER not set
        if let p = pronounsMap[identifier] {
            return genderFromPronouns(p)
        }
        return nil
    }

    /// Look up pronouns for a CNContact identifier.
    /// Returns the raw value, e.g. "They/Them/Theirs", "She/Her/Hers".
    func pronouns(for identifier: String) -> String? {
        pronounsMap[identifier]
    }

    private func genderFromPronouns(_ pronouns: String) -> String? {
        let lower = pronouns.lowercased()
        if lower.hasPrefix("he/") { return "male" }
        if lower.hasPrefix("she/") { return "female" }
        if lower.hasPrefix("they/") { return "non-binary" }
        return nil
    }

    private func loadFromDB() {
        let sourcesDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/AddressBook/Sources")

        guard let enumerator = FileManager.default.enumerator(
            at: sourcesDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return }

        var dbPaths: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            if url.lastPathComponent == "AddressBook-v22.abcddb" {
                dbPaths.append(url)
                enumerator.skipDescendants()
            }
        }

        for dbPath in dbPaths {
            loadFromDB(dbPath)
        }
    }

    private func loadFromDB(_ url: URL) {
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return
        }
        defer { sqlite3_close(db) }

        let sql = """
            SELECT r.ZUNIQUEID, u.ZPROPERTYNAME, u.ZORIGINALLINE
            FROM ZABCDUNKNOWNPROPERTY u
            JOIN ZABCDRECORD r ON u.ZOWNER = r.Z_PK
            WHERE u.ZPROPERTYNAME IN ('X-GENDER', 'X-CUSTOM')
            """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return
        }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let idPtr = sqlite3_column_text(stmt, 0),
                  let propPtr = sqlite3_column_text(stmt, 1),
                  let linePtr = sqlite3_column_text(stmt, 2) else { continue }

            let identifier = String(cString: idPtr)
            let prop = String(cString: propPtr)
            let line = String(cString: linePtr)

            if prop == "X-GENDER" {
                // e.g. "X-GENDER:Male"
                if let colonIdx = line.firstIndex(of: ":") {
                    let value = line[line.index(after: colonIdx)...]
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                    if value == "male" || value == "female" {
                        genderMap[identifier] = value
                    }
                }
            } else if prop == "X-CUSTOM" {
                // e.g. "X-CUSTOM:pronouns-=+=-They/Them/Theirs"
                let delimiter = "pronouns-=+=-"
                if let range = line.range(of: delimiter) {
                    let value = line[range.upperBound...]
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !value.isEmpty {
                        pronounsMap[identifier] = value
                    }
                }
            }
        }
    }
}
