import Foundation

enum OutputFormat: String, CaseIterable {
    case json
    case text
}

// MARK: - Lookup mode (phone numbers → names)

func runLookup(phones: [String], format: OutputFormat, resolver: Resolver) {
    let results = resolver.resolveAll(phones)

    switch format {
    case .json:
        let objects: [[String: String]] = results.map { item in
            ["phone": item.phone, "name": item.name ?? ""]
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(objects),
           let str = String(data: data, encoding: .utf8) {
            print(str)
        }

    case .text:
        for item in results {
            print("\(item.phone)\t\(item.name ?? "")")
        }
    }
}

// MARK: - Enrich mode (NDJSON from stdin)

func runEnrich(format: OutputFormat, resolver: Resolver) {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    while let line = readLine(strippingNewline: true) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let data = trimmed.data(using: .utf8) else { continue }

        guard var message = try? decoder.decode(ImsgMessage.self, from: data) else {
            // Pass through lines we can't parse
            print(trimmed)
            continue
        }

        // Enrich sender
        if let senderPhone = message.sender, !senderPhone.isEmpty {
            if let name = resolver.resolve(senderPhone) {
                message.sender = name
            }
        }

        // Enrich participants
        if let participants = message.participants {
            message.participants = participants.map { phone in
                resolver.resolve(phone) ?? phone
            }
        }

        guard let outData = try? encoder.encode(message),
              let outStr = String(data: outData, encoding: .utf8) else { continue }

        switch format {
        case .json:
            print(outStr)
        case .text:
            let sender = message.sender ?? ""
            let text = message.text ?? ""
            print("\(sender)\t\(text)")
        }
    }
}
