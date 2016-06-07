// OAuth2GrantSpec.swift
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

@testable import Auth0

class OAuth2GrantSpec: QuickSpec {

    override func spec() {

        describe("ImplicitGrant") {

            var implicit: ImplicitGrant!

            beforeEach {
                implicit = ImplicitGrant()
            }

            it("shoud build credentials") {
                let token = NSUUID().UUIDString
                let values = ["access_token": token, "token_type": "bearer"]
                waitUntil { done in
                    implicit.credentials(values) {
                        expect($0).to(haveCredentials(token))
                        done()
                    }
                }
            }

            it("shoud report error to get credentials") {
                waitUntil { done in
                    implicit.credentials([:]) {
                        expect($0).to(beFailure())
                        done()
                    }
                }
            }

            it("should specify response type") {
                expect(implicit.defaults["response_type"]) == "token"
            }
        }


        describe("Authorization Code w/PKCE") {

            let domain = NSURL.a0_url("samples.auth0.com")
            let method = "S256"
            let redirectURL = NSURL(string: "https://samples.auth0.com/callback")!
            var verifier: String!
            var challenge: String!
            var pkce: PKCE!

            beforeEach {
                verifier = "\(arc4random())"
                challenge = "\(arc4random())"
                pkce = PKCE(clientId: "CLIENTID", url: domain, redirectURL: redirectURL, verifier: verifier, challenge: challenge, method: method)
            }

            afterEach {
                OHHTTPStubs.removeAllStubs()
                stub(isHost(domain.host!)) { _ in
                    return OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
                }.name = "YOU SHALL NOT PASS!"
            }

            it("shoud build credentials") {
                let token = NSUUID().UUIDString
                let code = NSUUID().UUIDString
                let values = ["code": code]
                stub(isToken(domain.host!) && hasAtLeast(["code": code, "code_verifier": pkce.verifier, "grant_type": "authorization_code", "redirect_uri": pkce.redirectURL.absoluteString])) { _ in return authResponse(accessToken: token) }.name = "Code Exchange Auth"
                waitUntil { done in
                    pkce.credentials(values) {
                        expect($0).to(haveCredentials(token))
                        done()
                    }
                }
            }

            it("shoud report error to get credentials") {
                waitUntil { done in
                    pkce.credentials([:]) {
                        expect($0).to(beFailure())
                        done()
                    }
                }
            }

            it("should specify response type") {
                expect(pkce.defaults["response_type"]) == "code"
            }

            it("should specify pkce parameters") {
                expect(pkce.defaults["code_challenge_method"]) == "S256"
                expect(pkce.defaults["code_challenge"]) == challenge
            }

            it("should get values from generator") {
                let generator = A0SHA256ChallengeGenerator()
                pkce = PKCE(clientId: "CLIENTID", url: domain, redirectURL: redirectURL, generator: generator)

                expect(pkce.defaults["code_challenge_method"]) == generator.method
                expect(pkce.defaults["code_challenge"]) == generator.challenge
                expect(pkce.verifier) == generator.verifier
            }
        }
    }

}