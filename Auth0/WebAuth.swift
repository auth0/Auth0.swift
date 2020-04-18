// WebAuth.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import SafariServices
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

/**
 Auth0 component for authenticating with web-based flow

 ```
 Auth0.webAuth()
 ```

 Auth0 domain is loaded from the file `Auth0.plist` in your main bundle with the following content:

 ```
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
	<key>ClientId</key>
	<string>{YOUR_CLIENT_ID}</string>
	<key>Domain</key>
	<string>{YOUR_DOMAIN}</string>
 </dict>
 </plist>
 ```

 - parameter bundle:    bundle used to locate the `Auth0.plist` file. By default is the main bundle

 - returns: Auth0 WebAuth component
 - important: Calling this method without a valid `Auth0.plist` will crash your application
 */
public func webAuth(bundle: Bundle = Bundle.main) -> WebAuth {
    let values = plistValues(bundle: bundle)!
    return webAuth(clientId: values.clientId, domain: values.domain)
}

/**
 Auth0  component for authenticating with web-based flow

 ```
 Auth0.webAuth(clientId: clientId, domain: "samples.auth0.com")
 ```

 - parameter clientId: id of your Auth0 client
 - parameter domain:   name of your Auth0 domain

 - returns: Auth0 WebAuth component
 */
public func webAuth(clientId: String, domain: String) -> WebAuth {
    return Auth0WebAuth(clientId: clientId, url: .a0_url(domain))
}

/// WebAuth Authentication using Auth0
public protocol WebAuthenticatable: Trackable, Loggable {
    var clientId: String { get }
    var url: URL { get }
    var telemetry: Telemetry { get set }

    /**
     For redirect url instead of a custom scheme it will use `https` and Universal Links.

     Before enabling this flag you'll need to configure Universal Links

     - returns: the same WebAuth instance to allow method chaining
     */
    func useUniversalLink() -> Self

    /**
     Specify a connection name to be used to authenticate.

     By default no connection is specified, so the hosted login page will be displayed

     - parameter connection: name of the connection to use

     - returns: the same WebAuth instance to allow method chaining
     */
    func connection(_ connection: String) -> Self

    /**
     Scopes that will be requested during auth

     - parameter scope: a scope value like: `openid email`

     - returns: the same WebAuth instance to allow method chaining
     */
    func scope(_ scope: String) -> Self

    /**
     Provider scopes for oauth2/social connections. e.g. Facebook, Google etc

     - parameter connectionScope: oauth2/social comma separated scope list: `user_friends,email`

     - returns: the same WebAuth instance to allow method chaining
     */
    func connectionScope(_ connectionScope: String) -> Self

    /**
     State value that will be echoed after authentication
     in order to check that the response is from your request and not other.

     By default a random value is used.

     - parameter state: a state value to send with the auth request

     - returns: the same WebAuth instance to allow method chaining
     */
    func state(_ state: String) -> Self

    /**
     Send additional parameters for authentication.

     - parameter parameters: additional auth parameters

     - returns: the same WebAuth instance to allow method chaining
     */
    func parameters(_ parameters: [String: String]) -> Self

    /// Setup the response types to be used for authentcation
    ///
    /// - Parameter response: Array of ResponseOptions
    /// - Returns: the same WebAuth instance to allow method chaining
    func responseType(_ response: [ResponseType]) -> Self

    /// Specify a redirect url to be used instead of a custom scheme
    ///
    /// - Parameter redirectURL: custom redirect url
    /// - Returns: the same WebAuth instance to allow method chaining
    func redirectURL(_ redirectURL: URL) -> Self

    /// Add `nonce` parameter for authentication, this is a requirement
    /// when response type `.idToken` is specified.
    ///
    /// - Parameter nonce: nonce string
    /// - Returns: the same WebAuth instance to allow method chaining
    func nonce(_ nonce: String) -> Self

    ///  Audience name of the API that your application will call using the `access_token` returned after Auth.
    ///  This value must match the one defined in Auth0 Dashboard [APIs Section](https://manage.auth0.com/#/apis)
    ///
    /// - Parameter audience: an audience value like: `https://someapi.com/api`
    /// - Returns: the same WebAuth instance to allow method chaining
    func audience(_ audience: String) -> Self

