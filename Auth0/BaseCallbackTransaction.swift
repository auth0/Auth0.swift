#if WEB_AUTH_PLATFORM
import Foundation

class BaseCallbackTransaction: NSObject, AuthTransaction {

    var authSession: AuthSession?
    var state: String?
    let callback: (Bool) -> Void

    init(callback: @escaping (Bool) -> Void) {
        self.callback = callback
    }

    func cancel() {
        self.callback(false)
    }

    func resume(_ url: URL) -> Bool {
        self.callback(true)
        return true
    }

}
#endif
