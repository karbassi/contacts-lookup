import Contacts
import Foundation

struct ContactStore: @unchecked Sendable {
    let store: CNContactStore

    static let shared = ContactStore()

    private init() {
        store = CNContactStore()
    }

    static func requestAccessOrExit() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized:
            return
        case .notDetermined:
            final class Result: @unchecked Sendable { var granted = false }
            let sema = DispatchSemaphore(value: 0)
            let result = Result()
            CNContactStore().requestAccess(for: .contacts) { isGranted, _ in
                result.granted = isGranted
                sema.signal()
            }
            sema.wait()
            if !result.granted {
                fputs("error: contacts access denied\n", stderr)
                exit(1)
            }
        case .denied, .restricted:
            fputs("""
            error: contacts access denied.
            Grant access in System Settings → Privacy & Security → Contacts.
            If running a sandboxed build, ensure NSContactsUsageDescription is set in Info.plist.
            \n
            """, stderr)
            exit(1)
        @unknown default:
            fputs("error: unknown contacts authorization status\n", stderr)
            exit(1)
        }
    }
}
