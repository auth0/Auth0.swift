import Foundation
import Quick
import Nimble

#if PASSKEYS_PLATFORM
import AuthenticationServices
#endif

@testable import Auth0

private let ClientId = "CLIENT_ID"
private let Domain = "samples.auth0.com"
private let DomainURL = URL(string: "https://\(Domain)")!
private let Audience = "https://example.com/api"
private let Scope = "openid email offline_access"
private let ExpiresIn: TimeInterval = 3600
private let Email = "user@example.com"
private let Phone = "+144444444444"
private let Username = "user"
private let Name = "John Doe"
private let ValidPassword = "I.O.U. a password"
private let InvalidPassword = "InvalidPassword"
private let ConnectionName = "Username-Password-Authentication"
private let OrganizationId = "Organization"
private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let SessionTransferToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let FacebookToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let InvalidFacebookToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let Timeout: NimbleTimeInterval = .seconds(2)
private let PasswordlessGrantType = "http://auth0.com/oauth/grant-type/passwordless/otp"
private let TokenExchangeGrantType = "urn:ietf:params:oauth:grant-type:token-exchange"
private let PasskeysGrantType = "urn:okta:params:oauth:grant-type:webauthn"
private let SessionTransferTokenTokenType = "urn:auth0:params:oauth:token-type:session_transfer_token"

