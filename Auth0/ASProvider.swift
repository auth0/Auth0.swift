#if WEB_AUTH_PLATFORM
import AuthenticationServices

extension WebAuthentication {

    static func asProvider(urlScheme: String, ephemeralSession: Bool = false) -> WebAuthProvider {
        return { url, callback in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: urlScheme) {
                guard let callbackURL = $0, $1 == nil else {
                    if let error = $1, case ASWebAuthenticationSessionError.canceledLogin = error {
                        return callback(.failure(WebAuthError(code: .userCancelled)))
                    } else if let error = $1 {
                        return callback(.failure(WebAuthError(code: .other, cause: error)))
                    }

                    return callback(.failure(WebAuthError(code: .unknown("ASWebAuthenticationSession failed"))))
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

    func finish(with result: WebAuthResult<Void>) {
        self.session.cancel()
        self.callback(result)
    }

    public override var description: String {
        return String(describing: ASWebAuthenticationSession.self)
    }

}
#endif
