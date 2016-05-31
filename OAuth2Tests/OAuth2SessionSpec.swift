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
        let controller = MockSafariViewController(URL: NSURL(string: "https://auth0.com")!)
        let session = OAuth2Session(controller: controller, redirectURL: RedirectURL, callback: {
            result = $0
        })

        beforeEach {
            result = nil
        }

        context("SFSafariViewControllerDelegate") {

            it("should set itself as delegate") {
                expect(controller.delegate as? OAuth2Session).to(equal(session))
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

            it("should call callback with error when controller is not presented") {
                controller.presenting = nil
                session.resume(NSURL(string: "https://auth0.com")!)
                expect(result).toEventually(beFailure())
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

        }

    }

}