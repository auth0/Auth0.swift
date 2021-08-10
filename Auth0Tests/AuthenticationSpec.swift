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

import Foundation
import Quick
import Nimble
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif

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
private let Timeout: DispatchTimeInterval = .seconds(2)
private let TokenExchangeGrantType = "urn:ietf:params:oauth:grant-type:token-exchange"
private let PasswordlessGrantType = "http://auth0.com/oauth/grant-type/passwordless/otp"

class AuthenticationSpec: QuickSpec {
    override func spec() {

        let auth: Authentication = Auth0Authentication(clientId: ClientId, url: URL(string: "https://\(Domain)")!)

        beforeEach {
            stub(condition: isHost(Domain)) { _ in
                return HTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
                }.name = "YOU SHALL NOT PASS!"
        }

        afterEach {
            HTTPStubs.removeAllStubs()
        }

        describe("login") {

            beforeEach {
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword]) && hasNoneOf(["scope": "openid"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Custom Scope Auth"
                stub(condition: isResourceOwner(Domain) && hasAtLeast(["password": InvalidPassword])) { _ in return HTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil)) }.name = "Not Authorized"
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

        describe("login MFA OTP") {

            beforeEach {
                stub(condition: isToken(Domain) && hasAtLeast(["otp": OTP, "mfa_token": MFAToken])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                stub(condition: isToken(Domain) && hasAtLeast(["otp": "bad_otp", "mfa_token": MFAToken])) { _ in return authFailure(code: "invalid_grant", description: "Invalid otp_code.") }.name = "invalid otp"
                stub(condition: isToken(Domain) && hasAtLeast(["otp": OTP, "mfa_token": "bad_token"])) { _ in return authFailure(code: "invalid_grant", description: "Malformed mfa_token") }.name = "invalid mfa_token"
            }

            it("should login with otp and mfa tokens") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(withOTP: OTP, mfaToken: MFAToken).start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should fail login with bad otp") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(withOTP: "bad_otp", mfaToken: MFAToken).start { result in
                        expect(result).to(haveAuthenticationError(code: "invalid_grant", description: "Invalid otp_code."))
                        done()
                    }
                }
            }

