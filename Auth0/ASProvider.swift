#if WEB_AUTH_PLATFORM
import AuthenticationServices

typealias ASHandler = ASWebAuthenticationSession.CompletionHandler

extension WebAuthentication {
    @MainActor
    static func asProvider(redirectURL: URL,
                           ephemeralSession: Bool = false,
                           headers: [String: String]? = nil,
                           presentationWindow: Auth0WindowRepresentable? = nil) -> WebAuthProvider {
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

            return ASUserAgent(session: session, callback: callback, presentationWindow: presentationWindow)
        }
    }

    static let completionHandler: @Sendable (_ callback: @escaping WebAuthProviderCallback) -> ASHandler = { callback in
        return { url, error in
            Task { @MainActor in
                guard let callbackURL = url, error == nil else {
                    if let error = error as? NSError,
                        error.userInfo.isEmpty,
                        case ASWebAuthenticationSessionError.canceledLogin = error {
                        return callback(.failure(WebAuthError(code: .userCancelled)))
                    } else if let error {
                        return callback(.failure(WebAuthError(code: .other, cause: error)))
                    }

                    return callback(.failure(WebAuthError(code: .unknown("ASWebAuthenticationSession failed"))))
                }
                _ = TransactionStore.shared.resume(callbackURL)
            }
        }
    }
}

final class ASUserAgent: NSObject, WebAuthUserAgent, Sendable {

    @MainActor
    private(set) static var currentSession: ASWebAuthenticationSession?
    let callback: WebAuthProviderCallback

    @MainActor
    weak var presentationWindow: Auth0WindowRepresentable?

    @MainActor
    init(session: ASWebAuthenticationSession,
         callback: @escaping WebAuthProviderCallback,
         presentationWindow: Auth0WindowRepresentable? = nil) {
        self.callback = callback
        self.presentationWindow = presentationWindow
        super.init()

        session.presentationContextProvider = self
        ASUserAgent.currentSession = session
    }


    func start() {
        Task {
            @MainActor in
            _ = ASUserAgent.currentSession?.start()
        }
    }
    
    func finish(with result: WebAuthResult<Void>) {
        Task {
            @MainActor in
            ASUserAgent.currentSession?.cancel()
            ASUserAgent.currentSession = nil
            self.callback(result)
        }
    }

    public override var description: String {
        return String(describing: ASWebAuthenticationSession.self)
    }

}

#endif
