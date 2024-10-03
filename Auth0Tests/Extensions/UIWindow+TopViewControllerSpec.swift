//
//  Untitled.swift
//  Auth0
//
//  Created by Desu Sai Venkat on 01/10/24.
//  Copyright © 2024 Auth0. All rights reserved.
//


#if os(iOS)
import Quick
import Nimble
@testable import Auth0

class UIWindow_TopViewControllerSpec: QuickSpec {
    
    override class func spec() {
        
        describe("UIWindow extension") {
            
            var root: SpyViewController!
            
            beforeEach {
                root = SpyViewController()
                UIApplication.shared.windows.last(where: \.isKeyWindow)?.rootViewController = root
            }
            
            it("should return nil when root is nil") {
                UIApplication.shared.windows.last(where: \.isKeyWindow)?.rootViewController = nil
                expect(UIWindow.topViewController).to(beNil())
            }
            
            it("should return root when is top controller") {
                expect(UIWindow.topViewController) == root
            }
            
            it("should return presented controller") {
                let presented = UIViewController()
                root.presented = presented
                expect(UIWindow.topViewController) == presented
            }
            
            it("should return split view controller if contains nothing") {
                let split = UISplitViewController()
                root.presented = split
                expect(UIWindow.topViewController) == split
            }
            
            it("should return last controller from split view controller") {
                let split = UISplitViewController()
                let last = UIViewController()
                split.viewControllers = [UIViewController(), last]
                root.presented = split
                expect(UIWindow.topViewController) == last
            }
            
            it("should return navigation controller if contains nothing") {
                let navigation = UINavigationController()
                root.presented = navigation
                expect(UIWindow.topViewController) == navigation
            }
            
            it("should return top from navigation controller") {
                let top = UIViewController()
                let navigation = UINavigationController(rootViewController: top)
                root.presented = navigation
                expect(UIWindow.topViewController) == top
            }
            
            it("should return tab bar controller if contains nothing") {
                let tabs = UITabBarController()
                root.presented = tabs
                expect(UIWindow.topViewController) == tabs
            }
            
            it("should return top from tab bar controller") {
                let top = UIViewController()
                let tabs = UITabBarController()
                tabs.viewControllers = [top]
                root.presented = tabs
                expect(UIWindow.topViewController) == top
            }
        }
        
    }
}
#endif
