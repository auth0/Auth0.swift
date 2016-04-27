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

private let SupportAtAuth0 = "support@auth0.com"
private let Support = "support"
private let ValidPassword = "I.O.U. a password"
private let InvalidPassword = "InvalidPassword"
private let ConnectionName = "Username-Password-Authentication"
private let AccessToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
private let IdToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")

class AuthenticationSpec: QuickSpec {
    override func spec() {

        let auth = Authentication(clientId: ClientId, url: NSURL(string: "https://\(Domain)")!)

        afterEach {
            OHHTTPStubs.removeAllStubs()
            stub(isHost(Domain)) { _ in
                return OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
                }.name = "YOU SHALL NOT PASS!"
        }

        context("login") {

            beforeEach {
                stub(isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                stub(isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword]) && hasNoneOf(["scope": "openid"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Custom Scope Auth"
                stub(isResourceOwner(Domain) && hasAtLeast(["password": InvalidPassword])) { _ in return OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil)) }.name = "Not Authorized"
            }

            it("should login with username and password") {
                waitUntil { done in
                    auth.login(SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should have an access_token") {
                waitUntil { done in
                    auth.login(SupportAtAuth0, password: ValidPassword, connection: ConnectionName, scope: "read:users").start { result in
                        expect(result).to(haveCredentials(AccessToken))
                        done()
                    }
                }
            }

            it("should have both token when scope is 'openid'") {
                waitUntil { done in
                    auth.login(SupportAtAuth0, password: ValidPassword, connection: ConnectionName, scope: "openid").start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

            it("should report when fails to login") {
                waitUntil { done in
                    auth.login(SupportAtAuth0, password: "invalid", connection: ConnectionName).start { result in
                        expect(result).toNot(haveCredentials())
                        done()
                    }
                }
            }

            it("should provide error payload from auth api") {

                waitUntil { done in
                    let code = "invalid_username_password"
                    let description = "Invalid password"
                    let password = "return invalid password"
                    stub(isResourceOwner(Domain) && hasAtLeast(["password": password])) { _ in return authFailure(code: code, description: description) }
                    auth.login(SupportAtAuth0, password: password, connection: ConnectionName).start { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should provide error payload from lock auth api") {

                waitUntil { done in
                    let code = "invalid_username_password"
                    let description = "Invalid password"
                    let password = "return invalid password"
                    stub(isResourceOwner(Domain) && hasAtLeast(["password": password])) { _ in return authFailure(error: code, description: description) }
                    auth.login(SupportAtAuth0, password: password, connection: ConnectionName).start { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should send additional parameters") {
                let token = "special token for state"
                let state = NSUUID().UUIDString
                let password = NSUUID().UUIDString
                stub(isResourceOwner(Domain) && hasAtLeast(["password": password, "state": state])) { _ in return authResponse(accessToken: token) }.name = "Custom Parameter Auth"
                waitUntil { done in
                    auth.login("mail@auth0.com", password: password, connection: ConnectionName, parameters: ["state": state]).start { result in
                        expect(result).to(haveCredentials(token))
                        done()
                    }
                }
            }
            
        }

        context("create user") {

            beforeEach {
                stub(isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/email"
                stub(isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "username": Support, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0, username: Support) }.name = "User w/username"
            }

            it("should create a user with email & password") {
                waitUntil { done in
                    auth.createUser(SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveCreatedUser(SupportAtAuth0))
                        done()
                    }
                }
            }


            it("should create a user with email, username & password") {
                waitUntil { done in
                    auth.createUser(SupportAtAuth0, username: Support, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveCreatedUser(SupportAtAuth0, username: Support))
                        done()
                    }
                }
            }

            it("should provide error payload from auth api") {

                waitUntil { done in
                    let code = "invalid_username_password"
                    let description = "Invalid password"
                    let password = "return invalid password"
                    stub(isSignUp(Domain) && hasAtLeast(["password": password])) { _ in return authFailure(code: code, description: description) }
                    auth.createUser(SupportAtAuth0, password: password, connection: ConnectionName).start { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should send user metadata") {
                let country = "Argentina"
                let email = "metadata@auth0.com"
                let metadata = ["country": country]
                stub(isSignUp(Domain) && hasUserMetadata(metadata)) { _ in return createdUser(email: email) }.name = "User w/metadata"
                waitUntil { done in
                    auth.createUser(email, password: ValidPassword, connection: ConnectionName, userMetadata: metadata).start { result in
                        expect(result).to(haveCreatedUser(email))
                        done()
                    }
                }
            }

        }

        context("reset password") {

            it("should reset password") {
                stub(isResetPassword(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": ConnectionName, "client_id": ClientId])) { _ in return resetPasswordResponse() }
                waitUntil { done in
                    auth.resetPassword(SupportAtAuth0, connection: ConnectionName).start { result in
                        guard case .Success = result else { return fail("Failed to reset password") }
                        done()
                    }
                }
            }

            it("should handle errors") {
                let code = "reset_failed"
                let description = "failed reset password"
                stub(isResetPassword(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": ConnectionName, "client_id": ClientId])) { _ in return authFailure(code: code, description: description) }
                waitUntil { done in
                    auth.resetPassword(SupportAtAuth0, connection: ConnectionName).start { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

        }

        context("create user and login") {

            it("should fail if create user fails") {
                let code = "create_failed"
                let description = "failed create user"
                stub(isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return authFailure(code: code, description: description) }.name = "User w/email"
                waitUntil { done in
                    auth.signUp(SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should fail if login fails") {
                let code = "invalid_password_failed"
                let description = "failed to login"
                stub(isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/email"
                stub(isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authFailure(code: code, description: description) }.name = "OpenID Auth"
                waitUntil { done in
                    auth.signUp(SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should create user and login") {
                stub(isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/email"
                stub(isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                waitUntil { done in
                    auth.signUp(SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

            it("should login with custom parameters") {
                let state = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
                stub(isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/email"
                stub(isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid", "state": state])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                waitUntil { done in
                    auth.signUp(SupportAtAuth0, password: ValidPassword, connection: ConnectionName, parameters: ["state": state]).start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

            it("should create user with metadata") {
                let country = "Argentina"
                let metadata = ["country": country]
                stub(isSignUp(Domain) && hasUserMetadata(metadata)) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/email"
                stub(isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                waitUntil { done in
                    auth.signUp(SupportAtAuth0, password: ValidPassword, connection: ConnectionName, userMetadata: metadata).start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

        }

    }
}