    /// Add a leeway amount for ID Token validation.
    /// This value represents the clock skew for the validation of date claims e.g. `exp`.
    ///
    /// - Parameter leeway: number of milliseconds. Defaults to `60000` (1 minute).
    /// - Returns: the same WebAuth instance to allow method chaining
    func leeway(_ leeway: Int) -> Self

    /// Add `max_age` parameter for authentication, only when response type `.idToken` is specified.
    /// Sending this parameter will require the presence of the `auth_time` claim in the ID Token.
    ///
    /// - Parameter maxAge: number of milliseconds
    /// - Returns: the same WebAuth instance to allow method chaining
    func maxAge(_ maxAge: Int) -> Self

    /**
     Change the default grant used for auth from `code` (w/PKCE) to `token` (implicit grant)

     - returns: the same WebAuth instance to allow method chaining
     */
    @available(*, deprecated, message: "use response([.token])")
    func usingImplicitGrant() -> Self

    /**
     Starts the WebAuth flow by modally presenting a ViewController in the top-most controller.

     ```
     Auth0
         .webAuth(clientId: clientId, domain: "samples.auth0.com")
         .start { result in
             print(result)
         }
     ```

     Then from `AppDelegate` we just need to resume the WebAuth Auth like this

     ```
     func application(app: UIApplication, openURL url: NSURL, options: [String : Any]) -> Bool {
         return Auth0.resumeAuth(url, options: options)
     }
     ```

     Any on going WebAuth Auth session will be automatically cancelled when starting a new one,
     and it's corresponding callback with be called with a failure result of `Authentication.Error.Cancelled`

     - parameter callback: callback called with the result of the WebAuth flow
     */
    func start(_ callback: @escaping (Result<Credentials>) -> Void)

    /**
     Removes Auth0 session and optionally remove the Identity Provider session.
     - seeAlso: [Auth0 Logout docs](https://auth0.com/docs/logout)

     For iOS 11+ you will need to ensure that the **Callback URL** has been added
     to the **Allowed Logout URLs** section of your application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

     ```
     Auth0
         .webAuth()
         .clearSession { print($0) }
     ```

     Remove Auth0 session and remove the IdP session.

     ```
     Auth0
         .webAuth()
         .clearSession(federated: true) { print($0) }
     ```

     - parameter federated: Bool to remove the IdP session
     - parameter callback: callback called with bool outcome of the call
     */
    func clearSession(federated: Bool, callback: @escaping (Bool) -> Void)
}

// TODO: MOVE to a platform-only file
#if os(iOS)
typealias Auth0WebAuth = MobileWebAuth
#if swift(>=4.2)
public typealias A0URLOptionsKey = UIApplication.OpenURLOptionsKey
#else
public typealias A0URLOptionsKey = UIApplicationOpenURLOptionsKey
#endif

/**
 Resumes the current Auth session (if any).

 - parameter url:     url received by the iOS application in AppDelegate
 - parameter options: dictionary with launch options received by the iOS application in AppDelegate

 - returns: if the url was handled by an on going session or not.
 */
public func resumeAuth(_ url: URL, options: [A0URLOptionsKey: Any] = [:]) -> Bool {
    return TransactionStore.shared.resume(url)
}

public protocol WebAuth: WebAuthenticatable {

    /**
     Use `SFSafariViewController` instead of `SFAuthenticationSession` for WebAuth
     in iOS 11.0+.

     - Parameter style: modal presentation style
     - returns: the same WebAuth instance to allow method chaining
     */
    @available(iOS 11, *)
    func useLegacyAuthentication(withStyle style: UIModalPresentationStyle) -> Self

}

public extension WebAuth {

    /**
     Use `SFSafariViewController` instead of `SFAuthenticationSession` for WebAuth
     in iOS 11.0+.
     Defaults to .fullScreen modal presentation style.
     
     - returns: the same WebAuth instance to allow method chaining
     */
    @available(iOS 11, *)
    func useLegacyAuthentication() -> Self {
        return useLegacyAuthentication(withStyle: .fullScreen)
    }

}

