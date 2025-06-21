#if WEB_AUTH_PLATFORM
import Foundation

actor ClearSessionTransaction: NSObject, AuthTransaction {

    private(set) var userAgent: WebAuthUserAgent?

    init(userAgent: WebAuthUserAgent) {
        self.userAgent = userAgent
        super.init()
    }

    func cancel() async {
        // The user agent can handle the error
        await self.finishUserAgent(with: .failure(WebAuthError(code: .userCancelled)))
    }

    func resume(_ url: URL) async -> Bool {
        // The user agent can close itself
        await self.finishUserAgent(with: .success(()))
        return true
    }

    private func finishUserAgent(with result: WebAuthResult<Void>) async {
        await userAgent?.finish(with: result)
        userAgent = nil
    }

}
#endif
