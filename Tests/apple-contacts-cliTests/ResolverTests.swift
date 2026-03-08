import Contacts
@testable import apple_contacts_cli
import XCTest

// MARK: - Mock store

final class MockContactStore: ContactStoreProtocol {
    /// Maps a phone number (as matched by CNPhoneNumber) to a list of contacts to return.
    var contactsByPhone: [String: [CNMutableContact]] = [:]

    func unifiedContacts(
        matching predicate: NSPredicate,
        keysToFetch _: [CNKeyDescriptor]
    ) throws -> [CNContact] {
        // CNContact.predicateForContacts(matching:) embeds the digits-only form of the number.
        // We match loosely: return any entry whose key appears in the predicate description.
        for (phone, contacts) in contactsByPhone where predicate.description.contains(phone.filter(\.isNumber)) {
            return contacts
        }
        return []
    }

    static func makeContact(givenName: String, familyName: String, phone: String) -> CNMutableContact {
        let contact = CNMutableContact()
        contact.givenName = givenName
        contact.familyName = familyName
        contact.phoneNumbers = [
            CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phone))
        ]
        return contact
    }
}

// MARK: - Tests

final class ResolverTests: XCTestCase {
    func testResolveKnownNumber() {
        let store = MockContactStore()
        store.contactsByPhone["+14155551212"] = [
            MockContactStore.makeContact(givenName: "Jane", familyName: "Doe", phone: "+14155551212")
        ]

        let resolver = Resolver(store: store)
        XCTAssertEqual(resolver.resolve("+14155551212"), "Jane Doe")
    }

    func testResolveUnknownNumberReturnsNil() {
        let resolver = Resolver(store: MockContactStore())
        XCTAssertNil(resolver.resolve("+19999999999"))
    }

    func testResolveTrimsWhitespace() {
        let store = MockContactStore()
        store.contactsByPhone["+14155551212"] = [
            MockContactStore.makeContact(givenName: "Jane", familyName: "Doe", phone: "+14155551212")
        ]

        let resolver = Resolver(store: store)
        XCTAssertEqual(resolver.resolve("  +14155551212  "), "Jane Doe")
    }

    func testResolverCachesLookups() {
        let store = MockContactStore()
        store.contactsByPhone["+14155551212"] = [
            MockContactStore.makeContact(givenName: "Jane", familyName: "Doe", phone: "+14155551212")
        ]

        let resolver = Resolver(store: store)

        // First call populates cache
        _ = resolver.resolve("+14155551212")

        // Remove from store — second call should still return from cache
        store.contactsByPhone.removeAll()
        XCTAssertEqual(resolver.resolve("+14155551212"), "Jane Doe")
    }

    func testResolveAll() {
        let store = MockContactStore()
        store.contactsByPhone["+14155551212"] = [
            MockContactStore.makeContact(givenName: "Jane", familyName: "Doe", phone: "+14155551212")
        ]

        let resolver = Resolver(store: store)
        let results = resolver.resolveAll(["+14155551212", "+19999999999"], mode: .phone)

        XCTAssertEqual(results[0].query, "+14155551212")
        XCTAssertEqual(results[0].name, "Jane Doe")
        XCTAssertEqual(results[1].query, "+19999999999")
        XCTAssertNil(results[1].name)
    }
}
