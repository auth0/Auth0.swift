#if WEB_AUTH_PLATFORM
import AuthenticationServices

typealias ASHandler = ASWebAuthenticationSession.CompletionHandler

extension WebAuthentication {

    static func asProvider(redirectURL: URL,
                           ephemeralSession: Bool = false,
                           headers: [String: String]? = nil) -> WebAuthProvider {
        return { url, callback in
            let session: ASWebAuthenticationSession

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

            session.prefersEphemeralWebBrowserSession = ephemeralSession

            Task {
                await ASUserAgent(session: session, callback: callback)
            }
        }
    }

    static let completionHandler: @Sendable (_ callback: @escaping WebAuthProviderCallback) -> ASHandler = { callback in
        return { url,error in
            Task {
                guard let callbackURL = url, error == nil else {
                    if let error = error as? NSError,
                       error.userInfo.isEmpty,
                       case ASWebAuthenticationSessionError.canceledLogin = error {
                        return callback(.failure(WebAuthError(code: .userCancelled)))
                    } else if let error = error {
                        return callback(.failure(WebAuthError(code: .other, cause: error)))
                    }
                    
                    return callback(.failure(WebAuthError(code: .unknown("ASWebAuthenticationSession failed"))))
                }
                
                _ = await TransactionStore.shared.resume(callbackURL)
            }
        }
    }
}

@MainActor final class ASUserAgent: NSObject, WebAuthUserAgent {

    private(set) static var currentSession: ASWebAuthenticationSession?
    let callback: WebAuthProviderCallback

    init(session: ASWebAuthenticationSession, callback: @escaping @Sendable WebAuthProviderCallback) async {
        self.callback = callback
        super.init()

        session.presentationContextProvider = self
        await initializeSession(session: session)
    }

    func initializeSession(session: ASWebAuthenticationSession) async {
        ASUserAgent.currentSession = session
    }

    func start() async {
        _ = ASUserAgent.currentSession?.start()
    }

    func finish(with result: WebAuthResult<Void>) async {
        ASUserAgent.currentSession?.cancel()
        self.callback(result)
    }

    public nonisolated override var description: String {
        return String(describing: ASWebAuthenticationSession.self)
    }

}
#endif
