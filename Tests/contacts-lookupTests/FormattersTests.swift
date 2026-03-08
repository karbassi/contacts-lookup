import Contacts
@testable import contacts_lookup
import XCTest

final class FormattersTests: XCTestCase {
    // MARK: - LookupResult JSON encoding

    func testLookupResultEncodesPhoneOnly() throws {
        let result = LookupResult(query: "+14155551212", name: "Jane Doe", phones: nil, emails: nil, birthday: nil, city: nil, organization: nil, gender: nil, pronouns: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(result)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["query"] as? String, "+14155551212")
        XCTAssertEqual(json["name"] as? String, "Jane Doe")
        XCTAssertNil(json["phones"])
        XCTAssertNil(json["emails"])
    }

    func testLookupResultEncodesWithPhonesAndEmails() throws {
        let result = LookupResult(
            query: "Jane",
            name: "Jane Doe",
            phones: ["+14155551212"],
            emails: ["jane@example.com"],
            birthday: nil,
            city: nil,
            organization: nil,
            gender: nil,
            pronouns: nil
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(result)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["phones"] as? [String], ["+14155551212"])
        XCTAssertEqual(json["emails"] as? [String], ["jane@example.com"])
    }

    func testLookupResultUnknownQueryEncodesNilName() throws {
        let result = LookupResult(query: "+19999999999", name: nil, phones: nil, emails: nil, birthday: nil, city: nil, organization: nil, gender: nil, pronouns: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(result)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["query"] as? String, "+19999999999")
        XCTAssertNil(json["name"] as? String)
    }

    // MARK: - Enrich logic

    func testEnrichReplacesSenderWithName() throws {
        let store = MockContactStore()
        store.contactsByPhone["+14155551212"] = [
            MockContactStore.makeContact(givenName: "Jane", familyName: "Doe", phone: "+14155551212")
        ]
        let resolver = Resolver(store: store)

        var message = try JSONDecoder().decode(
            ImsgMessage.self,
            from: Data(#"{"sender":"+14155551212","text":"hello"}"#.utf8)
        )

        if let senderPhone = message.sender, !senderPhone.isEmpty {
            if let name = resolver.resolve(senderPhone) {
                message.sender = name
            }
        }

        XCTAssertEqual(message.sender, "Jane Doe")
    }

    func testEnrichReplacesParticipantsWithNames() throws {
        let store = MockContactStore()
        store.contactsByPhone["+14155551212"] = [
            MockContactStore.makeContact(givenName: "Jane", familyName: "Doe", phone: "+14155551212")
        ]
        let resolver = Resolver(store: store)

        var message = try JSONDecoder().decode(
            ImsgMessage.self,
            from: Data(#"{"sender":"me","participants":["+14155551212","+19999999999"]}"#.utf8)
        )

        if let participants = message.participants {
            message.participants = participants.map { phone in
                resolver.resolve(phone) ?? phone
            }
        }

        XCTAssertEqual(message.participants, ["Jane Doe", "+19999999999"])
    }

    func testEnrichPreservesUnknownSender() throws {
        let resolver = Resolver(store: MockContactStore())

        var message = try JSONDecoder().decode(
            ImsgMessage.self,
            from: Data(#"{"sender":"+19999999999","text":"hi"}"#.utf8)
        )

        if let senderPhone = message.sender, !senderPhone.isEmpty {
            if let name = resolver.resolve(senderPhone) {
                message.sender = name
            }
        }

        XCTAssertEqual(message.sender, "+19999999999")
    }
}
