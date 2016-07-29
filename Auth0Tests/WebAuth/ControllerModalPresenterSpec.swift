// ControllerModalPresenterSpec.swift
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

import Quick
import Nimble

@testable import Auth0

class MockViewController: UIViewController {
    var presented: UIViewController? = nil

    override var presentedViewController: UIViewController? {
        return presented ?? super.presentedViewController
    }

    override func dismissViewControllerAnimated(flag: Bool, completion: (() -> Void)?) {
        completion?()
    }
}

class ControllerModalPresenterSpec: QuickSpec {

    override func spec() {

        describe("init") {

            it("should get root controller from UIApplication") {
                let presenter = ControllerModalPresenter()
                expect(presenter.rootViewController) == UIApplication.sharedApplication().keyWindow?.rootViewController
            }

            it("should accept specific controller") {
                let controller = UIViewController()
                let presenter = ControllerModalPresenter(rootViewController: controller)
                expect(presenter.rootViewController) == controller
            }

        }

        describe("topViewController") {

            var root: MockViewController!

            beforeEach {
                root = MockViewController()
            }

            it("should return nil when root is nil") {
                expect(ControllerModalPresenter(rootViewController: nil).topViewController).to(beNil())
            }

            it("should return root when is top controller") {
                expect(ControllerModalPresenter(rootViewController: root).topViewController) == root
            }

            it("should return presented controller") {
                let presented = UIViewController()
                root.presented = presented
                expect(ControllerModalPresenter(rootViewController: root).topViewController) == presented
            }

            it("should return split view controller if contains nothing") {
                let split = UISplitViewController()
                expect(ControllerModalPresenter(rootViewController: split).topViewController) == split
            }

            it("should return last controller from split view controller") {
                let split = UISplitViewController()
                let last = UIViewController()
                split.viewControllers = [UIViewController(), last]
                expect(ControllerModalPresenter(rootViewController: split).topViewController) == last
            }

            it("should return navigation controller if contains nothing") {
                let navigation = UINavigationController()
                expect(ControllerModalPresenter(rootViewController: navigation).topViewController) == navigation
            }

            it("should return top from navigation controller") {
                let top = UIViewController()
                let navigation = UINavigationController(rootViewController: top)
                expect(ControllerModalPresenter(rootViewController: navigation).topViewController) == top
            }

        }

    }
}