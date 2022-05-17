#if os(iOS)
import UIKit
import SafariServices

public extension WebAuthentication {

    static func safariProvider(style: UIModalPresentationStyle = .fullScreen) -> WebAuthProvider {
        return { url, _ in
            let safari = SFSafariViewController(url: url)
            safari.dismissButtonStyle = .cancel
            safari.modalPresentationStyle = style

            return SafariUserAgent(controller: safari)
        }
    }

}

extension SFSafariViewController {

    func present() {
        topViewController?.present(self, animated: true, completion: nil)
    }

    private var rootViewController: UIViewController? {
        return UIApplication.shared()?.keyWindow?.rootViewController
    }

    private var topViewController: UIViewController? {
        guard let root = self.rootViewController else { return nil }
        return findTopViewController(from: root)
    }

    private func findTopViewController(from root: UIViewController) -> UIViewController? {
        if let presented = root.presentedViewController { return findTopViewController(from: presented) }
        switch root {
        case let split as UISplitViewController:
            guard let last = split.viewControllers.last else { return split }
            return findTopViewController(from: last)
        case let navigation as UINavigationController:
            guard let top = navigation.topViewController else { return navigation }
            return findTopViewController(from: top)
        case let tab as UITabBarController:
            guard let selected = tab.selectedViewController else { return tab }
            return findTopViewController(from: selected)
        default:
            return root
        }
    }

}

class SafariUserAgent: NSObject, WebAuthUserAgent {

    var controller: SFSafariViewController

    init(controller: SFSafariViewController) {
        self.controller = controller
        super.init()
        self.controller.delegate = self
    }

    func start() {
        self.controller.present()
    }

    func finish(_ callback: @escaping (WebAuthResult<Void>) -> Void) -> (WebAuthResult<Void>) -> Void {
        return { [weak controller] result -> Void in
            if case .failure(let cause) = result, case .userCancelled = cause {
                DispatchQueue.main.async {
                    callback(result)
                }
            } else {
                DispatchQueue.main.async {
                    guard let presenting = controller?.presentingViewController else {
                        return callback(Result.failure(WebAuthError.unknown))
                    }
                    presenting.dismiss(animated: true) {
                        callback(result)
                    }
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
        WebAuthentication.cancel()
    }

}
#endif
