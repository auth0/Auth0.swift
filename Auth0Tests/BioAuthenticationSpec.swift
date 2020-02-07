// BioAuthenticationSpec.swift
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
import OHHTTPStubs
import LocalAuthentication

@testable import Auth0

class BioAuthenticationSpec: QuickSpec {

    override func spec() {

        var mockContext: MockLAContext!
        var bioAuthentication: BioAuthentication!

        beforeEach {
            mockContext = MockLAContext()
            bioAuthentication = BioAuthentication(authContext: mockContext, title: "Touch Auth")
        }

        describe("touch availablility") {

            it("touch should be enabled") {
                expect(bioAuthentication.available).to(beTrue())
            }

            it("touch should be disabled") {
                mockContext.enabled = false
                expect(bioAuthentication.available).to(beFalse())
            }
        }

        describe("setters") {

            it("should set cancel title") {
                bioAuthentication.cancelTitle = "cancel title"
                expect(mockContext.localizedCancelTitle) == "cancel title"
            }

            it("should set fallback title") {
                bioAuthentication.fallbackTitle = "fallback title"
                expect(mockContext.localizedFallbackTitle) == "fallback title"
            }
        }
        describe("touch authentication") {

            var error: Error?

            beforeEach {
                error = nil
            }

            it("should authenticate") {
                bioAuthentication.validateBiometric { error = $0 }
                expect(error).toEventually(beNil())
            }

            it("should return error on touch authentication") {
                let touchError = LAError(.appCancel)
                mockContext.replyError = touchError
                bioAuthentication.validateBiometric { error = $0 }
                expect(error).toEventually(matchError(touchError))
            }

            it("should return authenticationFailed error if no policy success") {
                let touchError = LAError(.authenticationFailed)
                mockContext.replySuccess = false
                bioAuthentication.validateBiometric { error = $0 }
                expect(error).toEventually(matchError(touchError))
            }

        }
    }
}

class MockLAContext: LAContext {

    var enabled = true
    var replySuccess = true
    var replyError: Error? = nil

    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        return self.enabled
    }

    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
        reply(replySuccess, replyError)
    }
}

