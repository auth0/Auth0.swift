// AuthenticationSpec.swift
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

private let ClientId = "CLIENT_ID"
private let Domain = "samples.auth0.com"

private let Timeout: NSTimeInterval = 1000000


private let SupportAtAuth0 = "support@auth0.com"
private let ValidPassword = "I.O.U. a password"
private let InvalidPassword = "InvalidPassword"
private let ConnectionName = "Username-Password-Authentication"
private let AccessToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
private let IdToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")

class AuthenticationSpec: QuickSpec {
    override func spec() {

        let auth = Authentication(clientId: ClientId, url: NSURL(string: "https://\(Domain)")!, manager: TestManager())

        afterEach {
            OHHTTPStubs.removeAllStubs()
            stub(isHost(Domain)) { _ in
                return OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
                }.name = "YOU SHALL NOT PASS!"
        }

        context("login") {

            beforeEach {
                stub(isResourceOwner(Domain) && hasAllOf(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                stub(isResourceOwner(Domain) && hasAllOf(["username":SupportAtAuth0, "password": ValidPassword]) && hasNoneOf(["scope": "openid"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Custom Scope Auth"
                stub(isResourceOwner(Domain) && hasAllOf(["password": InvalidPassword])) { _ in return OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil)) }.name = "Not Authorized"
            }

            it("should login with username and password") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(SupportAtAuth0, password: ValidPassword, connection: ConnectionName) { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should have an access_token") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(SupportAtAuth0, password: ValidPassword, connection: ConnectionName, scope: "read:users") { result in
                        expect(result).to(haveCredentials(AccessToken))
                        done()
                    }
                }
            }

            it("should have both token when scope is 'openid'") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(SupportAtAuth0, password: ValidPassword, connection: ConnectionName, scope: "openid") { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

            it("should report when fails to login") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(SupportAtAuth0, password: "invalid", connection: ConnectionName) { result in
                        expect(result).toNot(haveCredentials())
                        done()
                    }
                }
            }

            it("should provide error payload from auth api") {

                waitUntil(timeout: Timeout) { done in
                    let code = "invalid_username_password"
                    let description = "Invalid password"
                    let password = "return invalid password"
                    stub(isResourceOwner(Domain) && hasAllOf(["password": password])) { _ in return authFailure(code: code, description: description) }
                    auth.login(SupportAtAuth0, password: password, connection: ConnectionName) { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should provide error payload from lock auth api") {

                waitUntil(timeout: Timeout) { done in
                    let code = "invalid_username_password"
                    let description = "Invalid password"
                    let password = "return invalid password"
                    stub(isResourceOwner(Domain) && hasAllOf(["password": password])) { _ in return authFailure(error: code, description: description) }
                    auth.login(SupportAtAuth0, password: password, connection: ConnectionName) { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should send additional parameters") {
                let token = "special token for state"
                let state = NSUUID().UUIDString
                let password = NSUUID().UUIDString
                stub(isResourceOwner(Domain) && hasAllOf(["password": password, "state": state])) { _ in return authResponse(accessToken: token) }.name = "Custom Parameter Auth"
                waitUntil(timeout: Timeout) { done in
                    auth.login("mail@auth0.com", password: password, connection: ConnectionName, parameters: ["state": state]) { result in
                        expect(result).to(haveCredentials(token))
                        done()
                    }
                }
            }
            
        }

    }
}