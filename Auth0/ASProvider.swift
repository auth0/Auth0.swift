#if WEB_AUTH_PLATFORM
import AuthenticationServices

typealias ASHandler = ASWebAuthenticationSession.CompletionHandler

extension WebAuthentication {

    static func asProvider(redirectURL: URL,
                           ephemeralSession: Bool = false,
                           headers: [String: String]? = nil) -> WebAuthProvider {
        return { url, callback in
            let session: ASWebAuthenticationSession

            #if compiler(>=5.10)
            if #available(iOS 17.4, macOS 14.4, visionOS 1.2, *) {
                if redirectURL.scheme == "https" {
                    session = ASWebAuthenticationSession(url: url,
                                                         callback: .https(host: redirectURL.host!,
                                                                          path: redirectURL.path),
                                                         completionHandler: completionHandler(callback))
                } else {
                    session = ASWebAuthenticationSession(url: url,
                                                         callback: .customScheme(redirectURL.scheme!),
                                                         completionHandler: completionHandler(callback))
                }

                session.additionalHeaderFields = headers
            } else {
                session = ASWebAuthenticationSession(url: url,
                                                     callbackURLScheme: redirectURL.scheme,
                                                     completionHandler: completionHandler(callback))
            }
            #else
            session = ASWebAuthenticationSession(url: url,
                                                 callbackURLScheme: redirectURL.scheme,
                                                 completionHandler: completionHandler(callback))
            #endif

            session.prefersEphemeralWebBrowserSession = ephemeralSession

            return ASUserAgent(session: session, callback: callback)
        }
    }

    static let completionHandler: (_ callback: @escaping WebAuthProviderCallback) -> ASHandler = { callback in
        return {
            guard let callbackURL = $0, $1 == nil else {
                if let error = $1 as? NSError,
                    error.userInfo.isEmpty,
                    case ASWebAuthenticationSessionError.canceledLogin = error {
                    return callback(.failure(WebAuthError(code: .userCancelled)))
                } else if let error = $1 {
                    return callback(.failure(WebAuthError(code: .other, cause: error)))
                }

                return callback(.failure(WebAuthError(code: .unknown("ASWebAuthenticationSession failed"))))
            }

            _ = TransactionStore.shared.resume(callbackURL)
        }
    }
}

class ASUserAgent: NSObject, WebAuthUserAgent {

    private(set) static var currentSession: ASWebAuthenticationSession?
    let callback: WebAuthProviderCallback

    init(session: ASWebAuthenticationSession, callback: @escaping WebAuthProviderCallback) {
        self.callback = callback
        super.init()

        session.presentationContextProvider = self
        ASUserAgent.currentSession = session
    }

    func start() {
        _ = ASUserAgent.currentSession?.start()
    }

    func finish(with result: WebAuthResult<Void>) {
        ASUserAgent.currentSession?.cancel()
        self.callback(result)
    }

    public override var description: String {
        return String(describing: ASWebAuthenticationSession.self)
    }

}
#endif
