// WebAuthErrorSpec.swift
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

import Foundation
import Quick
import Nimble

@testable import Auth0

class WebAuthErrorSpec: QuickSpec {

    override func spec() {

        describe("foundation error") {

            it("should build generic NSError") {
                let error = WebAuthError.noBundleIdentifierFound as NSError
                expect(error.domain) == "com.auth0.webauth"
                expect(error.code) == 1
            }

            it("should build error for PKCE not allowed") {
                let message = "Not Allowed"
                let error = WebAuthError.pkceNotAllowed(message) as NSError
                expect(error.domain) == "com.auth0.webauth"
                expect(error.code) == 1
                expect(error.localizedDescription) == message
            }

            it("should build error for user cancelled") {
                let error = WebAuthError.userCancelled as NSError
                expect(error.domain) == "com.auth0.webauth"
                expect(error.code) == 0
            }

            it("should build error for no nonce supplied") {
                let error = WebAuthError.noNonceProvided as NSError
                expect(error.domain) == "com.auth0.webauth"
                expect(error.code) == 1
            }

            it("should build error for no idToken nonce match") {
                let error = WebAuthError.invalidIdTokenNonce as NSError
                expect(error.domain) == "com.auth0.webauth"
                expect(error.code) == 1
            }

            it("should build error for missing access_token") {
                let error = WebAuthError.missingAccessToken as NSError
                expect(error.domain) == "com.auth0.webauth"
                expect(error.code) == 1
            }
        }
    }
}
