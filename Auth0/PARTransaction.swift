#if WEB_AUTH_PLATFORM
import Foundation

/// Transaction that handles the PAR authorization flow callback.
/// Parses the redirect URL for the authorization code and optional state.
class PARTransaction: NSObject, AuthTransaction {

    typealias FinishTransaction = (WebAuthResult<AuthorizationCode>) -> Void

    private(set) var userAgent: WebAuthUserAgent?

    let redirectURL: URL
    let callback: FinishTransaction

    init(redirectURL: URL,
         userAgent: WebAuthUserAgent,
         callback: @escaping FinishTransaction) {
        self.redirectURL = redirectURL
        self.userAgent = userAgent
        self.callback = callback
        super.init()
    }

    func cancel() {
        self.finishUserAgent(with: .failure(WebAuthError(code: .userCancelled)))
    }

    func resume(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            self.finishUserAgent(with: .failure(WebAuthError(code: .unknown("Invalid callback URL: \(url.absoluteString)"))))
            return false
        }

        let items = queryItems.reduce(into: [String: String]()) { result, item in
            result[item.name] = item.value
        }

        if let error = items["error"] {
            let description = items["error_description"] ?? "Unknown error"
            let cause = AuthenticationError(info: items, statusCode: 302)
            self.finishUserAgent(with: .failure(WebAuthError(code: .other, cause: cause)))
        } else if let code = items["code"] {
            self.finishUserAgent(with: .success(()))
            let authorizationCode = AuthorizationCode(code: code, state: items["state"])
            self.callback(.success(authorizationCode))
            return true
        } else {
            self.finishUserAgent(with: .failure(WebAuthError(code: .noAuthorizationCode(items))))
        }

        return true
    }

    private func finishUserAgent(with result: WebAuthResult<Void>) {
        self.userAgent?.finish(with: result)
        self.userAgent = nil
    }

}
#endif
