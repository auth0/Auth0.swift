#if WEB_AUTH_PLATFORM
import Foundation

actor LoginTransaction: NSObject, AuthTransaction {

    typealias FinishTransaction = @Sendable (WebAuthResult<Credentials>) -> Void

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
        self.callback = callback
        super.init()
    }

    func cancel() async {
        await self.finishUserAgent(with: .failure(WebAuthError(code: .userCancelled)))
    }

    func resume(_ url: URL) async -> Bool {
        self.logger?.trace(url: url, source: "Callback URL")
        return await self.handleURL(url)
    }

    private func handleURL(_ url: URL) async -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              case let items = self.handler.values(fromComponents: components),
              has(state: self.state, inItems: items) else {
            let error = WebAuthError(code: .unknown("Invalid callback URL: \(url.absoluteString)"))
            // The user agent can handle the error
            await self.finishUserAgent(with: .failure(error))
            return false
        }

        if items["error"] != nil {
            let error = WebAuthError(code: .other, cause: AuthenticationError(info: items))
            // The user agent can handle the error
            await self.finishUserAgent(with: .failure(error))
        } else {
            // The user agent can close itself
            await self.finishUserAgent(with: .success(()))
            // Continue with code exchange
            self.handler.credentials(from: items, callback: self.callback)
        }

        return true
    }

    private func finishUserAgent(with result: WebAuthResult<Void>) async {
        await userAgent?.finish(with: result)
        userAgent = nil
    }

    private func has(state: String?, inItems items: [String: String]) -> Bool {
        return state == nil || items["state"] == state
    }

}
#endif
