#if WEB_AUTH_PLATFORM
import Foundation

class BaseCallbackTransaction: NSObject, AuthTransaction {

    var authSession: AuthSession?
    var state: String?
    let callback: (WebAuthResult<Void>) -> Void

    init(callback: @escaping (WebAuthResult<Void>) -> Void) {
        self.callback = callback
    }

    func cancel() {
        self.callback(.failure(WebAuthError(code: .userCancelled)))
    }

    func resume(_ url: URL) -> Bool {
        self.callback(.success(()))
        return true
    }

}
#endif
