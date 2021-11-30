#if WEB_AUTH_PLATFORM
import AuthenticationServices

final class ASTransaction: BaseTransaction {

    init(authorizeURL: URL,
         redirectURL: URL,
         state: String? = nil,
         handler: OAuth2Grant,
         logger: Logger?,
         ephemeralSession: Bool,
         callback: @escaping FinishTransaction) {
        super.init(redirectURL: redirectURL,
                   state: state,
                   handler: handler,
                   logger: logger,
                   callback: callback)

        let authSession = ASWebAuthenticationSession(url: authorizeURL,
                                                     callbackURLScheme: self.redirectURL.scheme) { [weak self] in
            guard $1 == nil, let callbackURL = $0 else {
                if let authError = $1, case ASWebAuthenticationSessionError.canceledLogin = authError {
                    self?.callback(.failure(WebAuthError(code: .userCancelled)))
                } else {
                    self?.callback(.failure(WebAuthError(code: .unknown("ASWebAuthenticationSession failed"))))
                }
                return TransactionStore.shared.clear()
            }
            _ = TransactionStore.shared.resume(callbackURL)
        }

        if #available(iOS 13.0, *) {
            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = ephemeralSession
        }

        self.authSession = authSession
        authSession.start()
    }

    override var description: String {
        return String(describing: ASWebAuthenticationSession.self)
    }

}

extension ASWebAuthenticationSession: AuthSession {}
#endif
