@testable import apple_contacts_cli
import Contacts
import XCTest

final class FormattersTests: XCTestCase {
    // MARK: - LookupResult JSON encoding

    func testLookupResultEncodesPhoneOnly() throws {
        let result = LookupResult(
            query: "+14155551212",
            name: "Jane Doe",
            phones: nil,
            emails: nil,
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
        let result = LookupResult(
            query: "+19999999999",
            name: nil,
            phones: nil,
            emails: nil,
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

        enrichMessage(&message, resolver: resolver)

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

        enrichMessage(&message, resolver: resolver)

        XCTAssertEqual(message.participants, ["Jane Doe", "+19999999999"])
    }

    func testEnrichReplacesDestinationCallerIdWithName() throws {
        let store = MockContactStore()
        store.contactsByPhone["+19522701020"] = [
            MockContactStore.makeContact(givenName: "Ali", familyName: "K", phone: "+19522701020")
        ]
        let resolver = Resolver(store: store)

        var message = try JSONDecoder().decode(
            ImsgMessage.self,
            from: Data(#"{"sender":"+14155551212","destination_caller_id":"+19522701020","text":"hello"}"#.utf8)
        )

        enrichMessage(&message, resolver: resolver)

        XCTAssertEqual(message.destinationCallerId, "Ali K")
    }

    func testEnrichPreservesUnknownSender() throws {
        let resolver = Resolver(store: MockContactStore())

        var message = try JSONDecoder().decode(
            ImsgMessage.self,
            from: Data(#"{"sender":"+19999999999","text":"hi"}"#.utf8)
        )

        enrichMessage(&message, resolver: resolver)

        XCTAssertEqual(message.sender, "+19999999999")
    }
}
