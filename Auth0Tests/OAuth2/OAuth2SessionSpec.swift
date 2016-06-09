// OAuth2SessionSpec.swift
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
import SafariServices

@testable import Auth0

class MockSafariViewController: SFSafariViewController {
    var presenting: UIViewController? = nil

    override var presentingViewController: UIViewController? {
        return presenting ?? super.presentingViewController
    }
}

private let RedirectURL = NSURL(string: "https://samples.auth0.com/callback")!

class OAuth2SessionSpec: QuickSpec {

    override func spec() {

        var result: Result<Credentials, Authentication.Error>? = nil
        let callback: Result<Credentials, Authentication.Error> -> () = { result = $0 }
        let controller = MockSafariViewController(URL: NSURL(string: "https://auth0.com")!)
        let handler = ImplicitGrant()
        let session = OAuth2Session(controller: controller, redirectURL: RedirectURL, handler: handler, finish: callback)

        beforeEach {
            result = nil
        }

        context("SFSafariViewControllerDelegate") {
            var session: OAuth2Session!

            beforeEach {
                controller.delegate = nil
                session = OAuth2Session(controller: controller, redirectURL: RedirectURL, handler: handler, finish: callback)
                SessionStorage.sharedInstance.store(session)
            }

            it("should set itself as delegate") {
                expect(controller.delegate).toNot(beNil())
            }

            it("should send cancelled event") {
                session.safariViewControllerDidFinish(controller)
                expect(result).toEventually(beFailure())
            }
        }

        describe("resume:options") {

            beforeEach {
                controller.presenting = MockViewController()
            }

            it("should return true if URL matches redirect URL") {
                expect(session.resume(NSURL(string: "https://samples.auth0.com/callback?access_token=ATOKEN&token_type=bearer")!)).to(beTrue())
            }

            it("should return false when URL does not match redirect URL") {
                expect(session.resume(NSURL(string: "https://auth0.com/mobile?access_token=ATOKEN&token_type=bearer")!)).to(beFalse())
            }

            it("should return credentials from query string") {
                session.resume(NSURL(string: "https://samples.auth0.com/callback?access_token=ATOKEN&token_type=bearer")!)
                expect(result).toEventually(haveCredentials())
            }

            it("should return credentials from fragment") {
                session.resume(NSURL(string: "https://samples.auth0.com/callback#access_token=ATOKEN&token_type=bearer")!)
                expect(result).toEventually(haveCredentials())
            }
            it("should return error from query string") {
                session.resume(NSURL(string: "https://samples.auth0.com/callback?error=error&error_description=description")!)
                expect(result).toEventually(haveError(code: "error", description: "description"))
            }

            it("should return error from fragment") {
                session.resume(NSURL(string: "https://samples.auth0.com/callback#error=error&error_description=description")!)
                expect(result).toEventually(haveError(code: "error", description: "description"))
            }

            it("should fail if values from fragment are invalid") {
                session.resume(NSURL(string: "https://samples.auth0.com/callback#access_token=")!)
                expect(result).toEventually(beFailure())
            }

            context("with state") {
                let session = OAuth2Session(controller: controller, redirectURL: RedirectURL, state: "state", handler: handler, finish: {
                    result = $0
                })

                it("should not handle url when state in url is missing") {
                    let handled = session.resume(NSURL(string: "https://samples.auth0.com/callback?access_token=ATOKEN&token_type=bearer")!)
                    expect(handled).to(beFalse())
                    expect(result).toEventually(beNil())
                }

                it("should not handle url when state in url does not match one in session") {
                    let handled = session.resume(NSURL(string: "https://samples.auth0.com/callback?access_token=ATOKEN&token_type=bearer&state=another")!)
                    expect(handled).to(beFalse())
                    expect(result).toEventually(beNil())
                }

            }
        }

    }

}