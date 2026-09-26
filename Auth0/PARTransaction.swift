#if WEB_AUTH_PLATFORM
import Foundation

/// Transaction that handles the PAR authorization flow callback.
/// Parses the redirect URL for the authorization code and optional state.
final class PARTransaction: AuthTransaction {

    typealias FinishTransaction = @MainActor @Sendable (WebAuthResult<AuthorizationCode>) -> Void

    private(set) var userAgent: WebAuthUserAgent?

    let redirectURL: URL
    let callback: FinishTransaction

    init(redirectURL: URL,
         userAgent: WebAuthUserAgent,
         callback: @escaping FinishTransaction) {
        self.redirectURL = redirectURL
        self.userAgent = userAgent
        self.callback = callback
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

        let callback = self.callback
        if items["error"] != nil {
            let cause = AuthenticationError(info: items, statusCode: 302)
            let error = WebAuthError(code: .other, cause: cause)
            self.finishUserAgent(with: .failure(error))
            Task { @MainActor in callback(.failure(error)) }
        } else if let code = items["code"] {
            self.finishUserAgent(with: .success(()))
            let authorizationCode = AuthorizationCode(code: code, state: items["state"])
            Task { @MainActor in callback(.success(authorizationCode)) }
        } else {
            let error = WebAuthError(code: .unknown("Authorization code missing from callback URL query parameters (\(items))"))
            self.finishUserAgent(with: .failure(error))
            Task { @MainActor in callback(.failure(error)) }
        }

        return true
    }

    private func finishUserAgent(with result: WebAuthResult<Void>) {
        self.userAgent?.finish(with: result)
        self.userAgent = nil
    }

}
#endif
