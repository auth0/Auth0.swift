#if WEB_AUTH_PLATFORM
import AuthenticationServices

extension WebAuthentication {

    static func asProvider(redirectURL: URL, ephemeralSession: Bool = false) -> WebAuthProvider {
        return { url, callback in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: redirectURL.scheme) {
                guard let callbackURL = $0, $1 == nil else {
                    callback(.failure(WebAuthError(from: $1)))
                    return TransactionStore.shared.clear()
                }

                _ = TransactionStore.shared.resume(callbackURL)
            }

            if #available(iOS 13.0, *) {
                session.prefersEphemeralWebBrowserSession = ephemeralSession
            }

            return ASUserAgent(session: session, callback: callback)
        }
    }

}

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

class ASUserAgent: NSObject, WebAuthUserAgent {

    let session: ASWebAuthenticationSession
    let callback: (WebAuthResult<Void>) -> Void

    init(session: ASWebAuthenticationSession, callback: @escaping (WebAuthResult<Void>) -> Void) {
        self.session = session
        self.callback = callback
        super.init()

        if #available(iOS 13.0, *) {
            session.presentationContextProvider = self
        }
    }

    func start() {
        _ = self.session.start()
    }

    func finish() -> (WebAuthResult<Void>) -> Void {
        return { [callback] result in
            callback(result)
        }
    }

    public override var description: String {
        return String(describing: ASWebAuthenticationSession.self)
    }

}
#endif
