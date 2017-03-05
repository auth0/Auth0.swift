// ControllerModalPresenter.swift
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

struct ControllerModalPresenter {

    var rootViewController: UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController
    }

    func present(controller: UIViewController) {
        topViewController?.present(controller, animated: true, completion: nil)
    }

    var topViewController: UIViewController? {
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
