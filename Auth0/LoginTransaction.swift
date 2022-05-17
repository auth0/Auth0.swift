#if WEB_AUTH_PLATFORM
import Foundation

class LoginTransaction: NSObject, AuthTransaction {

    typealias FinishTransaction = (WebAuthResult<Credentials>) -> Void

    private(set) var userAgent: WebAuthUserAgent?
    private(set) var userAgentCallback: ((WebAuthResult<Void>) -> Void)?
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
        self.logger?.trace(url: url, source: "Callback URL")
        return self.handleURL(url)
    }

    private func handleURL(_ url: URL) -> Bool {
        guard url.absoluteString.lowercased().hasPrefix(self.redirectURL.absoluteString.lowercased()),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              case let items = self.handler.values(fromComponents: components),
              has(state: self.state, inItems: items) else {
                  let error = WebAuthError(code: .unknown("Invalid callback URL: \(url.absoluteString)"))
                  self.finishUserAgent(.failure(error))
                  return false
        }

        if items["error"] != nil {
            let error = WebAuthError(code: .other, cause: AuthenticationError(info: items))
            self.finishUserAgent(.failure(error))
        } else {
            self.finishUserAgent(.success(()))
            self.handler.credentials(from: items, callback: self.callback)
        }
        return true
    }

    private func finishUserAgent(_ result: WebAuthResult<Void>) {
        self.userAgentCallback?(result)
        self.userAgent = nil
        self.userAgentCallback = nil
    }

    private func has(state: String?, inItems items: [String: String]) -> Bool {
        return state == nil || items["state"] == state
    }

}
#endif
