#if os(iOS)
import UIKit

extension UIWindow {
    static var topViewController: UIViewController? {
        // Find the foreground active scene's key window for multi-window support
        if let windowScene = UIApplication.shared()?.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: \.isKeyWindow),
           let root = keyWindow.rootViewController {
            return findTopViewController(from: root)
        }

        // Fallback to any key window
        guard let root = UIApplication.shared()?.windows.first(where: \.isKeyWindow)?.rootViewController else {
            return nil
        }
        return findTopViewController(from: root)
    }

    static func findTopViewController(from root: UIViewController) -> UIViewController? {
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
#endif
