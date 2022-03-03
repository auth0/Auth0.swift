#if WEB_AUTH_PLATFORM
import Foundation

class ClearSessionTransaction: NSObject, AuthTransaction {

    private(set) var userAgent: WebAuthUserAgent?
    let callback: (WebAuthResult<Void>) -> Void

    init(userAgent: WebAuthUserAgent, callback: @escaping (WebAuthResult<Void>) -> Void) {
        self.userAgent = userAgent
        self.callback = userAgent.wrap(callback: callback)
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
