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
    /// - Parameter style: `UIModalPresentationStyle` to be used. Defaults to `.fullScreen`.
    /// - Returns: A ``WebAuthProvider`` instance.
    ///
    /// ## See Also
    ///
    /// - <doc:UserAgents>
    static func safariProvider(style: UIModalPresentationStyle = .fullScreen) -> WebAuthProvider {
        return { url, callback -> WebAuthUserAgent in
            return await Task {
                let safari = await SFSafariViewController(url: url)
                await safari.setDismissButtonStyle()
                await safari.setModelPresentationStyle(style: style)
                return await SafariUserAgent(controller: safari, callback: callback)
            }.value
        }
    }

}

extension SFSafariViewController {
    func setDismissButtonStyle(style: DismissButtonStyle = .cancel) async {
        dismissButtonStyle = style
    }
    
    func setModelPresentationStyle(style: UIModalPresentationStyle = .fullScreen) async {
        modalPresentationStyle = style
    }
}

@MainActor final class SafariUserAgent: NSObject, WebAuthUserAgent {

    let controller: SFSafariViewController
    let callback: WebAuthProviderCallback

    init(controller: SFSafariViewController, callback: @escaping WebAuthProviderCallback) {
        self.controller = controller
        self.callback = callback
        super.init()
        self.controller.delegate = self
        self.controller.presentationController?.delegate = self
    }

    func start() async {
        UIWindow.topViewController?.present(controller, animated: true, completion: nil)
    }

    func finish(with result: WebAuthResult<Void>) async {
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

    nonisolated func safariViewControllerDidFinish(_ controller: SFSafariViewController)  {
        // If you are developing a custom Web Auth provider, call WebAuthentication.cancel() instead
        // TransactionStore is internal
        Task {
            await TransactionStore.shared.cancel()
        }
    }
 
}

extension SafariUserAgent: UIAdaptivePresentationControllerDelegate {

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController)  {
        // If you are developing a custom Web Auth provider, call WebAuthentication.cancel() instead
        Task {
            // TransactionStore is internal
            await TransactionStore.shared.cancel()
        }
    }

}
#endif
