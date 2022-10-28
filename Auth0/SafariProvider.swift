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
    /// If you need specify a custom `UIModalPresentationStyle`:
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
    static func safariProvider(style: UIModalPresentationStyle = .fullScreen) -> WebAuthProvider {
        return { url, callback in
            let safari = SFSafariViewController(url: url)
            safari.dismissButtonStyle = .cancel
            safari.modalPresentationStyle = style
            return SafariUserAgent(controller: safari, callback: callback)
        }
    }

}

extension SFSafariViewController {

    var topViewController: UIViewController? {
        guard let root = UIApplication.shared()?.keyWindow?.rootViewController else { return nil }
        return self.findTopViewController(from: root)
    }

    func present() {
        self.topViewController?.present(self, animated: true, completion: nil)
    }

    private func findTopViewController(from root: UIViewController) -> UIViewController? {
        if let presented = root.presentedViewController { return self.findTopViewController(from: presented) }

        switch root {
        case let split as UISplitViewController:
            guard let last = split.viewControllers.last else { return split }
            return self.findTopViewController(from: last)
        case let navigation as UINavigationController:
            guard let top = navigation.topViewController else { return navigation }
            return self.findTopViewController(from: top)
        case let tab as UITabBarController:
            guard let selected = tab.selectedViewController else { return tab }
            return self.findTopViewController(from: selected)
        default:
            return root
        }
    }

}

class SafariUserAgent: NSObject, WebAuthUserAgent {

    let controller: SFSafariViewController
    let callback: ((WebAuthResult<Void>) -> Void)

    init(controller: SFSafariViewController, callback: @escaping (WebAuthResult<Void>) -> Void) {
        self.controller = controller
        self.callback = callback
        super.init()
        self.controller.delegate = self
    }

    func start() {
        self.controller.present()
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
        // If you are developing a custom Web Auth provider, call WebAuthentication.cancel() instead
        // TransactionStore is internal
        TransactionStore.shared.cancel()
    }

}
#endif
