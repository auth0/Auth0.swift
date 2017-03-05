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

    override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        completion?()
    }
}

class ControllerModalPresenterSpec: QuickSpec {

    override func spec() {

        describe("topViewController") {

            var root: MockViewController!

            beforeEach {
                root = MockViewController()
                UIApplication.shared.keyWindow?.rootViewController = root
            }

            it("should return nil when root is nil") {
                UIApplication.shared.keyWindow?.rootViewController = nil
                expect(ControllerModalPresenter().topViewController).to(beNil())
            }

            it("should return root when is top controller") {
                expect(ControllerModalPresenter().topViewController) == root
            }

            it("should return presented controller") {
                let presented = UIViewController()
                root.presented = presented
                expect(ControllerModalPresenter().topViewController) == presented
            }

            it("should return split view controller if contains nothing") {
                let split = UISplitViewController()
                root.presented = split
                expect(ControllerModalPresenter().topViewController) == split
            }

            it("should return last controller from split view controller") {
                let split = UISplitViewController()
                let last = UIViewController()
                split.viewControllers = [UIViewController(), last]
                root.presented = split
                expect(ControllerModalPresenter().topViewController) == last
            }

            it("should return navigation controller if contains nothing") {
                let navigation = UINavigationController()
                root.presented = navigation
                expect(ControllerModalPresenter().topViewController) == navigation
            }

            it("should return top from navigation controller") {
                let top = UIViewController()
                let navigation = UINavigationController(rootViewController: top)
                root.presented = navigation
                expect(ControllerModalPresenter().topViewController) == top
            }

        }

    }
}
