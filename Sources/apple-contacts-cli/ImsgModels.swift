import Foundation

/// Represents a message object from `imsg history --json` output (NDJSON).
struct ImsgMessage: Codable {
    var sender: String?
    var participants: [String]?
    var text: String?
    var date: String?
    var isFromMe: Bool?

    /// Capture all remaining fields so we pass them through unchanged.
    private var extra: [String: AnyCodable] = [:]

    private enum CodingKeys: String, CodingKey {
        case sender, participants, text, date, isFromMe
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)

        sender = try container.decodeIfPresent(String.self, forKey: DynamicKey("sender"))
        participants = try container.decodeIfPresent([String].self, forKey: DynamicKey("participants"))
        text = try container.decodeIfPresent(String.self, forKey: DynamicKey("text"))
        date = try container.decodeIfPresent(String.self, forKey: DynamicKey("date"))
        isFromMe = try container.decodeIfPresent(Bool.self, forKey: DynamicKey("isFromMe"))

        let knownKeys: Set = ["sender", "participants", "text", "date", "isFromMe"]
        for key in container.allKeys where !knownKeys.contains(key.stringValue) {
            extra[key.stringValue] = try container.decode(AnyCodable.self, forKey: key)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        try container.encodeIfPresent(sender, forKey: DynamicKey("sender"))
        try container.encodeIfPresent(participants, forKey: DynamicKey("participants"))
        try container.encodeIfPresent(text, forKey: DynamicKey("text"))
        try container.encodeIfPresent(date, forKey: DynamicKey("date"))
        try container.encodeIfPresent(isFromMe, forKey: DynamicKey("isFromMe"))
        for (key, value) in extra {
            try container.encode(value, forKey: DynamicKey(key))
        }
    }
}

// MARK: - Helpers

struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int? {
        nil
    }

    init(_ string: String) {
        stringValue = string
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue _: Int) {
        nil
    }
}

/// Type-erased Codable wrapper for arbitrary JSON values.
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            try container.encodeNil()
        }
    }
}
