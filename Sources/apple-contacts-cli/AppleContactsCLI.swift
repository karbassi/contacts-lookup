import ArgumentParser
import Darwin
import Foundation

enum LookupMode: String, CaseIterable {
    case phone
    case name
    case email
}

struct AppleContactsCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apple-contacts-cli",
        abstract: "Look up contacts by phone number, name, or email from macOS Contacts.",
        discussion: """
        Phone lookup is the default. Use --name or --email to search by other fields.
        Queries can also be piped via stdin (one per line) when no arguments are given.
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

    @Option(name: .long, help: "Output format: json (default), ndjson (one object per line), or text (tab-separated).")
    var format: String = "json"

    var lookupMode: LookupMode {
        if name { return .name }
        if email { return .email }
        return .phone
    }

    func validate() throws {
        let validFormats = ["json", "ndjson", "text"]
        guard validFormats.contains(format) else {
            throw ValidationError("--format must be one of: \(validFormats.joined(separator: ", "))")
        }
        if name, email {
            throw ValidationError("--name and --email are mutually exclusive.")
        }
        if enrich, name || email {
            throw ValidationError("--name and --email cannot be used with --enrich.")
        }
        if enrich, !queries.isEmpty {
            throw ValidationError("--enrich reads from stdin; do not pass arguments when using it.")
        }
    }

    func run() throws {
        let outputFormat = OutputFormat(rawValue: format) ?? .json

        if enrich {
            ContactStore.requestAccessOrExit()
            let resolver = Resolver()
            runEnrich(format: outputFormat, resolver: resolver)
        } else {
            var effectiveQueries = queries
            if effectiveQueries.isEmpty {
                guard isatty(fileno(stdin)) == 0 else {
                    throw CleanExit.helpRequest(self)
                }
                while let line = readLine(strippingNewline: true) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        effectiveQueries.append(trimmed)
                    }
                }
                guard !effectiveQueries.isEmpty else {
                    throw ValidationError("No queries provided via arguments or stdin.")
                }
            }
            ContactStore.requestAccessOrExit()
            let resolver = Resolver()
            runLookup(queries: effectiveQueries, format: outputFormat, resolver: resolver, mode: lookupMode)
        }
    }
}
