#if WEB_AUTH_PLATFORM
import Foundation

class LoginTransaction: NSObject, AuthTransaction {

    typealias FinishTransaction = (WebAuthResult<Credentials>) -> Void

    private(set) var userAgent: WebAuthUserAgent?
    let redirectURL: URL
    let state: String?
    let handler: OAuth2Grant
    let logger: Logger?
    let callback: FinishTransaction

    init(redirectURL: URL,
         state: String? = nil,
         userAgent: WebAuthUserAgent,
         handler: OAuth2Grant,
         logger: Logger?,
         callback: @escaping FinishTransaction) {
        self.redirectURL = redirectURL
        self.state = state
        self.userAgent = userAgent
        self.handler = handler
        self.logger = logger
        self.callback = userAgent.wrap(callback: callback)
        super.init()
    }

    func cancel() {
        self.callback(.failure(WebAuthError(code: .userCancelled)))
        self.userAgent?.cancel()
        self.userAgent = nil
    }

    func resume(_ url: URL) -> Bool {
        self.logger?.trace(url: url, source: "Callback URL")
        if self.handleURL(url) {
            self.userAgent?.cancel()
            self.userAgent = nil
            return true
        }
        return false
    }

    private func handleURL(_ url: URL) -> Bool {
        guard url.absoluteString.lowercased().hasPrefix(self.redirectURL.absoluteString.lowercased()) else { return false }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            let error = WebAuthError(code: .unknown("Invalid callback URL: \(url.absoluteString)"))
            self.callback(.failure(error))
            return false
        }
        let items = self.handler.values(fromComponents: components)
        guard has(state: self.state, inItems: items) else { return false }
        if items["error"] != nil {
            self.callback(.failure(WebAuthError(code: .other, cause: AuthenticationError(info: items))))
        } else {
            self.handler.credentials(from: items, callback: self.callback)
        }
        return true
    }

    private func has(state: String?, inItems items: [String: String]) -> Bool {
        return state == nil || items["state"] == state
    }

}
#endif
