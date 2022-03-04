#if WEB_AUTH_PLATFORM
import AuthenticationServices

class ASProvider: NSObject {
    let ephemeralSession: Bool
    let redirectURL: URL

    init(ephemeralSession: Bool, redirectURL: URL) {
        self.ephemeralSession = ephemeralSession
        self.redirectURL = redirectURL
        super.init()
    }

    func login(url: URL, callback: @escaping(WebAuthResult<Void>) -> Void) -> WebAuthUserAgent {
        let userAgent = ASWebAuthenticationSession(url: url,
                                                   callbackURLScheme: self.redirectURL.scheme) {
            guard $1 == nil, let callbackURL = $0 else {
                if let authError = $1, case ASWebAuthenticationSessionError.canceledLogin = authError {
                    callback(.failure(WebAuthError(code: .userCancelled)))
                } else {
                    callback(.failure(WebAuthError(code: .unknown("ASWebAuthenticationSession failed"))))
                }
                return TransactionStore.shared.clear()
            }
            _ = TransactionStore.shared.resume(callbackURL)
        }

        if #available(iOS 13.0, *) {
            userAgent.presentationContextProvider = self
            userAgent.prefersEphemeralWebBrowserSession = ephemeralSession
        }

        return userAgent
    }

    func clearSession(url: URL, callback: @escaping(WebAuthResult<Void>) -> Void) -> WebAuthUserAgent {
        let userAgent = ASWebAuthenticationSession(url: url,
                                                   callbackURLScheme: self.redirectURL.scheme) {
            guard $0 != nil, $1 == nil else {
                if let authError = $1, case ASWebAuthenticationSessionError.canceledLogin = authError {
                    callback(.failure(WebAuthError(code: .userCancelled)))
                } else {
                    callback(.failure(WebAuthError(code: .unknown("ASWebAuthenticationSession failed"))))
                }
                return TransactionStore.shared.clear()
            }
            callback(.success(()))
            TransactionStore.shared.clear()
        }

        if #available(iOS 13.0, *) {
            userAgent.presentationContextProvider = self
        }

        return userAgent
    }

}

extension ASWebAuthenticationSession: WebAuthUserAgent {

    public func start() {
        let _: Bool = self.start()
    }

    public override var description: String {
        return String(describing: ASWebAuthenticationSession.self)
    }

}
#endif
