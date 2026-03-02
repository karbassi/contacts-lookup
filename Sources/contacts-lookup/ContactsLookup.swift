import ArgumentParser
import Foundation

enum LookupMode: String, CaseIterable {
    case phone
    case name
    case email
}

struct ContactsLookup: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "contacts-lookup",
        abstract: "Look up contacts by phone number, name, or email from macOS Contacts.",
        discussion: """
        Phone lookup is the default. Use --name or --email to search by other fields.
        Use --enrich to pipe NDJSON from `imsg history --json` via stdin.
        """
    )

    @Argument(help: "Queries to look up. Phone numbers by default; use --name or --email to change.")
    var queries: [String] = []

    @Flag(name: .long, help: "Search by contact name.")
    var name: Bool = false

    @Flag(name: .long, help: "Search by email address.")
    var email: Bool = false

    @Flag(name: .long, help: "Read NDJSON from stdin and enrich sender/participants with contact names.")
    var enrich: Bool = false

    @Option(name: .long, help: "Output format: json (default) or text (tab-separated).")
    var format: String = "json"

    var lookupMode: LookupMode {
        if name { return .name }
        if email { return .email }
        return .phone
    }

    func validate() throws {
        let validFormats = ["json", "text"]
        guard validFormats.contains(format) else {
            throw ValidationError("--format must be one of: \(validFormats.joined(separator: ", "))")
        }
        if name, email {
            throw ValidationError("--name and --email are mutually exclusive.")
        }
        if enrich, name || email {
            throw ValidationError("--name and --email cannot be used with --enrich.")
        }
        if !enrich, queries.isEmpty {
            throw ValidationError(
                "Provide at least one query, or use --enrich to read from stdin."
            )
        }
        if enrich, !queries.isEmpty {
            throw ValidationError("--enrich reads from stdin; do not pass arguments when using it.")
        }
    }

    func run() throws {
        ContactStore.requestAccessOrExit()

        let outputFormat = OutputFormat(rawValue: format) ?? .json
        let resolver = Resolver()

        if enrich {
            runEnrich(format: outputFormat, resolver: resolver)
        } else {
            runLookup(queries: queries, format: outputFormat, resolver: resolver, mode: lookupMode)
        }
    }
}
