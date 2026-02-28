import Contacts
import Foundation

struct ContactStore {
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
            let sema = DispatchSemaphore(value: 0)
            var granted = false
            CNContactStore().requestAccess(for: .contacts) { ok, _ in
                granted = ok
                sema.signal()
            }
            sema.wait()
            if !granted {
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