final class MobileWebAuth: BaseWebAuth, WebAuth {

    let presenter: ControllerModalPresenter

    private var safariPresentationStyle = UIModalPresentationStyle.fullScreen
    private var authenticationSession = true

    init(clientId: String,
         url: URL,
         presenter: ControllerModalPresenter = ControllerModalPresenter(),
         storage: TransactionStore = TransactionStore.shared,
         telemetry: Telemetry = Telemetry()) {
        self.presenter = presenter
        super.init(clientId: clientId, url: url, storage: storage, telemetry: telemetry)
    }

    func useLegacyAuthentication(withStyle style: UIModalPresentationStyle = .fullScreen) -> Self {
        self.authenticationSession = false
        self.safariPresentationStyle = style
        return self
    }

    override func performLogin(authorizeURL: URL,
                               redirectURL: URL,
                               state: String?,
                               handler: OAuth2Grant,
                               callback: @escaping (Result<Credentials>) -> Void) -> AuthTransaction? {
        if #available(iOS 11.0, *), self.authenticationSession {
            if #available(iOS 12.0, *) {
                return super.performLogin(authorizeURL: authorizeURL,
                                          redirectURL: redirectURL,
                                          state: state,
                                          handler: handler,
                                          callback: callback)
            }
            return SafariServicesSession(authorizeURL: authorizeURL,
                                         redirectURL: redirectURL,
                                         state: state,
                                         handler: handler,
                                         logger: self.logger,
                                         finish: callback)
        }
        let (controller, finish) = newSafari(authorizeURL, callback: callback)
        let session = SafariSession(controller: controller,
                                    redirectURL: redirectURL,
                                    state: state,
                                    handler: handler,
                                    logger: self.logger,
                                    finish: finish)
        controller.delegate = session
        self.presenter.present(controller: controller)
        return session
    }

    override func performLogout(logoutURL: URL,
                                redirectURL: String,
                                federated: Bool,
                                callback: @escaping (Bool) -> Void) -> AuthTransaction? {
        if #available(iOS 11.0, *), self.authenticationSession {
            if #available(iOS 12.0, *) {
                return super.performLogout(logoutURL: logoutURL,
                                           redirectURL: redirectURL,
                                           federated: federated,
                                           callback: callback)
            }
            return SafariServicesSessionCallback(url: logoutURL,
                                                 schemeURL: redirectURL,
                                                 callback: callback)
        }
        var urlComponents = URLComponents(url: logoutURL, resolvingAgainstBaseURL: true)!
        if federated, let firstQueryItem = urlComponents.queryItems?.first {
            urlComponents.queryItems = [firstQueryItem]
        } else {
            urlComponents.query = nil
        }
        let url = urlComponents.url!
        let controller = SilentSafariViewController(url: url) { callback($0) }
        self.presenter.present(controller: controller)
        self.logger?.trace(url: url, source: String(describing: "Safari"))
        return nil
    }

    func newSafari(_ authorizeURL: URL,
                   callback: @escaping (Result<Credentials>) -> Void) -> (SFSafariViewController, (Result<Credentials>) -> Void) {
        let controller = SFSafariViewController(url: authorizeURL)
        controller.modalPresentationStyle = safariPresentationStyle

        if #available(iOS 11.0, *) {
            controller.dismissButtonStyle = .cancel
        }

        let finish: (Result<Credentials>) -> Void = { [weak controller] (result: Result<Credentials>) -> Void in
            if case .failure(let cause as WebAuthError) = result, case .userCancelled = cause {
                DispatchQueue.main.async {
                    callback(result)
                }
            } else {
                DispatchQueue.main.async {
                    guard let presenting = controller?.presentingViewController else {
                        return callback(Result.failure(error: WebAuthError.cannotDismissWebAuthController))
                    }
                    presenting.dismiss(animated: true) {
                        callback(result)
                    }
                }
            }
        }
        return (controller, finish)
    }

}

extension Auth0Authentication {

