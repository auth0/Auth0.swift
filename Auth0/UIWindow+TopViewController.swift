//
//  UIWindow+TopViewController.swift
//  Auth0
//
//  Created by Desu Sai Venkat on 01/10/24.
//  Copyright © 2024 Auth0. All rights reserved.
//

#if os(iOS)
import UIKit

extension UIWindow {
    static var topViewController: UIViewController? {
        guard let root = UIApplication.shared()?.windows.last(where: \.isKeyWindow)?.rootViewController else {
            return nil
        }
        return findTopViewController(from: root)
    }

    private static func findTopViewController(from root: UIViewController) -> UIViewController? {
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
