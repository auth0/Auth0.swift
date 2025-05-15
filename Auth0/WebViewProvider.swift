//
//  WebViewProvider.swift
//  Auth0
//
//  Created by Desu Sai Venkat on 18/09/24.
//  Copyright © 2024 Auth0. All rights reserved.
//

#if os(iOS)

@preconcurrency import WebKit

/// Creates a Web Auth provider that uses `WKWebView` as the embedded user agent.
/// Unlike `SFSafariViewController`, `WKWebView` supports using Universal Links as callback URLs.
///
/// ## Usage
///
/// ```swift
/// Auth0
///     .webAuth()
///     .provider(WebAuthentication.webViewProvider())
///     .start { result in
///         // ...
/// }
/// ```
///
/// If you need to specify a custom `UIModalPresentationStyle`:
///
/// ```swift
/// Auth0
///     .webAuth()
///     .provider(WebAuthentication.webViewProvider(style: .formSheet))
///     .start { result in
///         // ...
/// }
/// ```
///
/// - Parameter style: `UIModalPresentationStyle` to be used. Defaults to `.fullScreen`.
/// - Returns: A ``WebAuthProvider`` instance.
///
/// > Note: To use Universal Login's biometrics and passkeys with `WKWebView`, you must
/// [set up an associated domain](https://github.com/auth0/Auth0.swift#configure-an-associated-domain).
///
/// > Warning: The use of `WKWebView` for performing web-based authentication [is not recommended](https://auth0.com/blog/oauth-2-best-practices-for-native-apps),
/// and some social identity providers –such as Google– do not support it.
///
/// ## See Also
///
/// - [OAuth 2.0 Best Practices for Native Apps](https://auth0.com/blog/oauth-2-best-practices-for-native-apps)
public extension WebAuthentication {

    static func webViewProvider(style: UIModalPresentationStyle = .fullScreen) -> WebAuthProvider {
        return { url, callback  in
            let redirectURL = extractRedirectURL(from: url)!

            return WebViewUserAgent(authorizeURL: url,
                                    redirectURL: redirectURL,
                                    modalPresentationStyle: style,
                                    callback: callback)
        }
    }

}

class WebViewUserAgent: NSObject, WebAuthUserAgent {

    static let customSchemeRedirectionSuccessMessage = "com.auth0.webview.redirection_success"
    static let customSchemeRedirectionFailureMessage = "com.auth0.webview.redirection_failure"
    let defaultSchemesSupportedByWKWebview = ["https"]

    let request: URLRequest
    var webview: WKWebView!
    let viewController: UIViewController
    let redirectURL: URL
    let callback: WebAuthProviderCallback

    init(authorizeURL: URL, redirectURL: URL, viewController: UIViewController = UIViewController(), modalPresentationStyle: UIModalPresentationStyle = .fullScreen, callback: @escaping WebAuthProviderCallback) {
        self.request = URLRequest(url: authorizeURL)
        self.redirectURL = redirectURL
        self.callback = callback
        self.viewController = viewController
        self.viewController.modalPresentationStyle = modalPresentationStyle

        super.init()
        if !defaultSchemesSupportedByWKWebview.contains(redirectURL.scheme!) {
            self.setupWebViewWithCustomScheme()
        } else {
            self.setupWebViewWithHTTPS()
        }
    }

    private func setupWebViewWithCustomScheme() {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(self, forURLScheme: redirectURL.scheme!)
        self.webview = WKWebView(frame: .zero, configuration: configuration)
        self.viewController.view = webview
        self.configurationSubviews()
        webview.navigationDelegate = self
    }
    
    private func setupWebViewWithHTTPS() {
        self.webview = WKWebView(frame: .zero)
        self.viewController.view = webview
        self.configurationSubviews()
        webview.navigationDelegate = self
    }
    
    private func configurationSubviews()
    {
        let closeButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .regular)
        let closeImage = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        closeButton.setImage(closeImage, for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.viewController.view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: self.viewController.view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: self.viewController.view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        self.viewController.isModalInPresentation = true
    }
    
    @objc private func closeTapped() {
        self.finish(with: .failure(WebAuthError(code: .userCancelled)))
    }

    func start() {
        self.webview.load(self.request)
        UIWindow.topViewController?.present(self.viewController, animated: true)
    }

    func finish(with result: WebAuthResult<Void>) {
        DispatchQueue.main.async { [weak webview, weak viewController, callback] in
            guard let presenting = viewController?.presentingViewController else {
                let error = WebAuthError(code: .unknown("Cannot dismiss WKWebView"))
                return callback(.failure(error))
            }
            presenting.dismiss(animated: true) {
                webview?.removeFromSuperview()
                callback(result)
            }
        }
    }

    public override var description: String {
        return String(describing: WKWebView.self)
    }

}

/// Handling of Custom Scheme callbacks.
extension WebViewUserAgent: WKURLSchemeHandler {

    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        _ = TransactionStore.shared.resume(urlSchemeTask.request.url!)
        let error = NSError(domain: WebViewUserAgent.customSchemeRedirectionSuccessMessage, code: 200, userInfo: [
            NSLocalizedDescriptionKey: "WebViewProvider: WKURLSchemeHandler: Succesfully redirected back to the app"
        ])
        urlSchemeTask.didFailWithError(error)
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {
        let error = NSError(domain: WebViewUserAgent.customSchemeRedirectionFailureMessage, code: 400, userInfo: [
            NSLocalizedDescriptionKey: "WebViewProvider: WKURLSchemeHandler: Webview Resource Loading has been stopped"
        ])
        urlSchemeTask.didFailWithError(error)
        self.finish(with: .failure(WebAuthError(code: .webViewFailure("The WebView's resource loading was stopped."))))
    }

}

/// Handling of HTTPS callbacks.
extension WebViewUserAgent: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let callbackUrl = navigationAction.request.url, callbackUrl.absoluteString.starts(with: redirectURL.absoluteString), let scheme = callbackUrl.scheme, scheme == "https" {
            _ = TransactionStore.shared.resume(callbackUrl)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        if (error as NSError).domain == WebViewUserAgent.customSchemeRedirectionSuccessMessage {
            return
        }
        self.finish(with: .failure(WebAuthError(code: .webViewFailure("An error occurred during a committed main frame navigation of the WebView."), cause: error)))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        if (error as NSError).domain == WebViewUserAgent.customSchemeRedirectionSuccessMessage {
            return
        }
        self.finish(with: .failure(WebAuthError(code: .webViewFailure("An error occurred while starting to load data for the main frame of the WebView."), cause: error)))
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        self.finish(with: .failure(WebAuthError(code: .webViewFailure("The WebView's content process was terminated."))))
    }

}

#endif
