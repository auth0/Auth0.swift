#if WEB_AUTH_PLATFORM
import Foundation

class ClearSessionTransaction: NSObject, AuthTransaction {

    private(set) var userAgent: WebAuthUserAgent?
    private(set) var userAgentCallback: ((WebAuthResult<Void>) -> Void)?
    let callback: (WebAuthResult<Void>) -> Void

    init(userAgent: WebAuthUserAgent, callback: @escaping (WebAuthResult<Void>) -> Void) {
        self.userAgent = userAgent
        self.callback = callback
        super.init()
        self.userAgentCallback = userAgent.finish { result in
            if case let .failure(error) = result {
                callback(.failure(error))
            }
        }
    }

    func cancel() {
        self.finishUserAgent(.failure(WebAuthError(code: .userCancelled)))
    }

    func resume(_ url: URL) -> Bool {
        self.finishUserAgent(.success(()))
        self.callback(.success(()))
        return true
    }

    private func finishUserAgent(_ result: WebAuthResult<Void>) {
        self.userAgentCallback?(result)
        self.userAgent = nil
        self.userAgentCallback = nil
    }

}
#endif
