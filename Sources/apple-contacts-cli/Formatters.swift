import Foundation

enum OutputFormat: String, CaseIterable {
    case json
    case ndjson
    case text
}

// MARK: - Lookup mode

func runLookup(queries: [String], format: OutputFormat, resolver: Resolver, mode: LookupMode) {
    let results = resolver.resolveAll(queries, mode: mode)

    switch format {
    case .json:
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(results),
           let str = String(data: data, encoding: .utf8) {
            print(str)
        }

    case .ndjson:
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        for item in results {
            if let data = try? encoder.encode(item),
               let str = String(data: data, encoding: .utf8) {
                print(str)
            }
        }

    case .text:
        for item in results {
            var parts = [item.query, item.name ?? ""]
            if let phones = item.phones {
                parts.append(phones.joined(separator: ","))
            }
            if let emails = item.emails {
                parts.append(emails.joined(separator: ","))
            }
            parts.append(item.birthday ?? "")
            parts.append(item.city ?? "")
            parts.append(item.organization ?? "")
            parts.append(item.gender ?? "")
            parts.append(item.pronouns ?? "")
            print(parts.joined(separator: "\t"))
        }
    }
}

// MARK: - Enrich mode (NDJSON from stdin)

func enrichMessage(_ message: inout ImsgMessage, resolver: Resolver) {
    if let senderPhone = message.sender, !senderPhone.isEmpty {
        if let name = resolver.resolve(senderPhone) {
            message.sender = name
        }
    }

    if let participants = message.participants {
        message.participants = participants.map { phone in
            resolver.resolve(phone) ?? phone
        }
    }

    if let destPhone = message.destinationCallerId, !destPhone.isEmpty {
        if let name = resolver.resolve(destPhone) {
            message.destinationCallerId = name
        }
    }
}

func runEnrich(format: OutputFormat, resolver: Resolver) {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    while let line = readLine(strippingNewline: true) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let data = trimmed.data(using: .utf8) else { continue }

        guard var message = try? decoder.decode(ImsgMessage.self, from: data) else {
            print(trimmed)
            continue
        }

        enrichMessage(&message, resolver: resolver)

        guard let outData = try? encoder.encode(message),
              let outStr = String(data: outData, encoding: .utf8) else { continue }

        switch format {
        case .json, .ndjson:
            print(outStr)
        case .text:
            let sender = message.sender ?? ""
            let text = message.text ?? ""
            print("\(sender)\t\(text)")
        }
    }
}
