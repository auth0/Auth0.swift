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
private let AccessToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
private let IdToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
private let FacebookToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
private let InvalidFacebookToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
private let Timeout: NSTimeInterval = 2

class AuthenticationSpec: QuickSpec {
    override func spec() {

        let auth = Authentication(clientId: ClientId, url: NSURL(string: "https://\(Domain)")!)

        afterEach {
            OHHTTPStubs.removeAllStubs()
            stub(isHost(Domain)) { _ in
                return OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
                }.name = "YOU SHALL NOT PASS!"
        }

        describe("login") {

            beforeEach {
                stub(isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                stub(isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword]) && hasNoneOf(["scope": "openid"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Custom Scope Auth"
                stub(isResourceOwner(Domain) && hasAtLeast(["password": InvalidPassword])) { _ in return OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil)) }.name = "Not Authorized"
            }

            it("should login with username and password") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should have an access_token") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(SupportAtAuth0, password: ValidPassword, connection: ConnectionName, scope: "read:users").start { result in
                        expect(result).to(haveCredentials(AccessToken))
                        done()
                    }
                }
            }

            it("should have both token when scope is 'openid'") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(SupportAtAuth0, password: ValidPassword, connection: ConnectionName, scope: "openid").start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

            it("should report when fails to login") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(SupportAtAuth0, password: "invalid", connection: ConnectionName).start { result in
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
                    stub(isResourceOwner(Domain) && hasAtLeast(["password": password])) { _ in return authFailure(code: code, description: description) }
                    auth.login(SupportAtAuth0, password: password, connection: ConnectionName).start { result in
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
                waitUntil(timeout: Timeout) { done in
                    auth.login("mail@auth0.com", password: password, connection: ConnectionName, parameters: ["state": state]).start { result in
                        expect(result).to(haveCredentials(token))
                        done()
                    }
                }
            }
            
        }

        describe("create user") {

            beforeEach {
                stub(isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/email"
                stub(isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "username": Support, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0, username: Support) }.name = "User w/username"
            }

            it("should create a user with email & password") {
                waitUntil(timeout: Timeout) { done in
                    auth.createUser(SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveCreatedUser(SupportAtAuth0))
                        done()
                    }
                }
            }


            it("should create a user with email, username & password") {
                waitUntil(timeout: Timeout) { done in
                    auth.createUser(SupportAtAuth0, username: Support, password: ValidPassword, connection: ConnectionName).start { result in
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
                waitUntil(timeout: Timeout) { done in
                    auth.createUser(email, password: ValidPassword, connection: ConnectionName, userMetadata: metadata).start { result in
                        expect(result).to(haveCreatedUser(email))
                        done()
                    }
                }
            }

        }

        describe("reset password") {

            it("should reset password") {
                stub(isResetPassword(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": ConnectionName, "client_id": ClientId])) { _ in return resetPasswordResponse() }
                waitUntil(timeout: Timeout) { done in
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
                waitUntil(timeout: Timeout) { done in
                    auth.resetPassword(SupportAtAuth0, connection: ConnectionName).start { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

        }

        describe("create user and login") {

            it("should fail if create user fails") {
                let code = "create_failed"
                let description = "failed create user"
                stub(isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return authFailure(code: code, description: description) }.name = "User w/email"
                waitUntil(timeout: Timeout) { done in
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
                waitUntil(timeout: Timeout) { done in
                    auth.signUp(SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should create user and login") {
                stub(isSignUp(Domain) && hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/email"
                stub(isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                waitUntil(timeout: Timeout) { done in
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
                waitUntil(timeout: Timeout) { done in
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
                waitUntil(timeout: Timeout) { done in
                    auth.signUp(SupportAtAuth0, password: ValidPassword, connection: ConnectionName, userMetadata: metadata).start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

        }

        describe("passwordless email") {

            it("should start with email with default values") {
                stub(isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "email", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0).start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should start with email") {
                stub(isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "custom_email", "client_id": ClientId, "send": "link_ios"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless custom"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .iOSLink, connection: "custom_email").start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should start with email and authParameters for web link") {
                let params = ["scope": "openid"]
                stub(isPasswordless(Domain) && hasAtLeast(["email": SupportAtAuth0]) && hasObjectAttribute("authParams", value: params)) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless web link with parameters"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .WebLink, parameters: params).start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should not send params if type is not web link") {
                let params = ["scope": "openid"]
                stub(isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "email", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless without parameters"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .Code, parameters: params).start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should not add params attr if they are empty") {
                stub(isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "email", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless without parameters"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .Code, parameters: [:]).start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should report failure") {
                stub(isPasswordless(Domain)) { _ in return authFailure(error: "error", description: "description") }.name = "failed passwordless start"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0).start { result in
                        expect(result).to(haveError(code: "error", description: "description"))
                        done()
                    }
                }
            }
        }

        describe("passwordless sms") {

            it("should start with sms with default values") {
                stub(isPasswordless(Domain) && hasAllOf(["phone_number": Phone, "connection": "sms", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "sms passwordless"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(phoneNumber: Phone).start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should start with sms") {
                stub(isPasswordless(Domain) && hasAllOf(["phone_number": Phone, "connection": "custom_sms", "client_id": ClientId, "send": "link_ios"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "sms passwordless custom"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(phoneNumber: Phone, type: .iOSLink, connection: "custom_sms").start { result in
                        expect(result).to(beSuccessfulResult())
                        done()
                    }
                }
            }

            it("should report failure") {
                stub(isPasswordless(Domain)) { _ in return authFailure(error: "error", description: "description") }.name = "failed passwordless start"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(phoneNumber: Phone).start { result in
                        expect(result).to(haveError(code: "error", description: "description"))
                        done()
                    }
                }
            }
        }

        describe("user information") {
            it("should return token information") {
                stub(isTokenInfo(Domain) && hasAllOf(["id_token": IdToken])) { _ in return tokenInfo() }.name = "token info"
                waitUntil(timeout: Timeout) { done in
                    auth.tokenInfo(IdToken).start { result in
                        expect(result).to(haveProfile(UserId))
                        done()
                    }
                }
            }

            it("should report failure to get token info") {
                stub(isTokenInfo(Domain)) { _ in return authFailure(error: "invalid_token", description: "the token is invalid") }.name = "token info failed"
                waitUntil(timeout: Timeout) { done in
                    auth.tokenInfo(IdToken).start { result in
                        expect(result).to(haveError(code: "invalid_token", description: "the token is invalid"))
                        done()
                    }
                }
            }

            it("should return user information") {
                stub(isUserInfo(Domain) && hasBearerToken(AccessToken)) { _ in return userInfo() }.name = "user info"
                waitUntil(timeout: Timeout) { done in
                    auth.userInfo(AccessToken).start { result in
                        expect(result).to(haveProfile(UserId))
                        done()
                    }
                }
            }

            it("should report failure to get user info") {
                stub(isUserInfo(Domain)) { _ in return authFailure(error: "invalid_token", description: "the token is invalid") }.name = "token info failed"
                waitUntil(timeout: Timeout) { done in
                    auth.userInfo(IdToken).start { result in
                        expect(result).to(haveError(code: "invalid_token", description: "the token is invalid"))
                        done()
                    }
                }
            }

        }

        describe("social login") {

            beforeEach {
                stub(isOAuthAccessToken(Domain) && hasAtLeast(["access_token":FacebookToken, "connection": "facebook", "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Facebook Auth OpenID"
                stub(isOAuthAccessToken(Domain) && hasAtLeast(["access_token":FacebookToken, "connection": "facebook"]) && hasNoneOf(["scope": "openid"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Custom Scope Facebook Auth"
                stub(isOAuthAccessToken(Domain) && hasAtLeast(["access_token": InvalidFacebookToken])) { _ in return OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil)) }.name = "Not Authorized"
            }

            it("should login with social IdP token") {
                waitUntil(timeout: Timeout) { done in
                    auth.loginSocial(FacebookToken, connection: "facebook").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should have an access_token") {
                waitUntil(timeout: Timeout) { done in
                    auth.loginSocial(FacebookToken, connection: "facebook", scope: "read:users").start { result in
                        expect(result).to(haveCredentials(AccessToken))
                        done()
                    }
                }
            }

            it("should have both token when scope is 'openid'") {
                waitUntil(timeout: Timeout) { done in
                    auth.loginSocial(FacebookToken, connection: "facebook", scope: "openid").start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }

            it("should report when fails to login") {
                waitUntil(timeout: Timeout) { done in
                    auth.loginSocial(InvalidFacebookToken, connection: "facebook").start { result in
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
                    stub(isOAuthAccessToken(Domain) && hasAtLeast(["access_token": token])) { _ in return authFailure(code: code, description: description) }
                    auth.loginSocial(token, connection: "facebook").start { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should provide error payload from lock auth api") {

                waitUntil(timeout: Timeout) { done in
                    let code = "invalid_token"
                    let description = "Invalid token"
                    let token = "return invalid token"
                    stub(isOAuthAccessToken(Domain) && hasAtLeast(["access_token": token])) { _ in return authFailure(error: code, description: description) }
                    auth.loginSocial(token, connection: "facebook").start { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

            it("should send additional parameters") {
                let accessToken = "special token for state"
                let state = NSUUID().UUIDString
                let token = NSUUID().UUIDString
                stub(isOAuthAccessToken(Domain) && hasAtLeast(["access_token": token, "state": state])) { _ in return authResponse(accessToken: accessToken) }.name = "Custom Parameter Auth"
                waitUntil(timeout: Timeout) { done in
                    auth.loginSocial(token, connection: "facebook", parameters: ["state": state]).start { result in
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
                code = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
                codeVerifier = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
            }


            it("should exchange code for tokens") {
                stub(isToken(Domain) && hasAtLeast(["code": code, "code_verifier": codeVerifier, "grant_type": "authorization_code", "redirect_uri": redirectURI])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Code Exchange Auth"
                waitUntil(timeout: Timeout) { done in
                    auth.exchangeCode(code, codeVerifier: codeVerifier, redirectURI: redirectURI).start { result in
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
                    stub(isToken(Domain) && hasAtLeast(["code": invalidCode])) { _ in return authFailure(code: code, description: description) }.name = "Invalid Code"
                    auth.exchangeCode(invalidCode, codeVerifier: codeVerifier, redirectURI: redirectURI).start { result in
                        expect(result).to(haveError(code: code, description: description))
                        done()
                    }
                }
            }

        }

    }
}