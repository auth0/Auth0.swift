#if WEB_AUTH_PLATFORM
import AuthenticationServices

fileprivate extension WebAuthError {

    init(from error: Error?) {
        if let error = error, case ASWebAuthenticationSessionError.canceledLogin = error {
            self.init(code: .userCancelled)
        } else if let error = error {
            self.init(code: .other, cause: error)
        } else {
            self.init(code: .unknown("ASWebAuthenticationSession failed"))
        }
    }

}

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
            guard let callbackURL = $0, $1 == nil else {
                callback(.failure(WebAuthError(from: $1)))
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
                callback(.failure(WebAuthError(from: $1)))
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