    func webAuth(withConnection connection: String) -> WebAuth {
        let safari = Auth0WebAuth(clientId: self.clientId, url: self.url, telemetry: self.telemetry)
        return safari
            .logging(enabled: self.logger != nil)
            .connection(connection)
    }

}

public extension _ObjectiveOAuth2 {

    /**
     Resumes the current Auth session (if any).

     - parameter url:     url received by iOS application in AppDelegate
     - parameter options: dictionary with launch options received by iOS application in AppDelegate

     - returns: if the url was handled by an on going session or not.
     */
    @objc(resumeAuthWithURL:options:)
    static func resume(_ url: URL, options: [A0URLOptionsKey: Any]) -> Bool {
        return TransactionStore.shared.resume(url)
    }

}

public protocol AuthResumable {

    /**
     Resumes the transaction when the third party application notifies the application using an url with a custom scheme.
     This method should be called from the Application's `AppDelegate` or using `public func resumeAuth(_ url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool` method.
     
     - parameter url: the url send by the third party application that contains the result of the Auth
     - parameter options: options recieved in the openUrl method of the `AppDelegate`
     - returns: if the url was expected and properly formatted otherwise it will return false.
    */
    func resume(_ url: URL, options: [A0URLOptionsKey: Any]) -> Bool

}

public extension AuthTransaction {

    /**
    Tries to resume (and complete) the OAuth2 session from the received URL

    - parameter url:     url received in application's AppDelegate
    - parameter options: a dictionary of launch options received from application's AppDelegate

    - returns: `true` if the url completed (successfuly or not) this session, `false` otherwise
    */
    func resume(_ url: URL, options: [A0URLOptionsKey: Any] = [:]) -> Bool {
        return self.resume(url, options: options)
    }

}

extension AuthTransaction where Self: BaseAuthTransaction {

    func resume(_ url: URL, options: [A0URLOptionsKey: Any]) -> Bool {
        return self.handleUrl(url)
    }

}

extension AuthTransaction where Self: SessionCallbackTransaction {

    func resume(_ url: URL, options: [A0URLOptionsKey: Any]) -> Bool {
        return self.handleUrl(url)
    }

}

@available(iOS 11.0, *)
final class SafariServicesSession: SessionTransaction {

    init(authorizeURL: URL,
         redirectURL: URL,
         state: String? = nil,
         handler: OAuth2Grant,
         logger: Logger?,
         finish: @escaping FinishTransaction) {
        super.init(redirectURL: redirectURL,
                   state: state,
                   handler: handler,
                   logger: logger,
                   finish: finish)

        authSession = SFAuthenticationSession(url: authorizeURL,
                                              callbackURLScheme: self.redirectURL.absoluteString) { [unowned self] in
            guard $1 == nil, let callbackURL = $0 else {
                let authError = $1 ?? WebAuthError.unknownError
                if case SFAuthenticationError.canceledLogin = authError {
                    self.finish(.failure(error: WebAuthError.userCancelled))
                } else {
                    self.finish(.failure(error: authError))
                }
                return TransactionStore.shared.clear()
            }
            _ = TransactionStore.shared.resume(callbackURL)
        }

         _ = authSession?.start()
    }

}

@available(iOS 11.0, *)
final class SafariServicesSessionCallback: SessionCallbackTransaction {

    init(url: URL, schemeURL: String, callback: @escaping (Bool) -> Void) {
        super.init(callback: callback)

        let authSession = SFAuthenticationSession(url: url, callbackURLScheme: schemeURL) { [unowned self] url, _ in
            self.callback(url != nil)
            TransactionStore.shared.clear()
        }

        self.authSession = authSession
        authSession.start()
    }

}

#if swift(>=5.1)
@available(iOS 13.0, *)
extension AuthenticationServicesSession: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared()?.keyWindow ?? ASPresentationAnchor()
    }

}

@available(iOS 13.0, *)
extension AuthenticationServicesSessionCallback: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared()?.keyWindow ?? ASPresentationAnchor()
    }

}
#endif

@available(iOS 11.0, *)
extension SFAuthenticationSession: AuthenticationSession {}
#endif
