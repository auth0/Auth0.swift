#if os(iOS)
import UIKit
import SafariServices

public extension WebAuthentication {

    /// Creates a Web Auth provider that uses `SFSafariViewController` as the external user agent.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .webAuth()
    ///     .provider(WebAuthentication.safariProvider())
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
    ///     .provider(WebAuthentication.safariProvider(style: .formSheet))
    ///     .start { result in
    ///         // ...
    /// }
    /// ```
    ///
    /// > Important: Unlike `ASWebAuthenticationSession`, `SFSafariViewController` will not automatically capture the
    /// callback URL when Auth0 redirects back to your app, so it is necessary to manually resume the Web Auth operation.
    /// See [Use `SFSafariViewController` instead of `ASWebAuthenticationSession`](https://github.com/auth0/Auth0.swift/blob/master/EXAMPLES.md#use-sfsafariviewcontroller-instead-of-aswebauthenticationsession)
    /// for the complete setup instructions.
    ///
    /// > Note: `SFSafariViewController` does not support using Universal Links as callback URLs.
    ///
    /// - Parameter style: `UIModalPresentationStyle` to be used. Defaults to `.fullScreen`.
    /// - Returns: A ``WebAuthProvider`` instance.
    ///
    /// ## See Also
    ///
    /// - <doc:UserAgents>
    static func safariProvider(style: UIModalPresentationStyle = .fullScreen) -> WebAuthProvider {
        return { url, callback in
            let safari = SFSafariViewController(url: url)
            safari.dismissButtonStyle = .cancel
            safari.modalPresentationStyle = style
            return SafariUserAgent(controller: safari, callback: callback)
        }
    }

}

class SafariUserAgent: NSObject, WebAuthUserAgent {

    let controller: SFSafariViewController
    let callback: WebAuthProviderCallback

    init(controller: SFSafariViewController, callback: @escaping WebAuthProviderCallback) {
        self.controller = controller
        self.callback = callback
        super.init()
        self.controller.delegate = self
        self.controller.presentationController?.delegate = self
    }

    func start() {
        UIWindow.topViewController?.present(controller, animated: true, completion: nil)
    }

    func finish(with result: WebAuthResult<Void>) {
        if case .failure(let cause) = result, case .userCancelled = cause {
            DispatchQueue.main.async { [callback] in
                callback(result)
            }
        } else {
            DispatchQueue.main.async { [callback, weak controller] in
                guard let presenting = controller?.presentingViewController else {
                    let error = WebAuthError(code: .unknown("Cannot dismiss SFSafariViewController"))
                    return callback(.failure(error))
                }
                presenting.dismiss(animated: true) {
                    callback(result)
                }
            }
        }
    }

    override var description: String {
        return String(describing: SFSafariViewController.self)
    }

}

extension SafariUserAgent: SFSafariViewControllerDelegate {

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        Task { @MainActor in
            TransactionStore.shared.cancel()
        }
    }

}

extension SafariUserAgent: UIAdaptivePresentationControllerDelegate {

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        Task { @MainActor in
            TransactionStore.shared.cancel()
        }
    }

}
#endif
