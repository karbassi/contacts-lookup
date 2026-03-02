import Contacts
import Foundation

struct LookupResult: Encodable {
    let query: String
    let name: String?
    let phones: [String]?
    let emails: [String]?
}

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
        CNContactEmailAddressesKey as CNKeyDescriptor,
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
        let result = lookupByPhone(key)
        cache[key] = result
        return result
    }

    /// Look up contacts by the given mode.
    func resolveAll(_ queries: [String], mode: LookupMode) -> [LookupResult] {
        queries.flatMap { query in
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            switch mode {
            case .phone:
                return [LookupResult(
                    query: trimmed, name: resolve(trimmed), phones: nil, emails: nil
                )]
            case .name:
                return lookupContacts(
                    predicate: CNContact.predicateForContacts(matchingName: trimmed),
                    query: trimmed
                )
            case .email:
                return lookupContacts(
                    predicate: CNContact.predicateForContacts(matchingEmailAddress: trimmed),
                    query: trimmed
                )
            }
        }
    }

    private func lookupByPhone(_ phone: String) -> String? {
        let predicate = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: phone))
        guard let contacts = try? store.unifiedContacts(matching: predicate, keysToFetch: Self.fetchKeys),
              let contact = contacts.first else { return nil }
        return displayName(for: contact)
    }

    private func lookupContacts(predicate: NSPredicate, query: String) -> [LookupResult] {
        guard let contacts = try? store.unifiedContacts(matching: predicate, keysToFetch: Self.fetchKeys) else {
            return [LookupResult(query: query, name: nil, phones: nil, emails: nil)]
        }
        if contacts.isEmpty {
            return [LookupResult(query: query, name: nil, phones: nil, emails: nil)]
        }
        return contacts.compactMap { contact -> LookupResult? in
            guard let fullName = displayName(for: contact) else { return nil }
            let phones = contact.phoneNumbers.map(\.value.stringValue)
            let emails = contact.emailAddresses.map { $0.value as String }
            return LookupResult(
                query: query,
                name: fullName,
                phones: phones.isEmpty ? nil : phones,
                emails: emails.isEmpty ? nil : emails
            )
        }
    }

    private func displayName(for contact: CNContact) -> String? {
        let name = CNContactFormatter.string(from: contact, style: .fullName)
            ?? "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }
}
