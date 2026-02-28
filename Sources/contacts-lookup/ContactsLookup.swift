import ArgumentParser
import Foundation

struct ContactsLookup: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "contacts-lookup",
        abstract: "Resolve phone numbers to contact names from macOS Contacts.",
        discussion: """
        Lookup mode: provide phone numbers as arguments.
        Enrich mode: pipe NDJSON from `imsg history --json` via stdin.
        """
    )

    @Argument(help: "Phone numbers to resolve (e.g. +14155551212). Ignored when --enrich is used.")
    var phones: [String] = []

    @Flag(name: .long, help: "Read NDJSON from stdin and enrich sender/participants with contact names.")
    var enrich: Bool = false

    @Option(name: .long, help: "Output format: json (default) or text (tab-separated).")
    var format: String = "json"

    func validate() throws {
        let validFormats = ["json", "text"]
        guard validFormats.contains(format) else {
            throw ValidationError("--format must be one of: \(validFormats.joined(separator: ", "))")
        }
        if !enrich, phones.isEmpty {
            throw ValidationError("Provide at least one phone number, or use --enrich to read from stdin.")
        }
        if enrich, !phones.isEmpty {
            throw ValidationError("--enrich reads from stdin; do not pass phone number arguments when using it.")
        }
    }

    func run() throws {
        ContactStore.requestAccessOrExit()

        let outputFormat = OutputFormat(rawValue: format) ?? .json
        let resolver = Resolver()

        if enrich {
            runEnrich(format: outputFormat, resolver: resolver)
        } else {
            runLookup(phones: phones, format: outputFormat, resolver: resolver)
        }
    }
}
