import Contacts
import Foundation

/// Abstraction over CNContactStore so tests can inject a mock.
protocol ContactStoreProtocol {
    func unifiedContacts(matching predicate: NSPredicate, keysToFetch keys: [CNKeyDescriptor]) throws -> [CNContact]
}

extension CNContactStore: ContactStoreProtocol {}

final class Resolver {
    private var cache: [String: String?] = [:]
    private let store: ContactStoreProtocol

    private nonisolated(unsafe) static let fetchKeys: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactMiddleNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactNamePrefixKey as CNKeyDescriptor,
        CNContactNameSuffixKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
    ]

    init(store: ContactStoreProtocol = ContactStore.shared.store) {
        self.store = store
    }

    /// Resolve a single phone number to a display name, using cache.
    func resolve(_ phone: String) -> String? {
        let key = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if let cached = cache[key] {
            return cached
        }
        let result = lookup(key)
        cache[key] = result
        return result
    }

    /// Resolve multiple phone numbers, returning an array of (phone, name?) tuples.
    func resolveAll(_ phones: [String]) -> [(phone: String, name: String?)] {
        phones.map { phone in
            let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            return (phone: trimmed, name: resolve(trimmed))
        }
    }

    private func lookup(_ phone: String) -> String? {
        let predicate = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: phone))
        guard let contacts = try? store.unifiedContacts(matching: predicate, keysToFetch: Self.fetchKeys),
              let contact = contacts.first else { return nil }
        let name = CNContactFormatter.string(from: contact, style: .fullName)
            ?? "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }
}
