// MobileWebAuth.swift
//
// Copyright (c) 2020 Auth0 (http://auth0.com)
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

#if os(iOS)
import UIKit
import SafariServices
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

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
        super.init(platform: "ios",
                   clientId: clientId,
                   url: url,
                   storage: storage,
                   telemetry: telemetry)
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
            #if !targetEnvironment(macCatalyst)
            return SafariServicesSession(authorizeURL: authorizeURL,
                                         redirectURL: redirectURL,
                                         state: state,
                                         handler: handler,
                                         logger: self.logger,
                                         callback: callback)
            #else
            return nil // Will never get executed because Catalyst will use AuthenticationServices
            #endif
        }
        let (controller, finish) = newSafari(authorizeURL, callback: callback)
        let session = SafariSession(controller: controller,
                                    redirectURL: redirectURL,
                                    state: state,
                                    handler: handler,
                                    logger: self.logger,
                                    callback: finish)
        controller.delegate = session
        self.presenter.present(controller: controller)
        return session
    }

    override func performLogout(logoutURL: URL,
                                redirectURL: URL,
                                federated: Bool,
                                callback: @escaping (Bool) -> Void) -> AuthTransaction? {
        if #available(iOS 11.0, *), self.authenticationSession {
            if #available(iOS 12.0, *) {
                return super.performLogout(logoutURL: logoutURL,
                                           redirectURL: redirectURL,
                                           federated: federated,
                                           callback: callback)
            }
            #if !targetEnvironment(macCatalyst)
            return SafariServicesSessionCallback(url: logoutURL,
                                                 schemeURL: redirectURL,
                                                 callback: callback)
            #else
            return nil // Will never get executed because Catalyst will use AuthenticationServices
            #endif
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

public extension _ObjectiveOAuth2 {

    /**
     Resumes the current Auth session (if any).

     - parameter url:     url received by iOS application in AppDelegate
     - parameter options: dictionary with launch options received by iOS application in AppDelegate

     - returns: if the url was handled by an on going session or not.
     */
    @objc(resumeAuthWithURL:options:)
    static func resume(_ url: URL, options: [A0URLOptionsKey: Any]) -> Bool {
        return resumeAuth(url, options: options)
    }

}

public protocol AuthResumable {

    /**
     Resumes the transaction when the third party application notifies the application using an url with a custom scheme.
     This method should be called from the Application's `AppDelegate` or using `public func resumeAuth(_ url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool` method.
     
     - parameter url: the url send by the third party application that contains the result of the Auth
     - parameter options: options recieved in the openUrl method of the `AppDelegate`

     - returns: if the url was expected and properly formatted otherwise it will return `false`.
    */
    func resume(_ url: URL, options: [A0URLOptionsKey: Any]) -> Bool

}

public extension AuthResumable {

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

#if !targetEnvironment(macCatalyst)
@available(iOS 11.0, *)
final class SafariServicesSession: SessionTransaction {

    init(authorizeURL: URL,
         redirectURL: URL,
         state: String? = nil,
         handler: OAuth2Grant,
         logger: Logger?,
         callback: @escaping FinishTransaction) {
        super.init(redirectURL: redirectURL,
                   state: state,
                   handler: handler,
                   logger: logger,
                   callback: callback)

        authSession = SFAuthenticationSession(url: authorizeURL,
                                              callbackURLScheme: self.redirectURL.absoluteString) { [unowned self] in
            guard $1 == nil, let callbackURL = $0 else {
                let authError = $1 ?? WebAuthError.unknownError
                if case SFAuthenticationError.canceledLogin = authError {
                    self.callback(.failure(error: WebAuthError.userCancelled))
                } else {
                    self.callback(.failure(error: authError))
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

    init(url: URL, schemeURL: URL, callback: @escaping (Bool) -> Void) {
        super.init(callback: callback)

        let authSession = SFAuthenticationSession(url: url,
                                                  callbackURLScheme: schemeURL.absoluteString) { [unowned self] url, _ in
            self.callback(url != nil)
            TransactionStore.shared.clear()
        }

        self.authSession = authSession
        authSession.start()
    }

}

@available(iOS 11.0, *)
extension SFAuthenticationSession: AuthSession {}
#endif

#if canImport(AuthenticationServices) && swift(>=5.1)
@available(iOS 13.0, *)
extension AuthenticationServicesSession: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}

@available(iOS 13.0, *)
extension AuthenticationServicesSessionCallback: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}
#endif
#endif