            it("should fail login with invalid mfa") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(withOTP: OTP, mfaToken: "bad_token").start { result in
                        expect(result).to(haveAuthenticationError(code: "invalid_grant", description: "Malformed mfa_token"))
                        done()
                    }
                }
            }
        }

        describe("login MFA OOB") {

            beforeEach {
                stub(condition: isToken(Domain) && hasAtLeast(["oob_code": OOB, "mfa_token": MFAToken, "binding_code": BindingCode])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                stub(condition: isToken(Domain) && hasAtLeast(["oob_code": "bad_oob", "mfa_token": MFAToken])) { _ in return authFailure(code: "invalid_grant", description: "Invalid oob_code.") }.name = "invalid oob_code"
                stub(condition: isToken(Domain) && hasAtLeast(["oob_code": OOB, "mfa_token": "bad_token"])) { _ in return authFailure(code: "invalid_grant", description: "Malformed mfa_token") }.name = "invalid mfa_token"
            }

            it("should login with oob code and mfa tokens") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(withOOBCode: OOB, mfaToken: MFAToken, bindingCode: BindingCode).start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should fail login with bad oob code") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(withOOBCode: "bad_oob", mfaToken: MFAToken, bindingCode: nil).start { result in
                        expect(result).to(haveAuthenticationError(code: "invalid_grant", description: "Invalid oob_code."))
                        done()
                    }
                }
            }

            it("should fail login with invalid mfa") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(withOOBCode: OOB, mfaToken: "bad_token", bindingCode: nil).start { result in
                        expect(result).to(haveAuthenticationError(code: "invalid_grant", description: "Malformed mfa_token"))
                        done()
                    }
                }
            }
        }

        describe("login MFA recovery code") {

            beforeEach {
                stub(condition: isToken(Domain) && hasAtLeast(["recovery_code": RecoveryCode, "mfa_token": MFAToken])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                stub(condition: isToken(Domain) && hasAtLeast(["recovery_code": "bad_recovery", "mfa_token": MFAToken])) { _ in return authFailure(code: "invalid_grant", description: "Invalid recovery_code.") }.name = "invalid recovery code"
                stub(condition: isToken(Domain) && hasAtLeast(["recovery_code": RecoveryCode, "mfa_token": "bad_token"])) { _ in return authFailure(code: "invalid_grant", description: "Malformed mfa_token") }.name = "invalid mfa_token"
            }

            it("should login with recovery code and mfa tokens") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(withRecoveryCode: RecoveryCode, mfaToken: MFAToken).start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should fail login with bad recovery code") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(withRecoveryCode: "bad_recovery", mfaToken: MFAToken).start { result in
                        expect(result).to(haveAuthenticationError(code: "invalid_grant", description: "Invalid recovery_code."))
                        done()
                    }
                }
            }

            it("should fail login with invalid mfa") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(withRecoveryCode: RecoveryCode, mfaToken: "bad_token").start { result in
                        expect(result).to(haveAuthenticationError(code: "invalid_grant", description: "Malformed mfa_token"))
                        done()
                    }
                }
            }
        }

        // MARK:- MFA Challenge

        describe("MFA challenge") {

            beforeEach {
                stub(condition: isMultifactorChallenge(Domain) && hasAtLeast([
                    "mfa_token": MFAToken,
                    "client_id": ClientId,
                    "challenge_type": "oob otp",
                    "oob_channel": OOBChannel,
                    "authenticator_id": AuthenticatorId
                    ])) { _ in return multifactorChallengeResponse(challengeType: "oob") }.name = "MFA Challenge"
            }

            it("should request without filters") {
                waitUntil(timeout: Timeout) { done in
                    auth.multifactorChallenge(mfaToken: MFAToken, types: ChallengeTypes, channel: OOBChannel, authenticatorId: AuthenticatorId).start { result in
                        expect(result).to(beSuccessful())
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

        // MARK:- Modify and Create Requests

        describe("Requests create and update") {

            let refreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")

            it("should contain payload") {
                let request = auth.renew(withRefreshToken: refreshToken)

                expect(request.payload["refresh_token"] as? String) == refreshToken
                expect(request.payload["grant_type"] as? String) == "refresh_token"
                expect(request.payload["client_id"] as? String) == ClientId
            }

            it("add and override parameters") {
                let request = auth.renew(withRefreshToken: refreshToken)
                    .parameters([
                        "client_id": "new Client ID",
                        "phone": Phone
                    ])

                expect(request.payload["refresh_token"] as? String) == refreshToken
                expect(request.payload["grant_type"] as? String) == "refresh_token"
                expect(request.payload["client_id"] as? String) == "new Client ID"
                expect(request.payload["phone"] as? String) == Phone
            }

            it("copy contains same informations") {
                let baseRequest = auth.renew(withRefreshToken: refreshToken)
                let modifiedRequest = baseRequest.parameters([:])

                expect(baseRequest.session) == modifiedRequest.session
                expect(baseRequest.url) == modifiedRequest.url
                expect(baseRequest.method) == modifiedRequest.method
                expect(baseRequest.payload as? [String: String]) == modifiedRequest.payload as? [String: String]
                expect(baseRequest.headers) == modifiedRequest.headers
            }
        }

        // MARK:- Token Exchange

        describe("native social token exchange") {
            
            context("apple") {
                beforeEach {
                    stub(condition: isToken(Domain) && hasAllOf([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": "VALIDCODE",
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                        "scope": "openid profile offline_access",
                        "client_id": ClientId
                        ])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success"
                    
                    stub(condition: isToken(Domain) && hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": "VALIDCODE",
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                        "scope": "openid email"
                        ])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success with custom scope"
                    
                    stub(condition: isToken(Domain) && hasAtLeast([
                    "grant_type": TokenExchangeGrantType,
                    "subject_token": "VALIDCODE",
                    "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                    "scope": "openid email",
                    "audience": "https://myapi.com/api"
                    ])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success with custom scope and audience"
                    
                    stub(condition: isToken(Domain) && hasAtLeast([
                    "grant_type": TokenExchangeGrantType,
                    "subject_token": "VALIDNAMECODE",
                    "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code"]) &&
                    (hasAtLeast(["user_profile": "{\"name\":{\"lastName\":\"Smith\",\"firstName\":\"John\"}}" ]) || hasAtLeast(["user_profile": "{\"name\":{\"firstName\":\"John\",\"lastName\":\"Smith\"}}" ]))
                    ) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success with user profile"
                    
                    stub(condition: isToken(Domain) && hasAtLeast([
                    "grant_type": TokenExchangeGrantType,
                    "subject_token": "VALIDPARTIALNAMECODE",
                    "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                    "user_profile": "{\"name\":{\"firstName\":\"John\"}}"
                    ])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success with partial user profile"
                    
                    stub(condition: isToken(Domain) && hasAtLeast([
                    "grant_type": TokenExchangeGrantType,
                    "subject_token": "VALIDMISSINGNAMECODE",
                    "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code"]) &&
                    hasNoneOf(["user_profile"])
                    ) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success with missing user profile"

                    stub(condition: isToken(Domain) && hasAtLeast([
                    "grant_type": TokenExchangeGrantType,
                    "subject_token": "VALIDNAMEANDPROFILECODE",
                    "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code"]) &&
                    (hasAtLeast(["user_profile": "{\"name\":{\"firstName\":\"John\"},\"user_metadata\":{\"custom_key\":\"custom_value\"}}"]) || hasAtLeast(["user_profile": "{\"user_metadata\":{\"custom_key\":\"custom_value\"},\"name\":{\"firstName\":\"John\"}}"]))
                    ) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success with user profile"
                }

                it("should exchange apple auth code for credentials") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(appleAuthorizationCode: "VALIDCODE")
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                        }
                    }
                    
                    waitUntil(timeout: Timeout) { done in
                        auth.tokenExchange(withAppleAuthorizationCode: "VALIDCODE")
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                        }
                    }
                }
                
                it("should exchange apple auth code and fail") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(appleAuthorizationCode: "INVALIDCODE")
                            .start { result in
                                expect(result).toNot(haveCredentials())
                                done()
                        }
                    }
                    
                    waitUntil(timeout: Timeout) { done in
                        auth.tokenExchange(withAppleAuthorizationCode: "INVALIDCODE")
                            .start { result in
                                expect(result).toNot(haveCredentials())
                                done()
                        }
                    }
                }
                
                it("should exchange apple auth code for credentials with custom scope") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(appleAuthorizationCode: "VALIDCODE", scope: "openid email")
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                        }
                    }
                    
                    waitUntil(timeout: Timeout) { done in
                        auth.tokenExchange(withAppleAuthorizationCode: "VALIDCODE", scope: "openid email")
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                        }
                    }
                }
                
                it("should exchange apple auth code for credentials with custom scope and audience") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(appleAuthorizationCode: "VALIDCODE", scope: "openid email", audience: "https://myapi.com/api")
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                        }
                    }
                    
                    waitUntil(timeout: Timeout) { done in
                        auth.tokenExchange(withAppleAuthorizationCode: "VALIDCODE", scope: "openid email", audience: "https://myapi.com/api")
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                        }
                    }
                }
                
                it("should exchange apple auth code for credentials with fullName") {
                    var fullName = PersonNameComponents()
                    fullName.givenName = "John"
                    fullName.familyName = "Smith"
                    fullName.middleName = "Ignored"

                    waitUntil(timeout: Timeout) { done in
                        auth.tokenExchange(withAppleAuthorizationCode: "VALIDNAMECODE",
                                           fullName: fullName)
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                        }
                    }
                }
                
                it("should exchange apple auth code for credentials with partial fullName") {
                    var fullName = PersonNameComponents()
                    fullName.givenName = "John"
                    fullName.familyName = nil
                    fullName.middleName = "Ignored"
                    
                    waitUntil(timeout: Timeout) { done in
                        auth.tokenExchange(withAppleAuthorizationCode: "VALIDPARTIALNAMECODE",
                                           fullName: fullName)
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                        }
                    }
                }
                
                it("should exchange apple auth code for credentials with missing fullName") {
                    var fullName = PersonNameComponents()
                    fullName.givenName = nil
                    fullName.familyName = nil
                    fullName.middleName = nil
                    
                    waitUntil(timeout: Timeout) { done in
                        auth.tokenExchange(withAppleAuthorizationCode: "VALIDMISSINGNAMECODE",
                                           fullName: fullName)
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                        }
                    }
                }

                it("should exchange apple auth code for credentials with fullName and profile") {
                    var fullName = PersonNameComponents()
                    fullName.givenName = "John"
                    fullName.familyName = nil
                    fullName.middleName = "Ignored"
                    let profile = ["user_metadata": ["custom_key": "custom_value"]]

                    waitUntil(timeout: Timeout) { done in
                        auth.login(appleAuthorizationCode: "VALIDNAMEANDPROFILECODE",
                                   fullName: fullName,
                                   profile: profile)
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                        }
                    }
                }
            }

            context("facebook") {
                let sessionAccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
                let profile = ["name": "John Smith"]

                it("should exchage the session access token and profile data for credentials") {
                    stub(condition: isToken(Domain) && hasAllOf([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": sessionAccessToken,
                        "subject_token_type": "http://auth0.com/oauth/token-type/facebook-info-session-access-token",
                        "scope": "openid profile offline_access",
                        "user_profile": "{\"name\":\"John Smith\"}",
                        "client_id": ClientId
                    ])) { _ in
                        return authResponse(accessToken: AccessToken, idToken: IdToken)
                    }

                    waitUntil(timeout: Timeout) { done in
                        auth.login(facebookSessionAccessToken: sessionAccessToken, profile: profile)
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                done()
                        }
                    }
                }

                it("should include profile data") {
                    stub(condition: isToken(Domain) &&
                        (hasAtLeast(["user_profile": "{\"name\":\"John Smith\",\"email\":\"john@smith.com\"}" ]) ||
                        hasAtLeast(["user_profile": "{\"email\":\"john@smith.com\",\"name\":\"John Smith\"}" ]))) { _ in
                            return authResponse(accessToken: AccessToken, idToken: IdToken)
                    }

                    waitUntil(timeout: Timeout) { done in
                        auth.login(facebookSessionAccessToken: sessionAccessToken,
                                           profile: ["name": "John Smith", "email": "john@smith.com"])
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                done()
                        }
                    }
                }

                it("should include audience if it is not nil") {
                    stub(condition: isToken(Domain) && hasAtLeast(["audience": "https://myapi.com/api"])) { _ in
                        return authResponse(accessToken: AccessToken, idToken: IdToken)
                    }

                    waitUntil(timeout: Timeout) { done in
                        auth.login(facebookSessionAccessToken: sessionAccessToken,
                                           profile: profile,
                                           audience: "https://myapi.com/api")
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                done()
                        }
                    }
                }

                it("should not include audience if it is nil") {
                    stub(condition: isToken(Domain) && hasNoneOf(["audience"])) { _ in
                        return authResponse(accessToken: AccessToken, idToken: IdToken)
                    }

                    waitUntil(timeout: Timeout) { done in
                        auth.login(facebookSessionAccessToken: sessionAccessToken,
                                           profile: profile,
                                           audience: nil)
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                done()
                        }
                    }
                }

                it("should include scope if it is not nil") {
                    stub(condition: isToken(Domain) && hasAtLeast(["scope": "openid email"])) { _ in
                        return authResponse(accessToken: AccessToken, idToken: IdToken)
                    }

                    waitUntil(timeout: Timeout) { done in
                        auth.login(facebookSessionAccessToken: sessionAccessToken,
                                           profile: profile,
                                           scope: "openid email")
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                done()
                        }
                    }
                }

                it("should not include scope if it is nil") {
                    stub(condition: isToken(Domain) && hasNoneOf(["scope"])) { _ in
                        return authResponse(accessToken: AccessToken, idToken: IdToken)
                    }

                    waitUntil(timeout: Timeout) { done in
                        auth.login(facebookSessionAccessToken: sessionAccessToken,
                                           profile: profile,
                                           scope: nil)
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                done()
                        }
                    }
                }
            }

        }

        describe("revoke refresh token") {

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

            it("should send additional parameters") {
                let state = UUID().uuidString
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid", "audience" : "https://myapi.com/api", "realm" : "customconnection", "state": state])) { _ in return authResponse(accessToken: AccessToken) }.name = "Custom Parameter Auth"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realm: "customconnection", audience: "https://myapi.com/api", scope: "openid", parameters: ["state": state]).start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

        }
        
        // MARK:- password grant type
        describe("authenticating with credentials in a default directory") {
            
            it("should receive token with username and password") {
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password"
                
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword).start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }
            
            it("should fail to return token") {
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password"
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: "invalid").start { result in
                        expect(result).toNot(haveCredentials())
                        done()
                    }
                }
            }
            
            it("should specify scope in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom Scope"
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword,  scope: "openid").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }
            
            it("should specify audience in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "audience" : "https://myapi.com/api"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom Audience"
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword, audience: "https://myapi.com/api").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }
            
            it("should specify audience and scope in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid", "audience" : "https://myapi.com/api"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom Scope and audience"
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword, audience: "https://myapi.com/api", scope: "openid").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }
            
            it("should send additional parameters") {
                let state = UUID().uuidString
                stub(condition: isToken(Domain) && hasAtLeast(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid", "audience" : "https://myapi.com/api", "state": state])) { _ in return authResponse(accessToken: AccessToken) }.name = "Custom Parameter Auth"
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword, audience: "https://myapi.com/api", scope: "openid", parameters: ["state": state]).start { result in
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
            
            context("root attributes") {
                
                it("should send root attributes") {
                    let attributes = ["family_name": "Doe",
                                      "nickname" : "Johnny"]
                    stub(condition: isSignUp(Domain) && hasAtLeast(attributes)) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/root attributes"
                    waitUntil(timeout: Timeout) { done in
                        auth.createUser(email: SupportAtAuth0, password: ValidPassword, connection: ConnectionName, rootAttributes: attributes).start { result in
                            expect(result).to(haveCreatedUser(SupportAtAuth0))
                            done()
                        }
                    }
                }
                
                it("should send root attributes but not overwrite existing email") {
                    let attributes = ["family_name": "Doe",
                                      "nickname" : "Johnny",
                                      "email" : "root@email.com"]
                    stub(condition: isSignUp(Domain) && !hasAtLeast(attributes)) { _ in return createdUser(email: SupportAtAuth0) }.name = "User w/root attributes"
                    waitUntil(timeout: Timeout) { done in
                        auth.createUser(email: SupportAtAuth0, password: ValidPassword, connection: ConnectionName, rootAttributes: attributes).start { result in
                            expect(result).to(haveCreatedUser(SupportAtAuth0))
                            done()
                        }
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
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should start with email") {
                stub(condition: isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "custom_email", "client_id": ClientId, "send": "link_ios"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless custom"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .iOSLink, connection: "custom_email").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should start with email and authParameters for web link") {
                let params = ["scope": "openid"]
                stub(condition: isPasswordless(Domain) && hasAtLeast(["email": SupportAtAuth0]) && hasObjectAttribute("authParams", value: params)) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless web link with parameters"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .WebLink, parameters: params).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should not send params if type is not web link") {
                let params = ["scope": "openid"]
                stub(condition: isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "email", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless without parameters"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .Code, parameters: params).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should not add params attr if they are empty") {
                stub(condition: isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "email", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless without parameters"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .Code, parameters: [:]).start { result in
                        expect(result).to(beSuccessful())
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
            
            context("passwordless login") {
                
                let emailRealm = "email"
                
                it("should login with email code") {
                    stub(condition: isToken(Domain) && hasAtLeast(["username": SupportAtAuth0, "otp": OTP, "realm": emailRealm, "grant_type": PasswordlessGrantType, "client_id": ClientId])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP).start { result in
                            expect(result).to(haveCredentials(AccessToken))
                            done()
                        }
                    }
                }
                
                it("should include audience if it is not nil") {
                    stub(condition: isToken(Domain) && hasAtLeast(["audience": "https://myapi.com/api"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, audience: "https://myapi.com/api", scope: nil, parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include audience if it is nil") {
                    stub(condition: isToken(Domain) && hasNoneOf(["audience"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, audience: nil, scope: nil, parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include audience by default") {
                    stub(condition: isToken(Domain) && hasNoneOf(["audience"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, scope: nil, parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should include scope if it is not nil") {
                    stub(condition: isToken(Domain) && hasAtLeast(["scope": "openid profile email"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, audience: nil, scope: "openid profile email", parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include scope if it is nil") {
                    stub(condition: isToken(Domain) && hasNoneOf(["scope"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, audience: nil, scope: nil, parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should use 'openid' as the default scope") {
                    stub(condition: isToken(Domain) && hasAtLeast(["scope": "openid"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, audience: nil, parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should include extra parameters") {
                    stub(condition: isToken(Domain) && hasAtLeast(["foo": "bar"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, audience: nil, scope: nil, parameters: ["foo": "bar"]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include extra parameters if they're empty") {
                    stub(condition: isToken(Domain) && hasAllOf(["username": SupportAtAuth0, "otp": OTP, "realm": emailRealm, "grant_type": PasswordlessGrantType, "client_id": ClientId])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, audience: nil, scope: nil, parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include extra parameters by default") {
                    stub(condition: isToken(Domain) && hasAllOf(["username": SupportAtAuth0, "otp": OTP, "realm": emailRealm, "grant_type": PasswordlessGrantType, "client_id": ClientId])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, audience: nil, scope: nil).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
            }
        }

        describe("passwordless sms") {

            it("should start with sms with default values") {
                stub(condition: isPasswordless(Domain) && hasAllOf(["phone_number": Phone, "connection": "sms", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "sms passwordless"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(phoneNumber: Phone).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should start with sms") {
                stub(condition: isPasswordless(Domain) && hasAllOf(["phone_number": Phone, "connection": "custom_sms", "client_id": ClientId, "send": "link_ios"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "sms passwordless custom"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(phoneNumber: Phone, type: .iOSLink, connection: "custom_sms").start { result in
                        expect(result).to(beSuccessful())
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
            
            context("passwordless login") {
                
                let smsRealm = "sms"
                
                it("should login with sms code") {
                    stub(condition: isToken(Domain) && hasAtLeast(["username": Phone, "otp": OTP, "realm": smsRealm, "grant_type": PasswordlessGrantType, "client_id": ClientId])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP).start { result in
                            expect(result).to(haveCredentials(AccessToken))
                            done()
                        }
                    }
                }
                
                it("should include audience if it is not nil") {
                    stub(condition: isToken(Domain) && hasAtLeast(["audience": "https://myapi.com/api"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, audience: "https://myapi.com/api", scope: nil, parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include audience if it is nil") {
                    stub(condition: isToken(Domain) && hasNoneOf(["audience"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, audience: nil, scope: nil, parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include audience by default") {
                    stub(condition: isToken(Domain) && hasNoneOf(["audience"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, scope: nil, parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should include scope if it is not nil") {
                    stub(condition: isToken(Domain) && hasAtLeast(["scope": "openid profile email"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, audience: nil, scope: "openid profile email", parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include scope if it is nil") {
                    stub(condition: isToken(Domain) && hasNoneOf(["scope"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, audience: nil, scope: nil, parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should use 'openid' as the default scope") {
                    stub(condition: isToken(Domain) && hasAtLeast(["scope": "openid"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, audience: nil, parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should include extra parameters") {
                    stub(condition: isToken(Domain) && hasAtLeast(["foo": "bar"])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, audience: nil, scope: nil, parameters: ["foo": "bar"]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include extra parameters if they're empty") {
                    stub(condition: isToken(Domain) && hasAllOf(["username": Phone, "otp": OTP, "realm": smsRealm, "grant_type": PasswordlessGrantType, "client_id": ClientId])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, audience: nil, scope: nil, parameters: [:]).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include extra parameters by default") {
                    stub(condition: isToken(Domain) && hasAllOf(["username": Phone, "otp": OTP, "realm": smsRealm, "grant_type": PasswordlessGrantType, "client_id": ClientId])) { _ in
                        return authResponse(accessToken: AccessToken)
                    }
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, audience: nil, scope: nil).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
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
                stub(condition: isUserInfo(Domain) && hasBearerToken(AccessToken)) { _ in return userInfo(withProfile: basicProfile()) }.name = "user info"
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

        describe("user information OIDC conformant") {

            it("should return user information") {
                stub(condition: isUserInfo(Domain) && hasBearerToken(AccessToken)) { _ in return userInfo(withProfile: basicProfileOIDC()) }.name = "user info oidc"
                waitUntil(timeout: Timeout) { done in
                    auth.userInfo(withAccessToken: AccessToken).start { result in
                        expect(result).to(haveProfileOIDC(Sub))
                        done()
                    }
                }
            }

            it("should report failure to get user info") {
                stub(condition: isUserInfo(Domain)) { _ in return authFailure(error: "invalid_token", description: "the token is invalid") }.name = "token info failed"
                waitUntil(timeout: Timeout) { done in
                    auth.userInfo(withAccessToken: AccessToken).start { result in
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
                stub(condition: isOAuthAccessToken(Domain) && hasAtLeast(["access_token": InvalidFacebookToken])) { _ in return HTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil)) }.name = "Not Authorized"
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
        
        describe("jwks") {
            context("successful fetch") {
                it("should fetch the jwks") {
                    stub(condition: isJWKSPath(Domain)) { _ in jwksResponse() }
                    
                    waitUntil { done in
                        auth.jwks().start {
                            expect($0).to(haveJWKS())
                            done()
                        }
                    }
                }
            }
            
            context("unsuccesful fetch") {
                it("should produce an error") {
                    stub(condition: isJWKSPath(Domain)) { _ in jwksErrorResponse() }
                    
                    waitUntil { done in
                        auth.jwks().start {
                            expect($0).to(beFailure())
                            done()
                        }
                    }
                }
            }
        }

#if WEB_AUTH_PLATFORM
        describe("spawn WebAuth instance") {

            it("should return a WebAuth instance with matching credentials") {
                let webAuth = auth.webAuth(withConnection: "facebook")
                expect(webAuth.clientId) == auth.clientId
                expect(webAuth.url) == auth.url
            }

            it("should return a WebAuth instance with matching telemetry") {
                let webAuth = auth.webAuth(withConnection: "facebook") as! Auth0WebAuth
                expect(webAuth.telemetry.info) == auth.telemetry.info
            }

            it("should return a WebAuth instance with matching connection") {
                let webAuth = auth.webAuth(withConnection: "facebook") as! Auth0WebAuth
                expect(webAuth.parameters["connection"]) == "facebook"
            }
        }
#endif

    }
}