class AuthenticationSpec: QuickSpec {
    override class func spec() {
        
        let auth: Authentication = Auth0Authentication(clientId: ClientId, url: DomainURL)
        
        beforeEach {
            URLProtocol.registerClass(StubURLProtocol.self)
        }
        
        afterEach {
            NetworkStub.clearStubs()
            URLProtocol.unregisterClass(StubURLProtocol.self)
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
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["otp": OTP, "mfa_token": MFAToken])
                }, response:  authResponse(accessToken: AccessToken, idToken: IdToken))
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["otp": OTP, "mfa_token": "bad_token"])
                }, response: authFailure(code: "invalid_grant", description: "Malformed mfa_token"))
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["otp": "bad_otp", "mfa_token": MFAToken])
                }, response: authFailure(code: "invalid_grant", description: "Invalid otp_code."))
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
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["oob_code": OOB, "mfa_token": MFAToken])
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["oob_code": OOB, "mfa_token": MFAToken, "binding_code": BindingCode])
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["oob_code": "bad_oob", "mfa_token": MFAToken])
                }, response: authFailure(code: "invalid_grant", description: "Invalid oob_code."))
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["oob_code": OOB, "mfa_token": "bad_token"])
                }, response: authFailure(code: "invalid_grant", description: "Malformed mfa_token"))
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
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["recovery_code": RecoveryCode, "mfa_token": MFAToken]) }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["recovery_code": "bad_recovery", "mfa_token": MFAToken]) }, response: authFailure(code: "invalid_grant", description: "Invalid recovery_code."))
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["recovery_code": RecoveryCode, "mfa_token": "bad_token"]) }, response: authFailure(code: "invalid_grant", description: "Malformed mfa_token"))
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
                NetworkStub.addStub(condition: {
                    $0.isMultifactorChallenge(Domain) && $0.hasAtLeast([
                        "mfa_token": MFAToken,
                        "client_id": ClientId
                    ]) && $0.hasNoneOf(["challenge_type", "authenticator_id"])
                }, response: multifactorChallengeResponse(challengeType: "oob"))
                
                NetworkStub.addStub(condition: {
                    $0.isMultifactorChallenge(Domain) && $0.hasAtLeast([
                        "mfa_token": MFAToken,
                        "client_id": ClientId,
                        "challenge_type": "oob otp"
                    ])
                }, response: multifactorChallengeResponse(challengeType: "oob"))
                
                NetworkStub.addStub(condition: {
                    $0.isMultifactorChallenge(Domain) && $0.hasAtLeast([
                        "mfa_token": MFAToken,
                        "client_id": ClientId,
                        "authenticator_id": AuthenticatorId
                    ])
                }, response: multifactorChallengeResponse(challengeType: "oob"))
                
                NetworkStub.addStub(condition: {
                    $0.isMultifactorChallenge(Domain) && $0.hasAtLeast([
                        "mfa_token": MFAToken,
                        "client_id": ClientId,
                        "challenge_type": "oob otp",
                        "authenticator_id": AuthenticatorId
                    ])
                }, response: multifactorChallengeResponse(challengeType: "oob"))
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

        // MARK: - Passkeys

        #if PASSKEYS_PLATFORM
        if #available(iOS 16.6, macOS 13.5, visionOS 1.0, *) {
            struct MockLoginPasskey: LoginPasskey {
                var userID: Data!
                var credentialID: Data
                var attachment: ASAuthorizationPublicKeyCredentialAttachment = .platform
                var rawClientDataJSON: Data
                var rawAuthenticatorData: Data!
                var signature: Data!
            }

            let authSession = "y1PI7ue7QX85WMxoR6Qa-9INuqA3xxKLVoDOxBOD6yYQL1Fl-zgwjFtZIQfRORhY"
            let userId = "LcICuavHdO2zbcA8zRgnTRIkzPrruI_HQqe0J3RL0ou5VSrWhRybCQqyNMXWj1LDdxOzat6KVf9xpW3qLw5qjw"
            let credentialId = "mXTk10IfDhdxZnJltERtBRyNUkE"
            let credentialType = "public-key"
            let clientData = "eyJ0eXBlIjoid2ViYXV0aG4uY3JlYXRlIiwiY2hhbGxlbmdlIjoiTDRTYVN4eDh0cHFyU2NUX2hicFpYLTUwcW" +
            "ZLaDEyX294bVNVSUtTR0ZwTSIsIm9yaWdpbiI6Imh0dHBzOi8vbG9naW4ud2lkY2tldC5jb20ifQ-MN8A"
            let authenticatorData = "lDH4SiOEQFwNz4z4dy3yWLJ5CkueUJPzpqulBxP_X_8dAAAAAA"
            let signature = "MEUCIH6XVeR9aTIEQZJ1vRv96y2ndS4da75h9K41Gnt6ssd9AiEA0DHoeNMrPw8GBzYkagdQD6I4ySOGONSTWPV" +
            "YA0FAwII"
            let challengeString = "L4SaSxx8tpqrScT_hbpZX-50qfKh12_oxmSUIKSGFpM"
            let challengeData = challengeString.a0_decodeBase64URLSafe()!
            let authenticatorAttachment = "platform"

            let passkey = MockLoginPasskey(userID: userId.a0_decodeBase64URLSafe(),
                                           credentialID: credentialId.a0_decodeBase64URLSafe()!,
                                           rawClientDataJSON: clientData.a0_decodeBase64URLSafe()!,
                                           rawAuthenticatorData: authenticatorData.a0_decodeBase64URLSafe(),
                                           signature: signature.a0_decodeBase64URLSafe())
            let challenge = PasskeyLoginChallenge(authenticationSession: authSession,
                                                  relyingPartyId: Domain,
                                                  challengeData: challengeData)

            describe("login with passkey") {

                it("should login with passkey and default parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession,
                            "authn_response": [
                                "id": credentialId,
                                "rawId": credentialId,
                                "authenticatorAttachment": authenticatorAttachment,
                                "type": credentialType,
                                "response": [
                                    "userHandle": userId,
                                    "authenticatorData": authenticatorData,
                                    "clientDataJSON": clientData,
                                    "signature": signature
                                ]
                            ]
                        ])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: passkey, challenge: challenge)
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                done()
                            }
                    }
                }

                it("should login with passkey and all parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "realm": ConnectionName,
                            "audience": Audience,
                            "scope": Scope,
                            "organization": OrganizationId,
                            "auth_session": authSession,
                            "authn_response": [
                                "id": credentialId,
                                "rawId": credentialId,
                                "authenticatorAttachment": authenticatorAttachment,
                                "type": credentialType,
                                "response": [
                                    "userHandle": userId,
                                    "authenticatorData": authenticatorData,
                                    "clientDataJSON": clientData,
                                    "signature": signature
                                ]
                            ]
                        ])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken, refreshToken: RefreshToken))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: passkey,
                                   challenge: challenge,
                                   connection: ConnectionName,
                                   audience: Audience,
                                   scope: Scope,
                                   organization: OrganizationId)
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken, RefreshToken))
                                done()
                            }
                    }

                }

            }

            describe("passkey login challenge") {

                it("should request passkey login challenge with default parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeyLoginChallenge(Domain) && $0.hasAtLeast(["client_id": ClientId])
                    }, response: passkeyLoginChallengeResponse())

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeyLoginChallenge()
                            .start { result in
                                expect(result).to(beSuccessful())
                                done()
                            }
                    }
                }

                it("should request passkey login challenge with all parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeyLoginChallenge(Domain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "realm": ConnectionName,
                            "organization": OrganizationId
                        ])
                    }, response: passkeyLoginChallengeResponse())

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeyLoginChallenge(connection: ConnectionName,
                            organization: OrganizationId)
                            .start { result in
                                expect(result).to(beSuccessful())
                                done()
                            }
                    }
                }

            }

            struct MockSignupPasskey: SignupPasskey {
                let credentialID: Data
                let attachment: ASAuthorizationPublicKeyCredentialAttachment = .platform
                let rawAttestationObject: Data?
                let rawClientDataJSON: Data
            }

            let attestationObject = "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YViYlDH4SiOEQFwNz4z4dy3yWLJ5CkueUJPzpqulBxP" +
            "_X_9dAAAAAPv8MAcVTk7MjAtuAgVX170AFJl05NdCHw4XcWZyZbREbQUcjVJBpQECAyYgASFYII53hB2t9eUcxo6B4PdeSaWKQCb-sQ" +
            "RSSJIsSl1iXE6VIlgg9SFUiFdAPMrCwC-RQaNKVwNrMFzsRkiu0Djz-GPjDfA"

            let signupPasskey = MockSignupPasskey(credentialID: credentialId.a0_decodeBase64URLSafe()!,
                                                  rawAttestationObject: attestationObject.a0_decodeBase64URLSafe(),
                                                  rawClientDataJSON: clientData.a0_decodeBase64URLSafe()!)
            let signupChallenge = PasskeySignupChallenge(authenticationSession: authSession,
                                                         relyingPartyId: Domain,
                                                         userId: userId.a0_decodeBase64URLSafe()!,
                                                         userName: Email,
                                                         challengeData: challengeData)

            describe("login with signup passkey") {

                it("should login with signup passkey and default parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession,
                            "authn_response": [
                                "authenticatorAttachment": authenticatorAttachment,
                                "type": credentialType,
                                "response": [
                                    "attestationObject": attestationObject,
                                    "clientDataJSON": clientData
                                ]
                            ]
                        ])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge)
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                done()
                            }
                    }
                }

                it("should login with signup passkey and all parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "realm": ConnectionName,
                            "audience": Audience,
                            "scope": Scope,
                            "organization": OrganizationId,
                            "auth_session": authSession,
                            "authn_response": [
                                "authenticatorAttachment": authenticatorAttachment,
                                "type": credentialType,
                                "response": [
                                    "attestationObject": attestationObject,
                                    "clientDataJSON": clientData
                                ]
                            ]
                        ])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken, refreshToken: RefreshToken))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge,
                                   connection: ConnectionName,
                                   audience: Audience,
                                   scope: Scope,
                                   organization: OrganizationId)
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken, RefreshToken))
                                done()
                            }
                    }

                }

            }

            describe("passkey signup challenge") {

                it("should request passkey signup challenge with email and default parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(Domain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["email": Email]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: Domain,
                                                                userId: userId,
                                                                userName: Email,
                                                                challenge: challengeString))
                    
                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeySignupChallenge(email: Email)
                            .start { result in
                                expect(result).to(havePasskeySignupChallenge(identifier: Email))
                                done()
                            }
                    }
                }

                it("should request passkey signup challenge with phone number and default parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(Domain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["phone_number": Phone]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: Domain,
                                                                userId: userId,
                                                                userName: Phone,
                                                                challenge: challengeString))
                    
                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeySignupChallenge(phoneNumber: Phone)
                            .start { result in
                                expect(result).to(havePasskeySignupChallenge(identifier: Phone))
                                done()
                            }
                    }
                }

                it("should request passkey signup challenge with username and default parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(Domain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["username": Username]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: Domain,
                                                                userId: userId,
                                                                userName: Username,
                                                                challenge: challengeString))
                    
                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeySignupChallenge(username: Username)
                            .start { result in
                                expect(result).to(havePasskeySignupChallenge(identifier: Username))
                                done()
                            }
                    }
                }

                it("should request passkey signup challenge with all parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(Domain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "realm": ConnectionName,
                            "organization": OrganizationId,
                            "user_profile": ["email": Email, "phone_number": Phone, "username": Username, "name": Name]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: Domain,
                                                                userId: userId,
                                                                userName: Email,
                                                                userDisplayName: Name,
                                                                challenge: challengeString))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeySignupChallenge(email: Email,
                                                    phoneNumber: Phone,
                                                    username: Username,
                                                    name: Name,
                                                    connection: ConnectionName,
                                                    organization: OrganizationId)
                            .start { result in
                                expect(result).to(havePasskeySignupChallenge(identifier: Email))
                                done()
                            }
                    }

                }

            }

        }
        #endif

        // MARK:- Refresh Tokens
        
        describe("renew auth with refresh token") {

            let refreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")

            it("should receive credentials") {
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": refreshToken]) && $0.hasNoneOf(["audience", "scope"])
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.renew(withRefreshToken: refreshToken)
                        .start { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                    }
                }
            }

            it("should receive credentials when sending audience") {
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": refreshToken, "audience": Audience]) && $0.hasNoneOf(["scope"])
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.renew(withRefreshToken: refreshToken, audience: Audience)
                        .start { result in
                            expect(result).to(beSuccessful())
                            done()
                    }
                }
            }

            it("should receive credentials when sending scope") {
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": refreshToken, "scope": "openid email"]) && $0.hasNoneOf(["audience"])
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.renew(withRefreshToken: refreshToken, scope: "openid email")
                        .start { result in
                            expect(result).to(beSuccessful())
                            done()
                    }
                }
            }

            it("should receive credentials when sending scope without enforcing openid scope") {
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": refreshToken, "scope": "email phone"]) && $0.hasNoneOf(["audience"])
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.renew(withRefreshToken: refreshToken, scope: "email phone")
                        .start { result in
                            expect(result).to(beSuccessful())
                            done()
                    }
                }
            }

            it("should receive credentials when sending audience and scope") {
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": refreshToken, "audience": Audience, "scope": "openid email"])
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.renew(withRefreshToken: refreshToken, audience: Audience, scope: "openid email")
                        .start { result in
                            expect(result).to(beSuccessful())
                            done()
                    }
                }
            }

            it("should receive credentials when sending audience and scope enforcing openid scope") {
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": refreshToken, "audience": Audience, "scope": "openid email phone"]) }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.renew(withRefreshToken: refreshToken, audience: Audience, scope: "email phone")
                        .start { result in
                            expect(result).to(beSuccessful())
                            done()
                    }
                }
            }
        }
        
        it("should fail to receive credentials") {
            let invalidRefreshToken = "invalidtoken"
            
            NetworkStub.addStub(condition: {
                $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": invalidRefreshToken])
            }, response: authFailure(error: "", description: ""))
            
            waitUntil(timeout: Timeout) { done in
                auth.renew(withRefreshToken: invalidRefreshToken)
                    .start { result in
                        expect(result).toNot(haveCredentials())
                        done()
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
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAllOf([
                            "grant_type": TokenExchangeGrantType,
                            "subject_token": validCode,
                            "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                            "scope": defaultScope,
                            "client_id": ClientId
                        ])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken))

                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast([
                            "grant_type": TokenExchangeGrantType,
                            "subject_token": validCode,
                            "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                            "scope": "openid email",
                        ])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast([
                            "grant_type": TokenExchangeGrantType,
                            "subject_token": validCode,
                            "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                            "scope": "openid email phone"])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))

                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": validCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                        "scope": "openid email",
                        "audience": Audience
                    ])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": validNameCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code"]) && ($0.hasAtLeast(["user_profile": "{\"name\":{\"lastName\":\"Smith\",\"firstName\":\"John\"}}" ]) || $0.hasAtLeast(["user_profile": "{\"name\":{\"firstName\":\"John\",\"lastName\":\"Smith\"}}" ])) }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    
                        NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": validPartialNameCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                        "user_profile": "{\"name\":{\"firstName\":\"John\"}}"
                    ])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    
                        NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": validMissingNameCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code"]) &&
                            $0.hasNoneOf(["user_profile"])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken))

                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": validNameAndProfileCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code"]) &&
                        ($0.hasAtLeast(["user_profile": "{\"name\":{\"firstName\":\"John\"},\"user_metadata\":{\"custom_key\":\"custom_value\"}}"]) || $0.hasAtLeast(["user_profile": "{\"user_metadata\":{\"custom_key\":\"custom_value\"},\"name\":{\"firstName\":\"John\"}}"]))},
                         response: authResponse(accessToken: AccessToken, idToken: IdToken))

                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAllOf([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": invalidCode,
                        "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                        "scope": defaultScope,
                        "client_id": ClientId
                    ])}, response: authFailure(error: "", description: "")
                    )
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
                
                it("should exchange apple auth code for credentials when sending custom scope") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(appleAuthorizationCode: validCode, scope: "openid email")
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                            }
                    }
                    
                }
                
                it("should exchange apple auth code for credentials when sending custom scope enforcing openid scope") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(appleAuthorizationCode: validCode, scope: "email phone")
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                            }
                    }
                    
                }
                
                it("should exchange apple auth code for credentials when sending custom scope and audience") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(appleAuthorizationCode: validCode, audience: Audience, scope: "openid email")
                            .start { result in
                                expect(result).to(haveCredentials())
                                done()
                            }
                    }
                    
                }
                
                it("should exchange apple auth code for credentials when sending fullName") {
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
                
                it("should exchange apple auth code for credentials when sending partial fullName") {
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
                
                it("should exchange apple auth code for credentials when fullName is empty") {
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
                
                it("should exchange apple auth code for credentials when sending fullName and profile") {
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
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAllOf([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": sessionAccessToken,
                        "subject_token_type": "http://auth0.com/oauth/token-type/facebook-info-session-access-token",
                        "scope": defaultScope,
                        "user_profile": "{\"name\":\"John Smith\"}",
                        "client_id": ClientId
                    ])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    
                    waitUntil(timeout: Timeout) { done in
                        auth.login(facebookSessionAccessToken: sessionAccessToken, profile: profile)
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                done()
                            }
                    }
                }
                
                it("should include profile data") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) &&
                        ($0.hasAtLeast(["user_profile": "{\"name\":\"John Smith\",\"email\":\"john@smith.com\"}" ]) ||
                         $0.hasAtLeast(["user_profile": "{\"email\":\"john@smith.com\",\"name\":\"John Smith\"}" ]))}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    
                    waitUntil(timeout: Timeout) { done in
                        auth.login(facebookSessionAccessToken: sessionAccessToken,
                                   profile: ["name": "John Smith", "email": "john@smith.com"])
                        .start { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                    }
                }
                
                it("should include custom scope") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["scope": "openid email"])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    
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
                
                it("should include custom scope enforcing openid scope") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["scope": "openid email phone"]) }, response:  authResponse(accessToken: AccessToken, idToken: IdToken))
                    
                    waitUntil(timeout: Timeout) { done in
                        auth.login(facebookSessionAccessToken: sessionAccessToken,
                                   profile: profile,
                                   scope: "email phone")
                        .start { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                    }
                }
                
                it("should include audience if it is not nil") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["audience": Audience]) }, response:  authResponse(accessToken: AccessToken, idToken: IdToken))
                    
                    waitUntil(timeout: Timeout) { done in
                        auth.login(facebookSessionAccessToken: sessionAccessToken,
                                   profile: profile,
                                   audience: Audience)
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
                NetworkStub.addStub(condition: { $0.isRevokeToken(Domain) && $0.hasAtLeast(["token": refreshToken]) }, response:  revokeTokenResponse())
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
                NetworkStub.addStub(condition: { $0.isRevokeToken(Domain) && $0.hasAtLeast(["token": refreshToken]) }, response:  authFailure(code: code, description: description))
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
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "realm": "myrealm"])} , response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "myrealm").start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }
            
            it("should fail to return token") {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": InvalidPassword, "realm": "myrealm"])} , response: authFailure(error: "", description: ""))
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: InvalidPassword, realmOrConnection: "myrealm").start { result in
                        expect(result).toNot(haveCredentials())
                        done()
                    }
                }
            }
            
            it("should specify scope in request") {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "scope": "openid", "realm": "myrealm"])} , response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "myrealm", scope: "openid").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
            it("should specify scope in request enforcing openid scope") {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "scope": "openid email phone", "realm": "myrealm"])} , response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "myrealm", scope: "email phone").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
            it("should specify audience in request") {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "audience" : Audience, "realm": "myrealm"])} , response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "myrealm", audience: Audience).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
            it("should specify audience and scope in request") {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "audience" : Audience, "scope": "openid", "realm": "myrealm"])} , response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "myrealm", audience: Audience, scope: "openid").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
            it("should specify audience, scope and realm/connection in request") {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "audience" : Audience, "scope": "openid", "realm": "customconnection"])} , response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "customconnection", audience: Audience, scope: "openid").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
        }
        
        // MARK:- password grant type
        
        describe("authenticating with credentials in a default directory") {
            
            it("should receive token with username and password") {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword])} , response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword).start { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken))
                        done()
                    }
                }
            }
            
            it("should fail to return token") {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": InvalidPassword])} , response: authFailure(error: "", description: ""))
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: InvalidPassword).start { result in
                        expect(result).toNot(haveCredentials())
                        done()
                    }
                }
            }
            
            it("should specify scope in request") {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "scope": "openid"])} , response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword,  scope: "openid").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
            it("should specify scope in request enforcing openid scope") {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "scope": "openid email phone"])} , response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword,  scope: "email phone").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
            it("should specify audience in request") {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "audience" : Audience])} , response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword, audience: Audience).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
            it("should specify audience and scope in request") {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "password": ValidPassword, "audience" : Audience, "scope": "openid"])} , response: authResponse(accessToken: AccessToken, idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword, audience: Audience, scope: "openid").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
        }
        
        describe("create user") {
            
            beforeEach {
                NetworkStub.addStub(condition: { $0.isSignUp(Domain) && $0.hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])}, response: createdUser(email: SupportAtAuth0))
                NetworkStub.addStub(condition: { $0.isSignUp(Domain) && $0.hasAllOf(["email": SupportAtAuth0, "username": Support, "password": ValidPassword, "connection": ConnectionName, "client_id": ClientId])}, response: createdUser(email: SupportAtAuth0, username: Support))
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
                    NetworkStub.addStub(condition: { $0.isSignUp(Domain) && $0.hasAtLeast(["password": password])}, response: authFailure(code: code, description: description))
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
                NetworkStub.addStub(condition: {$0.isSignUp(Domain) && $0.hasUserMetadata(metadata)}, response: createdUser(email: email))
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
                    NetworkStub.addStub(condition: { $0.isSignUp(Domain) && $0.hasAtLeast(attributes)}, response:createdUser(email: SupportAtAuth0))
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
                    NetworkStub.addStub(condition: { $0.isSignUp(Domain) && !$0.hasAtLeast(attributes)}, response:createdUser(email: SupportAtAuth0))
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
                NetworkStub.addStub(condition: { $0.isResetPassword(Domain) && $0.hasAllOf(["email": SupportAtAuth0, "connection": ConnectionName, "client_id": ClientId])}, response: resetPasswordResponse())
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
                NetworkStub.addStub(condition: { $0.isResetPassword(Domain) && $0.hasAllOf(["email": SupportAtAuth0, "connection": ConnectionName, "client_id": ClientId])}, response: authFailure(code: code, description: description))
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
                NetworkStub.addStub(condition: { $0.isPasswordless(Domain) && $0.hasAllOf(["email": SupportAtAuth0, "connection": "email", "client_id": ClientId, "send": "code"])}, response: passwordless(SupportAtAuth0, verified: true))
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
            it("should start with email") {
                NetworkStub.addStub(condition: { $0.isPasswordless(Domain) && $0.hasAllOf(["email": SupportAtAuth0, "connection": "custom_email", "client_id": ClientId, "send": "link_ios"])}, response: passwordless(SupportAtAuth0, verified: true))
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0, type: .iOSLink, connection: "custom_email").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
            it("should fail to start") {
                NetworkStub.addStub(condition: { $0.isPasswordless(Domain) }, response:authFailure(error: "error", description: "description"))
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(email: SupportAtAuth0).start { result in
                        expect(result).to(haveAuthenticationError(code: "error", description: "description"))
                        done()
                    }
                }
            }
            
            context("passwordless login") {
                
                it("should login with email code") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": SupportAtAuth0, "otp": OTP, "realm": "email", "scope": defaultScope, "grant_type": PasswordlessGrantType, "client_id": ClientId])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP).start { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                    }
                }
                
                it("should include custom scope") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["scope": "openid email"])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, scope: "openid email").start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should include custom scope enforcing openid scope") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["scope": "openid email phone"])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, scope: "email phone").start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should include audience if it is not nil") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["audience": Audience])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, audience: Audience).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include audience if it is nil") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasNoneOf(["audience"])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(email: SupportAtAuth0, code: OTP, audience: nil).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include audience by default") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasNoneOf(["audience"])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
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
                NetworkStub.addStub(condition: { $0.isPasswordless(Domain) && $0.hasAllOf(["phone_number": Phone, "connection": "sms", "client_id": ClientId, "send": "code"]) }, response:passwordless(SupportAtAuth0, verified: true))
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(phoneNumber: Phone).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
            it("should start with sms") {
                NetworkStub.addStub(condition: { $0.isPasswordless(Domain) && $0.hasAllOf(["phone_number": Phone, "connection": "custom_sms", "client_id": ClientId, "send": "link_ios"]) }, response:passwordless(SupportAtAuth0, verified: true))
                waitUntil(timeout: Timeout) { done in
                    auth.startPasswordless(phoneNumber: Phone, type: .iOSLink, connection: "custom_sms").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }
            
            it("should fail to start") {
                NetworkStub.addStub(condition: { $0.isPasswordless(Domain)}, response: authFailure(error: "error", description: "description"))
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
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["username": Phone, "otp": OTP, "realm": smsRealm, "scope": defaultScope, "grant_type": PasswordlessGrantType, "client_id": ClientId])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP).start { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                    }
                }
                
                it("should include custom scope") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["scope": "openid email"])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, scope: "openid email").start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should include custom scope enforcing openid scope") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["scope": "openid email phone"])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, scope: "email phone").start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should include audience if it is not nil") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["audience": Audience])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, audience: Audience).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include audience if it is nil") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasNoneOf(["audience"])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(phoneNumber: Phone, code: OTP, audience: nil).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
                
                it("should not include audience by default") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasNoneOf(["audience"])}, response: authResponse(accessToken: AccessToken, idToken: IdToken))
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
                NetworkStub.addStub(condition: { $0.isUserInfo(Domain) && $0.hasBearerToken(AccessToken)}, response: apiSuccessResponse(json: basicProfile()))
                waitUntil(timeout: Timeout) { done in
                    auth.userInfo(withAccessToken: AccessToken).start { result in
                        expect(result).to(haveProfile(Sub))
                        done()
                    }
                }
            }
            
            it("should fail to get user info") {
                NetworkStub.addStub(condition: { $0.isUserInfo(Domain) }, response: authFailure(error: "invalid_token", description: "the token is invalid"))
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
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["code": code!, "code_verifier": codeVerifier!, "grant_type": "authorization_code", "redirect_uri": redirectURI])}, response:authResponse(accessToken: AccessToken, idToken: IdToken))
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
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["code": invalidCode])}, response:authFailure(code: code, description: description))
                    auth.codeExchange(withCode: invalidCode, codeVerifier: codeVerifier, redirectURI: redirectURI).start { result in
                        expect(result).to(haveAuthenticationError(code: code, description: description))
                        done()
                    }
                }
            }
            
        }
        
        describe("sso exchange") {
            let grantType = "refresh_token"
            let audience = "urn:\(Domain):session_transfer"
            
            it("should exchange the refresh token for a session transfer token without refresh token rotation") {
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) &&
                    $0.hasAllOf([
                        "refresh_token": RefreshToken,
                        "grant_type": grantType,
                        "audience": audience,
                        "client_id": ClientId
                    ])
                }, response: authResponse(accessToken: SessionTransferToken,
                                          issuedTokenType: SessionTransferTokenTokenType,
                                          idToken: IdToken))
                waitUntil(timeout: Timeout) { done in
                    auth
                        .ssoExchange(withRefreshToken: RefreshToken)
                        .start { result in
                            expect(result).to(haveSSOCredentials(SessionTransferToken, IdToken))
                            done()
                    }
                }
            }
            
            it("should exchange the refresh token for a session transfer token with refresh token rotation") {
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) &&
                    $0.hasAllOf([
                        "refresh_token": RefreshToken,
                        "grant_type": grantType,
                        "audience": audience,
                        "client_id": ClientId
                    ])
                }, response: authResponse(accessToken: SessionTransferToken,
                                          issuedTokenType: SessionTransferTokenTokenType,
                                          idToken: IdToken,
                                          refreshToken: RefreshToken))
                waitUntil(timeout: Timeout) { done in
                    auth
                        .ssoExchange(withRefreshToken: RefreshToken)
                        .start { result in
                            expect(result).to(haveSSOCredentials(SessionTransferToken, IdToken, RefreshToken))
                            done()
                    }
                }
            }
            
            it("should fail to exchange the refresh token for a session transfer token") {
                waitUntil(timeout: Timeout) { done in
                    let code = "invalid_request"
                    let description = "missing params"
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) &&
                        $0.hasAllOf([
                            "refresh_token": RefreshToken,
                            "grant_type": grantType,
                            "audience": audience,
                            "client_id": ClientId
                        ])
                    }, response:authFailure(code: code, description: description))
                    auth
                        .ssoExchange(withRefreshToken: RefreshToken)
                        .start { result in
                            expect(result).to(haveAuthenticationError(code: code, description: description))
                            done()
                    }
                }
            }
            
        }
        
        describe("jwks") {
            it("should fetch the jwks") {
                NetworkStub.addStub(condition: { $0.isJWKSPath(Domain) }, response: jwksResponse())
                waitUntil { done in
                    auth.jwks().start {
                        expect($0).to(haveJWKS())
                        done()
                    }
                }
            }
            
            it("should produce an error") {
                NetworkStub.addStub(condition: { $0.isJWKSPath(Domain) }, response: apiFailureResponse())
                waitUntil { done in
                    auth.jwks().start {
                        expect($0).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }
        
    }
}
