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
private let DomainURL = URL(string: "https://\(Domain)")!

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

        let auth: Authentication = Auth0Authentication(clientId: ClientId, url: DomainURL)

        beforeEach {
            stub(condition: isHost(Domain)) { _ in catchAllResponse() }.name = "YOU SHALL NOT PASS!"
        }

        afterEach {
            HTTPStubs.removeAllStubs()
        }

        describe("init") {

            it("should init with client id & url") {
                let authentication = Auth0Authentication(clientId: ClientId, url: DomainURL)
                expect(authentication.clientId) == ClientId
                expect(authentication.url) == DomainURL
            }

            it("should init with client id, url & session") {
                let session = URLSession(configuration: URLSession.shared.configuration)
                let authentication = Auth0Authentication(clientId: ClientId, url: DomainURL, session: session)
                expect(authentication.session).to(be(session))
            }

            it("should init with client id, url & telemetry") {
                let telemetryInfo = "info"
                var telemetry = Telemetry()
                telemetry.info = telemetryInfo
                let authentication = Auth0Authentication(clientId: ClientId, url: DomainURL, telemetry: telemetry)
                expect(authentication.telemetry.info) == telemetryInfo
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
                stub(condition: isToken(Domain) && hasAtLeast(["oob_code": OOB, "mfa_token": MFAToken])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                stub(condition: isToken(Domain) && hasAtLeast(["oob_code": OOB, "mfa_token": MFAToken, "binding_code": BindingCode])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "OpenID Auth"
                stub(condition: isToken(Domain) && hasAtLeast(["oob_code": "bad_oob", "mfa_token": MFAToken])) { _ in return authFailure(code: "invalid_grant", description: "Invalid oob_code.") }.name = "invalid oob_code"
                stub(condition: isToken(Domain) && hasAtLeast(["oob_code": OOB, "mfa_token": "bad_token"])) { _ in return authFailure(code: "invalid_grant", description: "Malformed mfa_token") }.name = "invalid mfa_token"
            }

            it("should login with oob code and mfa tokens with default parameters") {
                waitUntil(timeout: Timeout) { done in
                    auth.login(withOOBCode: OOB, mfaToken: MFAToken).start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should login with oob code and mfa tokens with binding code") {
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
                    "client_id": ClientId
                ])) { _ in return multifactorChallengeResponse(challengeType: "oob") }.name = "MFA Challenge"
                stub(condition: isMultifactorChallenge(Domain) && hasAtLeast([
                    "mfa_token": MFAToken,
                    "client_id": ClientId,
                    "challenge_type": "oob otp"
                ])) { _ in return multifactorChallengeResponse(challengeType: "oob") }.name = "MFA Challenge"
                stub(condition: isMultifactorChallenge(Domain) && hasAtLeast([
                    "mfa_token": MFAToken,
                    "client_id": ClientId,
                    "authenticator_id": AuthenticatorId
                ])) { _ in return multifactorChallengeResponse(challengeType: "oob") }.name = "MFA Challenge"
                stub(condition: isMultifactorChallenge(Domain) && hasAtLeast([
                    "mfa_token": MFAToken,
                    "client_id": ClientId,
                    "challenge_type": "oob otp",
                    "authenticator_id": AuthenticatorId
                ])) { _ in return multifactorChallengeResponse(challengeType: "oob") }.name = "MFA Challenge"
            }

            it("should request MFA challenge with default parameters") {
                waitUntil(timeout: Timeout) { done in
                    auth.multifactorChallenge(mfaToken: MFAToken).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should request MFA challenge with challenge types") {
                waitUntil(timeout: Timeout) { done in
                    auth.multifactorChallenge(mfaToken: MFAToken, types: ChallengeTypes).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should request MFA challenge with authenticator id") {
                waitUntil(timeout: Timeout) { done in
                    auth.multifactorChallenge(mfaToken: MFAToken, authenticatorId: AuthenticatorId).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should request MFA challenge with all parameters") {
                waitUntil(timeout: Timeout) { done in
                    auth.multifactorChallenge(mfaToken: MFAToken, types: ChallengeTypes, authenticatorId: AuthenticatorId).start { result in
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

            it("should fail to receive access token") {
                let invalidRefreshToken = "invalidtoken"

                stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": invalidRefreshToken])) { _ in
                    return authFailure(error: "", description: "")
                }.name = "refresh_token login"

                waitUntil(timeout: Timeout) { done in
                    auth.renew(withRefreshToken: invalidRefreshToken).start { result in
                        expect(result).toNot(haveCredentials())
                        done()
                    }
                }
            }

        }


        // MARK:- Token Exchange

        describe("native social token exchange") {
            
            let validCode = "VALIDCODE"
            let validNameCode = "VALIDNAMECODE"
            let validPartialNameCode = "VALIDPARTIALNAMECODE"
            let validMissingNameCode = "VALIDMISSINGNAMECODE"
            let validNameAndProfileCode = "VALIDNAMEANDPROFILECODE"
            let invalidCode = "INVALIDCODE"
            
            context("apple") {
                beforeEach {
                    stub(condition: isToken(Domain) && hasAllOf([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": validCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                        "scope": defaultScope,
                        "client_id": ClientId
                    ])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success"
                    
                    stub(condition: isToken(Domain) && hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": validCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                        "scope": "openid email"
                    ])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success with custom scope"
                    
                    stub(condition: isToken(Domain) && hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": validCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                        "scope": "openid email",
                        "audience": "https://myapi.com/api"
                    ])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success with custom scope and audience"
                    
                    stub(condition: isToken(Domain) && hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": validNameCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code"]) &&
                        (hasAtLeast(["user_profile": "{\"name\":{\"lastName\":\"Smith\",\"firstName\":\"John\"}}" ]) || hasAtLeast(["user_profile": "{\"name\":{\"firstName\":\"John\",\"lastName\":\"Smith\"}}" ]))
                    ) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success with user profile"
                    
                    stub(condition: isToken(Domain) && hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": validPartialNameCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                        "user_profile": "{\"name\":{\"firstName\":\"John\"}}"
                    ])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success with partial user profile"
                    
                    stub(condition: isToken(Domain) && hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": validMissingNameCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code"]) &&
                        hasNoneOf(["user_profile"])
                    ) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success with missing user profile"

                    stub(condition: isToken(Domain) && hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": validNameAndProfileCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code"]) &&
                        (hasAtLeast(["user_profile": "{\"name\":{\"firstName\":\"John\"},\"user_metadata\":{\"custom_key\":\"custom_value\"}}"]) || hasAtLeast(["user_profile": "{\"user_metadata\":{\"custom_key\":\"custom_value\"},\"name\":{\"firstName\":\"John\"}}"]))
                    ) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Token Exchange Apple Success with user profile"
                    
                    stub(condition: isToken(Domain) && hasAllOf([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": invalidCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                        "scope": defaultScope,
                        "client_id": ClientId
                    ])) { _ in return authFailure(error: "", description: "") }.name = "Token Exchange Apple Failure"
                }

                it("should exchange apple auth code for credentials") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(appleAuthorizationCode: validCode)
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                        }
                    }

                }
                
                it("should exchange apple auth code and fail") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(appleAuthorizationCode: invalidCode)
                            .start { result in
                                expect(result).toNot(haveCredentials())
                                done()
                        }
                    }

                }
                
                it("should exchange apple auth code for credentials with custom scope") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(appleAuthorizationCode: validCode, scope: "openid email")
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                        }
                    }

                }
                
                it("should exchange apple auth code for credentials with custom scope and audience") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(appleAuthorizationCode: validCode, audience: "https://myapi.com/api", scope: "openid email")
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
                        auth.login(appleAuthorizationCode: validNameCode, fullName: fullName)
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
                        auth.login(appleAuthorizationCode: validPartialNameCode, fullName: fullName)
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
                        auth.login(appleAuthorizationCode: validMissingNameCode, fullName: fullName)
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
                        auth.login(appleAuthorizationCode: validNameAndProfileCode,
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
                        "scope": defaultScope,
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

            it("should fail to revoke token") {
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

        // MARK:- password-realm grant type
        describe("authenticating with credentials and a realm/connection") {

            it("should receive token with username and password") {
                stub(condition: isToken(Domain) && hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "realm": "myrealm"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "myrealm").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should fail to return token") {
                stub(condition: isToken(Domain) && hasAtLeast(["username": SupportAtAuth0, "password": InvalidPassword, "realm": "myrealm"])) { _ in return authFailure(error: "", description: "") }.name = "Grant Password"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: InvalidPassword, realmOrConnection: "myrealm").start { result in
                        expect(result).toNot(haveCredentials())
                        done()
                    }
                }
            }

            it("should specify scope in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "scope": "openid", "realm": "myrealm"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom Scope"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "myrealm", scope: "openid").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should specify audience in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "audience" : "https://myapi.com/api", "realm": "myrealm"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom Scope and audience"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "myrealm", audience: "https://myapi.com/api").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should specify audience and scope in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "scope": "openid", "audience" : "https://myapi.com/api", "realm": "myrealm"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom Scope and audience"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "myrealm", audience: "https://myapi.com/api", scope: "openid").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            it("should specify audience, scope and realm/connection in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "scope": "openid", "audience" : "https://myapi.com/api", "realm" : "customconnection"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom audience, scope and realm"
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "customconnection", audience: "https://myapi.com/api", scope: "openid").start { result in
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
                stub(condition: isToken(Domain) && hasAtLeast(["username": SupportAtAuth0, "password": InvalidPassword])) { _ in return authFailure(error: "", description: "") }.name = "Grant Password"
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: InvalidPassword).start { result in
                        expect(result).toNot(haveCredentials())
                        done()
                    }
                }
            }
            
            it("should specify scope in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom Scope"
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword,  scope: "openid").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }
            
            it("should specify audience in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "audience" : "https://myapi.com/api"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom Audience"
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword, audience: "https://myapi.com/api").start { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }
            
            it("should specify audience and scope in request") {
                stub(condition: isToken(Domain) && hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "scope": "openid", "audience" : "https://myapi.com/api"])) { _ in return authResponse(accessToken: AccessToken) }.name = "Grant Password Custom Scope and audience"
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword, audience: "https://myapi.com/api", scope: "openid").start { result in
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
                    auth.signup(email: SupportAtAuth0, password: ValidPassword, connection: ConnectionName).start { result in
                        expect(result).to(haveCreatedUser(SupportAtAuth0))
                        done()
                    }
                }
            }

            it("should create a user with email, username & password") {
                waitUntil(timeout: Timeout) { done in
                    auth.signup(email: SupportAtAuth0, username: Support, password: ValidPassword, connection: ConnectionName).start { result in
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
                    auth.signup(email: SupportAtAuth0, password: password, connection: ConnectionName).start { result in
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
                    auth.signup(email: email, password: ValidPassword, connection: ConnectionName, userMetadata: metadata).start { result in
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
                        auth.signup(email: SupportAtAuth0, password: ValidPassword, connection: ConnectionName, rootAttributes: attributes).start { result in
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
                        auth.signup(email: SupportAtAuth0, password: ValidPassword, connection: ConnectionName, rootAttributes: attributes).start { result in
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

            it("should fail to reset password") {
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
                    auth.startPasswordless(email: SupportAtAuth0, type: .webLink, parameters: params).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should not send params if type is not web link") {
                let params = ["scope": "openid"]
                stub(condition: isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "email", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless without parameters"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .code, parameters: params).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should not add params attr if they are empty") {
                stub(condition: isPasswordless(Domain) && hasAllOf(["email": SupportAtAuth0, "connection": "email", "client_id": ClientId, "send": "code"])) { _ in return passwordless(SupportAtAuth0, verified: true) }.name = "email passwordless without parameters"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .code, parameters: [:]).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should fail to start") {
                stub(condition: isPasswordless(Domain)) { _ in return authFailure(error: "error", description: "description") }.name = "failed passwordless start"
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0).start { result in
                        expect(result).to(haveAuthenticationError(code: "error", description: "description"))
                        done()
                    }
                }
            }
            
            context("passwordless login") {
                
                it("should login with email code") {
                    stub(condition: isToken(Domain) && hasAtLeast(["username": SupportAtAuth0, "otp": OTP, "realm": "email", "scope": defaultScope, "grant_type": PasswordlessGrantType, "client_id": ClientId])) { _ in
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
                        auth.login(email: SupportAtAuth0, code: OTP, audience: "https://myapi.com/api").start { result in
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
                        auth.login(email: SupportAtAuth0, code: OTP, audience: nil).start { result in
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
                        auth.login(email: SupportAtAuth0, code: OTP).start { result in
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

            it("should fail to start") {
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
                    stub(condition: isToken(Domain) && hasAtLeast(["username": Phone, "otp": OTP, "realm": smsRealm, "scope": defaultScope, "grant_type": PasswordlessGrantType, "client_id": ClientId])) { _ in
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
                        auth.login(phoneNumber: Phone, code: OTP, audience: "https://myapi.com/api").start { result in
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
                        auth.login(phoneNumber: Phone, code: OTP, audience: nil).start { result in
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
                        auth.login(phoneNumber: Phone, code: OTP).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

            }
        }

        describe("user information") {

            it("should return user information") {
                stub(condition: isUserInfo(Domain) && hasBearerToken(AccessToken)) { _ in return apiSuccessResponse(json: basicProfile()) }.name = "user info"
                waitUntil(timeout: Timeout) { done in
                    auth.userInfo(withAccessToken: AccessToken).start { result in
                        expect(result).to(haveProfile(Sub))
                        done()
                    }
                }
            }

            it("should fail to get user info") {
                stub(condition: isUserInfo(Domain)) { _ in return authFailure(error: "invalid_token", description: "the token is invalid") }.name = "token info failed"
                waitUntil(timeout: Timeout) { done in
                    auth.userInfo(withAccessToken: AccessToken).start { result in
                        expect(result).to(haveAuthenticationError(code: "invalid_token", description: "the token is invalid"))
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
                    auth.codeExchange(withCode: code, codeVerifier: codeVerifier, redirectURI: redirectURI).start { result in
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
                    auth.codeExchange(withCode: invalidCode, codeVerifier: codeVerifier, redirectURI: redirectURI).start { result in
                        expect(result).to(haveAuthenticationError(code: code, description: description))
                        done()
                    }
                }
            }

        }

        describe("jwks") {
            it("should fetch the jwks") {
                stub(condition: isJWKSPath(Domain)) { _ in jwksResponse() }
                
                waitUntil { done in
                    auth.jwks().start {
                        expect($0).to(haveJWKS())
                        done()
                    }
                }
            }

            it("should produce an error") {
                stub(condition: isJWKSPath(Domain)) { _ in apiFailureResponse() }
                
                waitUntil { done in
                    auth.jwks().start {
                        expect($0).to(beFailure())
                        done()
                    }
                }
            }
        }

    }
}
