#if WEB_AUTH_PLATFORM
import Foundation

class ClearSessionTransaction: NSObject, AuthTransaction {

    private(set) var userAgent: WebAuthUserAgent?

    init(userAgent: WebAuthUserAgent) {
        self.userAgent = userAgent
        super.init()
    }

    func cancel() {
        // The user agent can handle the error
        self.finishUserAgent(with: .failure(WebAuthError(code: .userCancelled)))
    }

    func resume(_ url: URL) -> Bool {
        // The user agent can close itself
        self.finishUserAgent(with: .success(()))
        return true
    }

    private func finishUserAgent(with result: WebAuthResult<Void>) {
        self.userAgent?.finish(with: result)
        self.userAgent = nil
    }

}
#endif
