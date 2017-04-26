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

private let Phone = "+144444444444"
private let ValidPassword = "I.O.U. a password"
private let InvalidPassword = "InvalidPassword"
private let ConnectionName = "Username-Password-Authentication"
private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let FacebookToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let InvalidFacebookToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let Timeout: TimeInterval = 2

class AuthenticationSpec: QuickSpec {
    override func spec() {

        let auth: Authentication = Auth0Authentication(clientId: ClientId, url: URL(string: "https://\(Domain)")!)

        beforeEach {
            stub(condition: isHost(Domain)) { _ in
                return OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
                }.name = "YOU SHALL NOT PASS!"
        }

        afterEach {
            OHHTTPStubs.removeAllStubs()
        }

        describe("login") {

            beforeEach {
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword]) && hasNoneOf(["scope": "openid"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Custom Scope Auth"
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["password": InvalidPassword])) { _ in return OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil)) }.name = "Not Authorized"
            }

            it("should login with username and password") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should have an access_token") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, connection: ConnectionName, scope: "read:users").start { result in
                        expect(result).to(haveCredentials(AccessToken))
                        done()
                    }
                }
            }

            it("should have both token when scope is 'openid'") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, connection: ConnectionName, scope: "openid").start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

            it("should report when fails to login") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: "invalid", connection: ConnectionName).start { result in
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
                    stub(condition: isResourceOwner(Domain) && hasAtLeast(["password": password])) { _ in return authFailure(code: code, description: description) }.name = "invalid password"
                    auth.login(usernameOrEmail: SupportAtAuth0, password: password, connection: ConnectionName).start { result in
                        expect(result).to(haveAuthenticationError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should provide error payload from lock auth api") {

                waitUntil(timeout: Timeout) { done in
                    let code = "invalid_username_password"
                    let description = "Invalid password"
                    let password = "return invalid password"
                    stub(condition: isResourceOwner(Domain) && hasAtLeast(["password": password])) { _ in return authFailure(error: code, description: description) }.name = "invalid password"
                    auth.login(usernameOrEmail: SupportAtAuth0, password: password, connection: ConnectionName).start { result in
                        expect(result).to(haveAuthenticationError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should send additional parameters") {
                let token = "special token for state"
                let state = UUID().uuidString
                let password = UUID().uuidString
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["password": password, "state": state])) { _ in return authResponse(accessToken: token) }.name = "Custom Parameter Auth"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: "mail@auth0.com", password: password, connection: ConnectionName, parameters: ["state": state]).start { result in
                        expect(result).to(haveCredentials(token))
                        done()
                    }
                }
            }

        }

        // MARK:- Refresh Tokens

        describe("renew auth with refresh token") {

            let refreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")

            beforeEach {
                stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": refreshToken])) { _ in return authResponse(accessToken: AccessToken) }.name = "refresh_token login"
            }

            it("should receive access token") {
                waitUntil(timeout: Timeout) { done in
                    auth.renew(withRefreshToken: refreshToken).start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should receive access token sending also scope") {
                waitUntil(timeout: Timeout) { done in
                    auth.renew(withRefreshToken: refreshToken, scope: "openid").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should fail to recieve access token") {
                waitUntil(timeout: Timeout) { done in
                    auth.renew(withRefreshToken: "invalidtoken").start { result in
                        expect(result).toNot(haveCredentials())
                        done()
                    }
                }
            }

        }

        describe("renew auth with refresh token") {

            let refreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")

            it("should revoke token") {
                stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": refreshToken])) { _ in
                    return revokeTokenResponse() }.name = "revokeToken"
                waitUntil(timeout: Timeout) { done in
                    auth.revoke(refreshToken: refreshToken).start { result in
                        guard case .success = result else { return fail("Failed to revoke token") }
                        done()
                    }
                }
            }

            it("should handle errors") {
                let code = "invalid_request"
                let description = "missing params"
                stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": refreshToken])) { _ in
                    return authFailure(code: code, description: description) }.name = "revoke failed"
                waitUntil(timeout: Timeout) { done in
                    auth.revoke(refreshToken: refreshToken).start { result in
                        expect(result).to(haveAuthenticationError(code: code, description: description))
                        done()
                    }
                }
            }

        }

        // MARK:- Delegation
        describe("delegation") {

            let refreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")

            beforeEach {
                let delegationPayload = [
                    "refresh_token": refreshToken,
                    "client_id": ClientId,
                    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                    "api_type": "app",
                    "scope": "openid"
                ]
                stub(condition: isMethodPOST() && isHost(Domain) && isPath("/delegation") && hasAllOf(delegationPayload)) { _ in return authResponse(accessToken: AccessToken) }.name = "delegation with refresh token"
            }

            it("should receive access token") {
                waitUntil(timeout: Timeout) { done in
                    auth.delegation(withParameters: [
                        "refresh_token": refreshToken,
                        "api_type": "app",
                        "scope": "openid"
                        ]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                    }
                }
            }

            it("should fail to recieve access token") {
                waitUntil(timeout: Timeout) { done in
                    auth.delegation(withParameters: [:]).start { result in
                        expect(result).to(beFailure())
                        done()
                    }
                }
            }

        }

        // MARK:- password-realm grant type
        describe("authenticating with credentials in a realm") {

            it("should receive token with username and password") {
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "realm": "myrealm"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password"

                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realm: "myrealm").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should fail to return token") {
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "realm": "myrealm"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: "invalid", realm: "myrealm").start { result in
                        expect(result).toNot(haveCredentials())
                        done()
                    }
                }
            }

            it("should specify scope in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid", "realm": "myrealm"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom Scope"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realm: "myrealm", scope: "openid").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should specify audience in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "audience" : "https://myapi.com/api", "realm": "myrealm"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom Scope and audience"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realm: "myrealm", audience: "https://myapi.com/api").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should specify audience and scope in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid", "audience" : "https://myapi.com/api", "realm": "myrealm"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom Scope and audience"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realm: "myrealm", audience: "https://myapi.com/api", scope: "openid").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should specify audience,scope and realm in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid", "audience" : "https://myapi.com/api", "realm" : "customconnection"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom audience, scope and realm"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realm: "customconnection", audience: "https://myapi.com/api", scope: "openid").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

        }

        describe("create user") {

            beforeEach {
                stub(condition: isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/email"
                stub(condition: isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "username": Support, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0, username: Support) }.name = "User w/username"
            }

            it("should create a user with email & password") {
                waitUntil(timeout: Timeout) { done in
                    auth.createUser(email: SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveCreatedUser(SupportAtAuth0))
                        done()
                    }
                }
            }


            it("should create a user with email, username & password") {
                waitUntil(timeout: Timeout) { done in
                    auth.createUser(email: SupportAtAuth0, username: Support, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveCreatedUser(SupportAtAuth0, username: Support))
                        done()
                    }
                }
            }

            it("should provide error payload from auth api") {

                waitUntil(timeout: Timeout) { done in
                    let code = "invalid_username_password"
                    let description = "Invalid password"
                    let password = "return invalid password"
                    stub(condition: isSignUp(Domain) && hasAtLeast(["password": password])) { _ in return authFailure(code: code, description: description) }.name = "invalid password"
                    auth.createUser(email: SupportAtAuth0, password: password, connection: ConnectionName).start { result in
                        expect(result).to(haveAuthenticationError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should send user metadata") {
                let country = "Argentina"
                let email = "metadata@auth0.com"
                let metadata = ["country": country]
                stub(condition: isSignUp(Domain) && hasUserMetadata(metadata)) { _ in return createdUser(email: email) }.name = "User w/metadata"
                waitUntil(timeout: Timeout) { done in
                    auth.createUser(email: email, password: ValidPassword, connection: ConnectionName, userMetadata: metadata).start { result in
                        expect(result).to(haveCreatedUser(email))
                        done()
                    }
                }
            }

        }

        describe("reset password") {

            it("should reset password") {
                stub(condition: isResetPassword(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": ConnectionName, "client_id": ClientId])) { _ in return resetPasswordResponse() }.name = "reset request sent"
                waitUntil(timeout: Timeout) { done in
                    auth.resetPassword(email: SupportAtAuth0, connection: ConnectionName).start { result in
                        guard case .success = result else { return fail("Failed to reset password") }
                        done()
                    }
                }
            }

            it("should handle errors") {
                let code = "reset_failed"
                let description = "failed reset password"
                stub(condition: isResetPassword(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": ConnectionName, "client_id": ClientId])) { _ in return authFailure(code: code, description: description) }.name = "reset failed"
                waitUntil(timeout: Timeout) { done in
                    auth.resetPassword(email: SupportAtAuth0, connection: ConnectionName).start { result in
                        expect(result).to(haveAuthenticationError(code: code, description: description))
                        done()
                    }
                }
            }

        }

        describe("create user and login") {

            it("should fail if create user fails") {
                let code = "create_failed"
                let description = "failed create user"
                stub(condition: isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return authFailure(code: code, description: description) }.name = "User w/email"
                waitUntil(timeout: Timeout) { done in
                    auth.signUp(email: SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveAuthenticationError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should fail if login fails") {
                let code = "invalid_password_failed"
                let description = "failed to login"
                stub(condition: isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/email"
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authFailure(code: code, description: description) }.name = "OpenID Auth"
                waitUntil(timeout: Timeout) { done in
                    auth.signUp(email: SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveAuthenticationError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should create user and login") {
                stub(condition: isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/email"
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                waitUntil(timeout: Timeout) { done in
                    auth.signUp(email: SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

            it("should login with custom parameters") {
                let state = UUID().uuidString.replacingOccurrences(of: "-", with: "")
                stub(condition: isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/email"
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid", "state": state])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                waitUntil(timeout: Timeout) { done in
                    auth.signUp(email: SupportAtAuth0, password: ValidPassword, connection: ConnectionName, parameters: ["state": state]).start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

            it("should create user with metadata") {
                let country = "Argentina"
                let metadata = ["country": country]
                stub(condition: isSignUp(Domain) && hasUserMetadata(metadata)) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/email"
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                waitUntil(timeout: Timeout) { done in
                    auth.signUp(email: SupportAtAuth0, password: ValidPassword, connection: ConnectionName, userMetadata: metadata).start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

        }

        describe("passwordless email") {

            it("should start with email with default values") {
                stub(condition: isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "email", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0).start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should start with email") {
                stub(condition: isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "custom_email", "client_id": ClientId, "send": "link_ios"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless custom"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .iOSLink, connection: "custom_email").start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should start with email and authParameters for web link") {
                let params = ["scope": "openid"]
                stub(condition: isPasswordless(Domain) && hasAtLeast(["email": SupportAtAuth0]) && hasObjectAttribute("authParams", value: params)) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless web link with parameters"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .WebLink, parameters: params).start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should not send params if type is not web link") {
                let params = ["scope": "openid"]
                stub(condition: isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "email", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless without parameters"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .Code, parameters: params).start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should not add params attr if they are empty") {
                stub(condition: isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "email", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless without parameters"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .Code, parameters: [:]).start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should report failure") {
                stub(condition: isPasswordless(Domain)) { _ in return authFailure(error: "error", description: "description") }.name = "failed passwordless start"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0).start { result in
                        expect(result).to(haveAuthenticationError(code: "error", description: "description"))
                        done()
                    }
                }
            }
        }

        describe("passwordless sms") {

            it("should start with sms with default values") {
                stub(condition: isPasswordless(Domain) && hasAllOf(["phone_number": Phone, "connection": "sms", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "sms passwordless"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(phoneNumber: Phone).start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should start with sms") {
                stub(condition: isPasswordless(Domain) && hasAllOf(["phone_number": Phone, "connection": "custom_sms", "client_id": ClientId, "send": "link_ios"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "sms passwordless custom"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(phoneNumber: Phone, type: .iOSLink, connection: "custom_sms").start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should report failure") {
                stub(condition: isPasswordless(Domain)) { _ in return authFailure(error: "error", description: "description") }.name = "failed passwordless start"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(phoneNumber: Phone).start { result in
                        expect(result).to(haveAuthenticationError(code: "error", description: "description"))
                        done()
                    }
                }
            }
        }

        describe("user information") {
            it("should return token information") {
                stub(condition: isTokenInfo(Domain) && hasAllOf(["id_token": IdToken])) { _ in return tokenInfo() }.name = "token info"
                waitUntil(timeout: Timeout) { done in
                    auth.tokenInfo(token: IdToken).start { result in
                        expect(result).to(haveProfile(UserId))
                        done()
                    }
                }
            }

            it("should report failure to get token info") {
                stub(condition: isTokenInfo(Domain)) { _ in return authFailure(error: "invalid_token", description: "the token is invalid") }.name = "token info failed"
                waitUntil(timeout: Timeout) { done in
                    auth.tokenInfo(token: IdToken).start { result in
                        expect(result).to(haveAuthenticationError(code: "invalid_token", description: "the token is invalid"))
                        done()
                    }
                }
            }

            it("should return user information") {
                stub(condition: isUserInfo(Domain) && hasBearerToken(AccessToken)) { _ in return userInfo() }.name = "user info"
                waitUntil(timeout: Timeout) { done in
                    auth.userInfo(token: AccessToken).start { result in
                        expect(result).to(haveProfile(UserId))
                        done()
                    }
                }
            }

            it("should report failure to get user info") {
                stub(condition: isUserInfo(Domain)) { _ in return authFailure(error: "invalid_token", description: "the token is invalid") }.name = "token info failed"
                waitUntil(timeout: Timeout) { done in
                    auth.userInfo(token: IdToken).start { result in
                        expect(result).to(haveAuthenticationError(code: "invalid_token", description: "the token is invalid"))
                        done()
                    }
                }
            }

        }

        describe("social login") {

            beforeEach {
                stub(condition: isOAuthAccessToken(Domain) && hasAtLeast(["access_token":FacebookToken, "connection": "facebook", "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Facebook Auth OpenID"
                stub(condition: isOAuthAccessToken(Domain) && hasAtLeast(["access_token":FacebookToken, "connection": "facebook"]) && hasNoneOf(["scope": "openid"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Custom Scope Facebook Auth"
                stub(condition: isOAuthAccessToken(Domain) && hasAtLeast(["access_token": InvalidFacebookToken])) { _ in return OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil)) }.name = "Not Authorized"
            }

            it("should login with social IdP token") {
                waitUntil(timeout: Timeout) { done in
                    auth.loginSocial(token: FacebookToken, connection: "facebook").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should have an access_token") {
                waitUntil(timeout: Timeout) { done in
                    auth.loginSocial(token: FacebookToken, connection: "facebook", scope: "read:users").start { result in
                        expect(result).to(haveCredentials(AccessToken))
                        done()
                    }
                }
            }

            it("should have both token when scope is 'openid'") {
                waitUntil(timeout: Timeout) { done in
                    auth.loginSocial(token: FacebookToken, connection: "facebook", scope: "openid").start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

            it("should report when fails to login") {
                waitUntil(timeout: Timeout) { done in
                    auth.loginSocial(token: InvalidFacebookToken, connection: "facebook").start { result in
                        expect(result).toNot(haveCredentials())
                        done()
                    }
                }
            }

            it("should provide error payload from auth api") {

                waitUntil(timeout: Timeout) { done in
                    let code = "invalid_token"
                    let description = "Invalid token"
                    let token = "return invalid token"
                    stub(condition: isOAuthAccessToken(Domain) && hasAtLeast(["access_token": token])) { _ in return authFailure(code: code, description: description) }.name = "invalid token"
                    auth.loginSocial(token: token, connection: "facebook").start { result in
                        expect(result).to(haveAuthenticationError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should provide error payload from lock auth api") {

                waitUntil(timeout: Timeout) { done in
                    let code = "invalid_token"
                    let description = "Invalid token"
                    let token = "return invalid token"
                    stub(condition: isOAuthAccessToken(Domain) && hasAtLeast(["access_token": token])) { _ in return authFailure(error: code, description: description) }.name = "invalid token"
                    auth.loginSocial(token: token, connection: "facebook").start { result in
                        expect(result).to(haveAuthenticationError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should send additional parameters") {
                let accessToken = "special token for state"
                let state = UUID().uuidString
                let token = UUID().uuidString
                stub(condition: isOAuthAccessToken(Domain) && hasAtLeast(["access_token": token, "state": state])) { _ in return authResponse(accessToken: accessToken) }.name = "Custom Parameter Auth"
                waitUntil(timeout: Timeout) { done in
                    auth.loginSocial(token: token, connection: "facebook", parameters: ["state": state]).start { result in
                        expect(result).to(haveCredentials(accessToken))
                        done()
                    }
                }
            }

        }

        describe("code exchange") {

            var code: String!
            var codeVerifier: String!
            let redirectURI = "https://samples.auth0.com/callback"

            beforeEach {
                code = UUID().uuidString.replacingOccurrences(of: "-", with: "")
                codeVerifier = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            }


            it("should exchange code for tokens") {
                stub(condition: isToken(Domain) && hasAtLeast(["code": code, "code_verifier": codeVerifier, "grant_type": "authorization_code", "redirect_uri": redirectURI])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Code Exchange Auth"
                waitUntil(timeout: Timeout) { done in
                    auth.tokenExchange(withCode: code, codeVerifier: codeVerifier, redirectURI: redirectURI).start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

            it("should provide error payload from auth api") {

                waitUntil(timeout: Timeout) { done in
                    let code = "invalid_code"
                    let description = "Invalid code"
                    let invalidCode = "return invalid code"
                    stub(condition: isToken(Domain) && hasAtLeast(["code": invalidCode])) { _ in return authFailure(code: code, description: description) }.name = "Invalid Code"
                    auth.tokenExchange(withCode: invalidCode, codeVerifier: codeVerifier, redirectURI: redirectURI).start { result in
                        expect(result).to(haveAuthenticationError(code: code, description: description))
                        done()
                    }
                }
            }

        }

        describe("resource owner multifactor") {

            var code: String!

            beforeEach {
                code = UUID().uuidString.replacingOccurrences(of: "-", with: "")
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword]) && hasNoneOf(["mfa_code"])) { _ in return authFailure(error: "a0.mfa_required", description: "need multifactor") }.name = "MFA Required"
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "mfa_code": code])) { _ in return authResponse(accessToken: AccessToken) }.name = "MFA Login"
            }

            it("should report multifactor is required") {
                waitUntil(timeout: Timeout) { done in
                    auth
                        .login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, connection: ConnectionName)
                        .start { result in
                            expect(result).to(beFailure { (error: AuthenticationError) in return error.isMultifactorRequired })
                            done()
                    }
                }
            }

            it("should login with multifactor") {
                waitUntil(timeout: Timeout) { done in
                    auth
                        .login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, multifactorCode: code, connection: ConnectionName)
                        .start { result in
                            expect(result).to(haveCredentials())
                            done()
                    }
                }
            }
        }

#if os(iOS)
        describe("spawn WebAuth instance") {

            it("should return a WebAuth instance with matching credentials") {
                let webAuth = auth.webAuth(withConnection: "facebook")
                expect(webAuth.clientId) == auth.clientId
                expect(webAuth.url) == auth.url
            }

            it("should return a WebAuth instance with matching telemetry") {
                let webAuth = auth.webAuth(withConnection: "facebook") as! SafariWebAuth
                expect(webAuth.telemetry.info) == auth.telemetry.info
            }

            it("should return a WebAuth instance with matching connection") {
                let webAuth = auth.webAuth(withConnection: "facebook") as! SafariWebAuth
                expect(webAuth.parameters["connection"]) == "facebook"
            }
        }
#endif

    }
}
