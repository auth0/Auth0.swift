#if WEB_AUTH_PLATFORM
import AuthenticationServices

typealias ASHandler = ASWebAuthenticationSession.CompletionHandler

public extension WebAuthentication {

    /// Creates a Web Auth provider that uses `ASWebAuthenticationSession` as the external user agent.
    ///
    /// This is the default provider used by Web Auth. You can use this method to explicitly configure
    /// ephemeral sessions.
    ///
    /// ## Usage
    ///
    /// Default ASWebAuthenticationSession:
    ///
    /// ```swift
    /// Auth0
    ///     .webAuth()
    ///     .provider(WebAuthentication.asProvider())
    ///     .start { result in
    ///         // ...
    ///     }
    /// ```
    ///
    /// With ephemeral session (no SSO):
    ///
    /// ```swift
    /// Auth0
    ///     .webAuth()
    ///     .provider(WebAuthentication.asProvider(ephemeralSession: true))
    ///     .start { result in
    ///         // ...
    ///     }
    /// ```
    ///
    /// - Parameter ephemeralSession: If the session should not be shared with the system browser. Using this will disable
    ///   single sign-on (SSO). Defaults to `false`.
    /// - Returns: A ``WebAuthProvider`` instance that uses `ASWebAuthenticationSession`.
    /// - Important: You don't need to call ``WebAuth/clearSession(federated:callback:)`` if you are using
    /// ephemeral sessions on login, because there will be no shared cookie to remove.
    ///
    /// ## See Also
    ///
    /// - <doc:UserAgents>
    /// - [FAQ](https://github.com/auth0/Auth0.swift/blob/master/FAQ.md)
    /// - [prefersEphemeralWebBrowserSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/3237231-prefersephemeralwebbrowsersessio)
    static func asProvider(ephemeralSession: Bool = false) -> WebAuthProvider {
        return { url, callback in
            // Extract redirect_uri from the authorization URL
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                  let redirectURIString = components.queryItems?.first(where: { $0.name == "redirect_uri" })?.value,
                  let redirectURL = URL(string: redirectURIString) else {
                fatalError("Could not extract redirect_uri from authorization URL")
            }
            
            return asProvider(redirectURL: redirectURL, ephemeralSession: ephemeralSession, headers: nil)(url, callback)
        }
    }

}

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
        ASUserAgent.currentSession = nil
        self.callback(result)
    }

    public override var description: String {
        return String(describing: ASWebAuthenticationSession.self)
    }

}
#endif
