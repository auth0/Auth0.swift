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
#if SWIFT_PACKAGE
import Auth0ObjectiveC
#endif

@testable import Auth0

class OAuth2GrantSpec: QuickSpec {

    override func spec() {

        let domain = URL.a0_url("samples.auth0.com")
        let authentication = Auth0Authentication(clientId: "CLIENT_ID", url: domain)
        let idToken = generateJWT(iss: "\(domain.absoluteString)/", aud: [authentication.clientId]).string
        let nonce = "a1b2c3d4e5"
        let issuer = "\(domain.absoluteString)/"
        let leeway = 60 * 1000

        describe("ImplicitGrant") {

            var implicit: ImplicitGrant!

            beforeEach {
                implicit = ImplicitGrant(authentication: authentication, issuer: issuer, leeway: leeway)
                stub(condition: isJWKSPath(domain.host!)) { _ in jwksResponse() }
            }

            it("shoud build credentials") {
                let token = UUID().uuidString
                let values = ["access_token": token, "token_type": "bearer"]
                waitUntil { done in
                    implicit.credentials(from: values) {
                        expect($0).to(haveCredentials(token))
                        done()
                    }
                }
            }

            it("shoud report error to get credentials") {
                waitUntil { done in
                    implicit.credentials(from: [:]) {
                        expect($0).to(beFailure())
                        done()
                    }
                }
            }

            it("should specify response type") {
                expect(implicit.responseType.contains(.token)).to(beTrue())
            }

            describe("ImplicitGrant with id_token") {

                beforeEach {
                    implicit = ImplicitGrant(authentication: authentication, responseType: [.idToken], issuer: issuer, leeway: leeway, nonce: nonce)
                }

                it("should build credentials") {
                    let values = ["id_token": idToken]
                    waitUntil { done in
                        implicit.credentials(from: values) {
                            expect($0).to(haveCredentials())
                            done()
                        }
                    }
                }

                it("should fail with an invalid id_token") {
                    let values = ["id_token": generateJWT(iss: nil).string]
                    waitUntil { done in
                        implicit.credentials(from: values) {
                            expect($0).to(beFailure())
                            done()
                        }
                    }
                }

                it("should fail with no id_token") {
                    let values = ["": ""]
                    waitUntil { done in
                        implicit.credentials(from: values) {
                            expect($0).to(beFailure())
                            done()
                        }
                    }
                }

            }

        }


        describe("Authorization Code w/PKCE") {

            let method = "S256"
            let redirectURL = URL(string: "https://samples.auth0.com/callback")!
            var verifier: String!
            var challenge: String!
            var pkce: PKCE!
            let response: [ResponseType] = [.code]

            beforeEach {
                verifier = "\(arc4random())"
                challenge = "\(arc4random())"
                pkce = PKCE(authentication: authentication, redirectURL: redirectURL, verifier: verifier, challenge: challenge, method: method, responseType: response, issuer: issuer, leeway: leeway, nonce: nil)
            }

            afterEach {
                HTTPStubs.removeAllStubs()
                stub(condition: isHost(domain.host!)) { _ in
                    return HTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
                    }.name = "YOU SHALL NOT PASS!"
            }

            it("shoud build credentials") {
                let token = UUID().uuidString
                let code = UUID().uuidString
                let values = ["code": code]
                stub(condition: isToken(domain.host!) && hasAtLeast(["code": code, "code_verifier": pkce.verifier, "grant_type": "authorization_code", "redirect_uri": pkce.redirectURL.absoluteString])) { _ in
                    return authResponse(accessToken: token, idToken: idToken)
                }.name = "Code Exchange Auth"
                waitUntil { done in
                    pkce.credentials(from: values) {
                        expect($0).to(haveCredentials(token))
                        done()
                    }
                }
            }

            it("shoud report error to get credentials") {
                waitUntil { done in
                    pkce.credentials(from: [:]) {
                        expect($0).to(beFailure())
                        done()
                    }
                }
            }

            it("should specify response type") {
                expect(pkce.responseType.contains(.code)).to(beTrue())
            }

            it("should specify pkce parameters") {
                expect(pkce.defaults["code_challenge_method"]) == "S256"
                expect(pkce.defaults["code_challenge"]) == challenge
            }

            it("should get values from generator") {
                let generator = A0SHA256ChallengeGenerator()
                let authentication = Auth0Authentication(clientId: "CLIENT_ID", url: domain)
                pkce = PKCE(authentication: authentication, redirectURL: redirectURL, generator: generator, responseType: response, issuer: issuer, leeway: leeway, nonce: nil)
                
                expect(pkce.defaults["code_challenge_method"]) == generator.method
                expect(pkce.defaults["code_challenge"]) == generator.challenge
                expect(pkce.verifier) == generator.verifier
            }
        }

        describe("Authorization Code w/PKCE and idToken") {

            let domain = URL.a0_url("samples.auth0.com")
            let method = "S256"
            let redirectURL = URL(string: "https://samples.auth0.com/callback")!
            var verifier: String!
            var challenge: String!
            var pkce: PKCE!
            let response: [ResponseType] = [.code, .idToken]
            var authentication: Auth0Authentication!

            beforeEach {
                verifier = "\(arc4random())"
                challenge = "\(arc4random())"
                authentication = Auth0Authentication(clientId: "CLIENT_ID", url: domain)
                pkce = PKCE(authentication: authentication, redirectURL: redirectURL, verifier: verifier, challenge: challenge, method: method, responseType: response, issuer: issuer, leeway: leeway, nonce: nonce)
            }

            afterEach {
                HTTPStubs.removeAllStubs()
                stub(condition: isHost(domain.host!)) { _ in
                    return HTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
                    }.name = "YOU SHALL NOT PASS!"
            }

            it("shoud build credentials") {
                let token = UUID().uuidString
                let code = UUID().uuidString
                let values = ["code": code, "id_token": idToken, "nonce": nonce]
                stub(condition: isToken(domain.host!) && hasAtLeast(["code": code, "code_verifier": pkce.verifier, "grant_type": "authorization_code", "redirect_uri": pkce.redirectURL.absoluteString])) { _ in return authResponse(accessToken: token, idToken: idToken) }.name = "Code Exchange Auth"
                stub(condition: isJWKSPath(domain.host!)) { _ in jwksResponse() }
                waitUntil { done in
                    pkce.credentials(from: values) {
                        expect($0).to(haveCredentials(token))
                        done()
                    }
                }
            }

            it("should fail if no nonce is provided to compare against the id_token") {
                pkce = PKCE(authentication: authentication, redirectURL: redirectURL, verifier: verifier, challenge: challenge, method: method, responseType: response, issuer: issuer, leeway: leeway, nonce: nil)
                let token = UUID().uuidString
                let code = UUID().uuidString
                let values = ["code": code, "id_token": idToken]
                stub(condition: isToken(domain.host!) && hasAtLeast(["code": code, "code_verifier": pkce.verifier, "grant_type": "authorization_code", "redirect_uri": pkce.redirectURL.absoluteString])) { _ in return authResponse(accessToken: token, idToken: idToken) }.name = "Code Exchange Auth"
                waitUntil { done in
                    pkce.credentials(from: values) {
                        expect($0).to(beFailure())
                        done()
                    }
                }
            }
            
            it("should fail with an invalid id_token") {
                pkce = PKCE(authentication: authentication, redirectURL: redirectURL, verifier: verifier, challenge: challenge, method: method, responseType: response, issuer: issuer, leeway: leeway, nonce: nonce)
                let token = UUID().uuidString
                let code = UUID().uuidString
                let values = ["code": code, "id_token": generateJWT(iss: nil, nonce: nonce).string, "nonce": nonce]
                stub(condition: isToken(domain.host!) && hasAtLeast(["code": code, "code_verifier": pkce.verifier, "grant_type": "authorization_code", "redirect_uri": pkce.redirectURL.absoluteString])) { _ in return authResponse(accessToken: token, idToken: idToken) }.name = "Code Exchange Auth"
                waitUntil { done in
                    pkce.credentials(from: values) {
                        expect($0).to(beFailure())
                        done()
                    }
                }
            }

            it("shoud report error to get credentials") {
                waitUntil { done in
                    pkce.credentials(from: [:]) {
                        expect($0).to(beFailure())
                        done()
                    }
                }
            }

            it("should specify response type") {
                expect(pkce.responseType.contains(.code)).to(beTrue())
                expect(pkce.responseType.contains(.idToken)).to(beTrue())
            }

            it("should specify pkce parameters") {
                expect(pkce.defaults["code_challenge_method"]) == "S256"
                expect(pkce.defaults["code_challenge"]) == challenge
            }

            it("should get values from generator") {
                let generator = A0SHA256ChallengeGenerator()
                let authentication = Auth0Authentication(clientId: "CLIENT_ID", url: domain)
                pkce = PKCE(authentication: authentication, redirectURL: redirectURL, generator: generator, responseType: response, issuer: issuer, leeway: leeway, nonce: nonce)

                expect(pkce.defaults["code_challenge_method"]) == generator.method
                expect(pkce.defaults["code_challenge"]) == generator.challenge
                expect(pkce.verifier) == generator.verifier
            }
        }
    }
    
}
