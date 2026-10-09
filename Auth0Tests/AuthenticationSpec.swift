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
private let PasskeyDomain = "passkeystestdomain.acmetest.org"
private let PasskeyDomainURL = URL(string: "http://\(PasskeyDomain)")!
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
            
            it("should init with client id, url & auth0ClientInfo") {
                let telemetryInfo = "info"
                var auth0ClientInfo = Auth0ClientInfo()
                auth0ClientInfo.info = telemetryInfo
                let authentication = Auth0Authentication(clientId: ClientId, url: DomainURL, auth0ClientInfo: auth0ClientInfo)
                expect(authentication.auth0ClientInfo.info) == telemetryInfo
            }
            
        }
        
        // MARK: - Passkeys

        #if PASSKEYS_PLATFORM
        if #available(iOS 16.6, macOS 13.5, visionOS 1.0, *) {
            let auth: Authentication = Auth0Authentication(clientId: ClientId, url: PasskeyDomainURL)

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
                                                  relyingPartyId: PasskeyDomain,
                                                  challengeData: challengeData)

            describe("login with passkey") {

                it("should login with passkey and default parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
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
                        $0.isToken(PasskeyDomain) &&
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

                it("should use DPoP when it is enabled") {
                    let auth = Auth0Authentication(clientId: ClientId, url: PasskeyDomainURL).useDPoP()
                    let request = auth.login(passkey: passkey,
                                             challenge: challenge,
                                             connection: ConnectionName,
                                             audience: Audience,
                                             scope: Scope)

                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).toNot(beNil())
                }

                it("should not use DPoP when it is not enabled") {
                    let request = auth.login(passkey: passkey,
                                             challenge: challenge,
                                             connection: ConnectionName,
                                             audience: Audience,
                                             scope: Scope)

                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).to(beNil())
                }

            }

            describe("passkey login challenge") {

                it("should request passkey login challenge with default parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeyLoginChallenge(PasskeyDomain) && $0.hasAtLeast(["client_id": ClientId])
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
                        $0.isPasskeyLoginChallenge(PasskeyDomain) && $0.hasAtLeast([
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

                it("should not use DPoP") {
                    let auth = Auth0Authentication(clientId: ClientId, url: PasskeyDomainURL).useDPoP()
                    let request = auth.passkeyLoginChallenge(connection: ConnectionName)

                    expect((request as? Request<PasskeyLoginChallenge, AuthenticationError>)?.dpop).to(beNil())
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
                                                         relyingPartyId: PasskeyDomain,
                                                         userId: userId.a0_decodeBase64URLSafe()!,
                                                         userName: Email,
                                                         challengeData: challengeData)

            describe("login with signup passkey") {

                it("should login with signup passkey and default parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
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
                        $0.isToken(PasskeyDomain) &&
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

                it("should login with signup passkey and verification codes") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession,
                            "verification": ["email": "123456", "phone": "654321"],
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
                                   challenge: signupChallenge,
                                   connection: nil,
                                   audience: nil,
                                   scope: defaultScope,
                                   organization: nil,
                                   verification: [.email: "123456", .phone: "654321"])
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                done()
                            }
                    }
                }

                it("should login with signup passkey when a single email verification code is provided") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession,
                            "verification": ["email": "123456"],
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
                                   challenge: signupChallenge,
                                   connection: nil,
                                   audience: nil,
                                   scope: defaultScope,
                                   organization: nil,
                                   verification: [.email: "123456"])
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                done()
                            }
                    }
                }

                it("should not send verification when no verification codes are provided") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession
                        ]) &&
                        $0.hasNoneOf(["verification"])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge,
                                   verification: [:])
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                done()
                            }
                    }
                }

                it("should use DPoP when it is enabled") {
                    let auth = Auth0Authentication(clientId: ClientId, url: PasskeyDomainURL).useDPoP()
                    let request = auth.login(passkey: signupPasskey,
                                             challenge: signupChallenge,
                                             connection: ConnectionName,
                                             audience: Audience,
                                             scope: Scope)

                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).toNot(beNil())
                }

                it("should not use DPoP when it is not enabled") {
                    let request = auth.login(passkey: signupPasskey,
                                             challenge: signupChallenge,
                                             connection: ConnectionName,
                                             audience: Audience,
                                             scope: Scope)

                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).to(beNil())
                }

            }

            describe("passkey signup challenge") {

                it("should request passkey signup challenge with email and default parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["email": Email]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
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
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["phone_number": Phone]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
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
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["username": Username]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
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
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "realm": ConnectionName,
                            "organization": OrganizationId,
                            "user_profile": ["email": Email, "phone_number": Phone, "username": Username, "name": Name]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
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

                it("should request passkey signup challenge with additional profile fields") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": [
                                "email": Email,
                                "given_name": "John",
                                "family_name": "Doe",
                                "nickname": "johnny",
                                "picture": "https://example.com/photo.png"
                            ]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
                                                                userId: userId,
                                                                userName: Email,
                                                                challenge: challengeString))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeySignupChallenge(email: Email,
                                                    givenName: "John",
                                                    familyName: "Doe",
                                                    nickname: "johnny",
                                                    picture: "https://example.com/photo.png")
                            .start { result in
                                expect(result).to(havePasskeySignupChallenge(identifier: Email))
                                done()
                            }
                    }
                }

                it("should request passkey signup challenge with user metadata") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["email": Email],
                            "user_metadata": ["signup_source": "ios_app"]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
                                                                userId: userId,
                                                                userName: Email,
                                                                challenge: challengeString))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeySignupChallenge(email: Email,
                                                    userMetadata: ["signup_source": "ios_app"])
                            .start { result in
                                expect(result).to(havePasskeySignupChallenge(identifier: Email))
                                done()
                            }
                    }
                }

                it("should request passkey signup challenge with all fields including user metadata") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "realm": ConnectionName,
                            "organization": OrganizationId,
                            "user_profile": [
                                "email": Email,
                                "phone_number": Phone,
                                "username": Username,
                                "name": Name,
                                "given_name": "John",
                                "family_name": "Doe",
                                "nickname": "johnny",
                                "picture": "https://example.com/photo.png"
                            ],
                            "user_metadata": ["key1": "value1"]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
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
                                                    givenName: "John",
                                                    familyName: "Doe",
                                                    nickname: "johnny",
                                                    picture: "https://example.com/photo.png",
                                                    userMetadata: ["key1": "value1"],
                                                    connection: ConnectionName,
                                                    organization: OrganizationId)
                            .start { result in
                                expect(result).to(havePasskeySignupChallenge(identifier: Email))
                                done()
                            }
                    }
                }

                it("should not send delivery_method when it is not specified") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["email": Email]
                        ]) &&
                        $0.hasNoneOf(["delivery_method"])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
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

                it("should send delivery_method text when specified") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["email": Email, "phone_number": Phone],
                            "delivery_method": "text"
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
                                                                userId: userId,
                                                                userName: Email,
                                                                challenge: challengeString))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeySignupChallenge(email: Email,
                                                    phoneNumber: Phone,
                                                    username: nil,
                                                    name: nil,
                                                    givenName: nil,
                                                    familyName: nil,
                                                    nickname: nil,
                                                    picture: nil,
                                                    userMetadata: nil,
                                                    connection: nil,
                                                    organization: nil,
                                                    deliveryMethod: .text)
                            .start { result in
                                expect(result).to(havePasskeySignupChallenge(identifier: Email))
                                done()
                            }
                    }
                }

                it("should send delivery_method voice when specified") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["email": Email, "phone_number": Phone],
                            "delivery_method": "voice"
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
                                                                userId: userId,
                                                                userName: Email,
                                                                challenge: challengeString))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeySignupChallenge(email: Email,
                                                    phoneNumber: Phone,
                                                    username: nil,
                                                    name: nil,
                                                    givenName: nil,
                                                    familyName: nil,
                                                    nickname: nil,
                                                    picture: nil,
                                                    userMetadata: nil,
                                                    connection: nil,
                                                    organization: nil,
                                                    deliveryMethod: .voice)
                            .start { result in
                                expect(result).to(havePasskeySignupChallenge(identifier: Email))
                                done()
                            }
                    }
                }

                it("should decode verification_required when present in the challenge response") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["email": Email]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
                                                                userId: userId,
                                                                userName: Email,
                                                                challenge: challengeString,
                                                                verificationRequired: ["email"]))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeySignupChallenge(email: Email)
                            .start { result in
                                if case .success(let challenge) = result {
                                    expect(challenge.verificationRequired) == [.email]
                                } else {
                                    fail("Expected success")
                                }
                                done()
                            }
                    }
                }

                it("should decode verification_required for email and phone") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["email": Email]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
                                                                userId: userId,
                                                                userName: Email,
                                                                challenge: challengeString,
                                                                verificationRequired: ["email", "phone"]))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeySignupChallenge(email: Email)
                            .start { result in
                                if case .success(let challenge) = result {
                                    expect(challenge.verificationRequired) == [.email, .phone]
                                } else {
                                    fail("Expected success")
                                }
                                done()
                            }
                    }
                }

                it("should decode unrecognized verification_required values as unknown") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["email": Email]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
                                                                userId: userId,
                                                                userName: Email,
                                                                challenge: challengeString,
                                                                verificationRequired: ["email", "username"]))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeySignupChallenge(email: Email)
                            .start { result in
                                if case .success(let challenge) = result {
                                    expect(challenge.verificationRequired) == [.email, .unknown("username")]
                                    expect(challenge.verificationRequired?.map(\.rawValue)) == ["email", "username"]
                                } else {
                                    fail("Expected success")
                                }
                                done()
                            }
                    }
                }

                it("should have nil verificationRequired when absent from challenge response") {
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasAtLeast([
                            "client_id": ClientId,
                            "user_profile": ["email": Email]
                        ])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
                                                                userId: userId,
                                                                userName: Email,
                                                                challenge: challengeString))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .passkeySignupChallenge(email: Email)
                            .start { result in
                                if case .success(let challenge) = result {
                                    expect(challenge.verificationRequired).to(beNil())
                                } else {
                                    fail("Expected success")
                                }
                                done()
                            }
                    }
                }

                it("should not use DPoP") {
                    let auth = Auth0Authentication(clientId: ClientId, url: PasskeyDomainURL).useDPoP()
                    let request = auth.passkeySignupChallenge(email: Email,
                                                              phoneNumber: Phone,
                                                              username: Username,
                                                              name: Name,
                                                              connection: ConnectionName)

                    expect((request as? Request<PasskeySignupChallenge, AuthenticationError>)?.dpop).to(beNil())
                }

            }

            describe("passkey signup token exchange errors") {

                it("should surface retryable invalid_grant with verification_required and auth_session") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession
                        ])
                    }, response: apiFailureResponse(json: [
                        "error": "invalid_grant",
                        "error_description": "Invalid or expired session",
                        "auth_session": authSession,
                        "verification_required": ["email"]
                    ], statusCode: 400))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge)
                            .start { result in
                                if case .failure(let error) = result {
                                    expect(error.code) == "invalid_grant"
                                    expect(error.passkeyVerificationRequired) == [.email]
                                    expect(error.passkeyAuthSession) == authSession
                                    expect(error.isPasskeyVerificationCodeInvalid) == true
                                } else {
                                    fail("Expected failure")
                                }
                                done()
                            }
                    }
                }

                it("should surface terminal invalid_grant without auth_session") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession
                        ])
                    }, response: apiFailureResponse(json: [
                        "error": "invalid_grant",
                        "error_description": "Invalid or expired session"
                    ], statusCode: 400))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge)
                            .start { result in
                                if case .failure(let error) = result {
                                    expect(error.code) == "invalid_grant"
                                    expect(error.passkeyAuthSession).to(beNil())
                                    expect(error.isPasskeyVerificationCodeInvalid) == false
                                } else {
                                    fail("Expected failure")
                                }
                                done()
                            }
                    }
                }

                it("should report a missing verification code as invalid_request without a session") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession
                        ])
                    }, response: apiFailureResponse(json: [
                        "error": "invalid_request",
                        "error_description": "Missing required parameter: verification.email"
                    ], statusCode: 400))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge)
                            .start { result in
                                if case .failure(let error) = result {
                                    expect(error.code) == "invalid_request"
                                    expect(error.statusCode) == 400
                                    expect(error.isPasskeyVerificationCodeMissing) == true
                                    expect(error.isPasskeyVerificationCodeInvalid) == false
                                    expect(error.passkeyAuthSession).to(beNil())
                                } else {
                                    fail("Expected failure")
                                }
                                done()
                            }
                    }
                }

                it("should report an empty verification code as invalid_request without a session") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession,
                            "verification": ["email": ""]
                        ])
                    }, response: apiFailureResponse(json: [
                        "error": "invalid_request",
                        "error_description": "\"verification.email\" is not allowed to be empty"
                    ], statusCode: 400))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge,
                                   verification: [.email: ""])
                            .start { result in
                                if case .failure(let error) = result {
                                    expect(error.code) == "invalid_request"
                                    expect(error.isPasskeyVerificationCodeMissing) == true
                                    expect(error.isPasskeyVerificationCodeInvalid) == false
                                    expect(error.passkeyAuthSession).to(beNil())
                                } else {
                                    fail("Expected failure")
                                }
                                done()
                            }
                    }
                }

                it("should not report other invalid_request errors as a missing verification code") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession
                        ])
                    }, response: apiFailureResponse(json: [
                        "error": "invalid_request",
                        "error_description": "realm mismatch"
                    ], statusCode: 400))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge)
                            .start { result in
                                if case .failure(let error) = result {
                                    expect(error.code) == "invalid_request"
                                    expect(error.isPasskeyVerificationCodeMissing) == false
                                    expect(error.isPasskeyVerificationCodeInvalid) == false
                                } else {
                                    fail("Expected failure")
                                }
                                done()
                            }
                    }
                }

                it("should accept the corrected code on the same session after a wrong code") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession,
                            "verification": ["email": "000000"]
                        ])
                    }, response: apiFailureResponse(json: [
                        "error": "invalid_grant",
                        "error_description": "Invalid or expired session",
                        "auth_session": authSession,
                        "verification_required": ["email"]
                    ], statusCode: 400))

                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession,
                            "verification": ["email": "123456"]
                        ])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge,
                                   verification: [.email: "000000"])
                            .start { first in
                                guard case .failure(let wrongCodeError) = first else {
                                    fail("Expected failure")
                                    return done()
                                }
                                expect(wrongCodeError.isPasskeyVerificationCodeInvalid) == true
                                expect(wrongCodeError.passkeyAuthSession) == authSession
                                expect(wrongCodeError.passkeyVerificationRequired) == [.email]

                                // Same challenge, same passkey, corrected code
                                auth
                                    .login(passkey: signupPasskey,
                                           challenge: signupChallenge,
                                           verification: [.email: "123456"])
                                    .start { second in
                                        expect(second).to(haveCredentials(AccessToken, IdToken))
                                        done()
                                    }
                            }
                    }
                }

                it("should surface a rate limit response from the token endpoint") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession
                        ])
                    }, response: apiFailureResponse(json: [
                        "error": "too_many_requests",
                        "error_description": "Rate limit exceeded"
                    ], statusCode: 429))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge)
                            .start { result in
                                if case .failure(let error) = result {
                                    expect(error.statusCode) == 429
                                    expect(error.code) == "too_many_requests"
                                    expect(error.isPasskeyVerificationCodeInvalid) == false
                                    expect(error.isPasskeyVerificationCodeMissing) == false
                                } else {
                                    fail("Expected failure")
                                }
                                done()
                            }
                    }
                }

                it("should surface terminal invalid_grant with 403 for unknown or consumed session") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession
                        ])
                    }, response: apiFailureResponse(json: [
                        "error": "invalid_grant",
                        "error_description": "Invalid or expired session"
                    ], statusCode: 403))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge)
                            .start { result in
                                if case .failure(let error) = result {
                                    expect(error.code) == "invalid_grant"
                                    expect(error.statusCode) == 403
                                    expect(error.passkeyAuthSession).to(beNil())
                                    expect(error.isPasskeyVerificationCodeInvalid) == false
                                } else {
                                    fail("Expected failure")
                                }
                                done()
                            }
                    }
                }

                it("should surface mfa_required with an mfa_token once verification has passed") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession
                        ])
                    }, response: apiFailureResponse(json: [
                        "error": "mfa_required",
                        "error_description": "Multifactor authentication required",
                        "mfa_token": "test-mfa-token"
                    ], statusCode: 403))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge,
                                   verification: [.email: "123456"])
                            .start { result in
                                if case .failure(let error) = result {
                                    expect(error.code) == "mfa_required"
                                    expect(error.statusCode) == 403
                                    expect(error.isMultifactorRequired) == true
                                    expect(error.localizedDescription) == "Multifactor authentication required"
                                    // The MFA token is what the MFA API needs to continue
                                    expect(error.mfaRequiredErrorPayload?.mfaToken) == "test-mfa-token"
                                    // Verification passed, so there is nothing left to retry on the passkey session
                                    expect(error.passkeyAuthSession).to(beNil())
                                    expect(error.passkeyVerificationRequired).to(beNil())
                                    expect(error.isPasskeyVerificationCodeInvalid) == false
                                } else {
                                    fail("Expected failure")
                                }
                                done()
                            }
                    }
                }

                it("should pass verification and reach mfa_required when a missing code is retried on the same session") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession
                        ]) &&
                        $0.hasNoneOf(["verification"])
                    }, response: apiFailureResponse(json: [
                        "error": "invalid_request",
                        "error_description": "Missing required parameter: verification.email"
                    ], statusCode: 400))

                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession,
                            "verification": ["email": "123456"]
                        ])
                    }, response: apiFailureResponse(json: [
                        "error": "mfa_required",
                        "error_description": "Multifactor authentication required",
                        "mfa_token": "test-mfa-token"
                    ], statusCode: 403))

                    waitUntil(timeout: Timeout) { done in
                        auth
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge)
                            .start { first in
                                guard case .failure(let missingCodeError) = first else {
                                    fail("Expected failure")
                                    return done()
                                }
                                expect(missingCodeError.code) == "invalid_request"
                                expect(missingCodeError.passkeyAuthSession).to(beNil())

                                // Same challenge, same passkey: the session is still usable, now with the code
                                auth
                                    .login(passkey: signupPasskey,
                                           challenge: signupChallenge,
                                           verification: [.email: "123456"])
                                    .start { second in
                                        if case .failure(let error) = second {
                                            // mfa_required means the code was accepted
                                            expect(error.isMultifactorRequired) == true
                                            expect(error.mfaRequiredErrorPayload?.mfaToken) == "test-mfa-token"
                                        } else {
                                            fail("Expected failure")
                                        }
                                        done()
                                    }
                            }
                    }
                }

            }

            describe("conformers written before passkey identifier verification") {

                // These conformers implement neither `login(...verification:)` nor `passkeySignupChallenge(...deliveryMethod:)`.
                // Calls that don't use the new parameters must reach the requirements they do implement, not recurse.

                it("should forward login without verification to the base requirement") {
                    let recorder = CallRecorder()
                    let legacy: Authentication = LegacyAuthentication(
                        wrapped: Auth0Authentication(clientId: ClientId, url: PasskeyDomainURL),
                        recorder: recorder
                    )
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) &&
                        $0.hasAtLeast([
                            "client_id": ClientId,
                            "grant_type": PasskeysGrantType,
                            "auth_session": authSession
                        ]) &&
                        $0.hasNoneOf(["verification"])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken))

                    waitUntil(timeout: Timeout) { done in
                        legacy
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge)
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                expect(recorder.calls) == ["login(passkey:challenge:connection:audience:scope:organization:)"]
                                done()
                            }
                    }
                }

                it("should forward login with an empty verification to the base requirement") {
                    let recorder = CallRecorder()
                    let legacy: Authentication = LegacyAuthentication(
                        wrapped: Auth0Authentication(clientId: ClientId, url: PasskeyDomainURL),
                        recorder: recorder
                    )
                    NetworkStub.addStub(condition: {
                        $0.isToken(PasskeyDomain) && $0.hasNoneOf(["verification"])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken))

                    waitUntil(timeout: Timeout) { done in
                        legacy
                            .login(passkey: signupPasskey,
                                   challenge: signupChallenge,
                                   verification: [:])
                            .start { result in
                                expect(result).to(haveCredentials(AccessToken, IdToken))
                                expect(recorder.calls) == ["login(passkey:challenge:connection:audience:scope:organization:)"]
                                done()
                            }
                    }
                }

                it("should forward passkeySignupChallenge without a delivery method to the base requirement") {
                    let recorder = CallRecorder()
                    let legacy: Authentication = LegacyAuthentication(
                        wrapped: Auth0Authentication(clientId: ClientId, url: PasskeyDomainURL),
                        recorder: recorder
                    )
                    NetworkStub.addStub(condition: {
                        $0.isPasskeySignupChallenge(PasskeyDomain) && $0.hasNoneOf(["delivery_method"])
                    }, response: passkeySignupChallengeResponse(authSession: authSession,
                                                                rpId: PasskeyDomain,
                                                                userId: userId,
                                                                userName: Email,
                                                                challenge: challengeString))

                    waitUntil(timeout: Timeout) { done in
                        legacy
                            .passkeySignupChallenge(email: Email)
                            .start { result in
                                expect(result).to(havePasskeySignupChallenge(identifier: Email))
                                expect(recorder.calls) == ["passkeySignupChallenge(...organization:)"]
                                done()
                            }
                    }
                }

            }

            describe("PasskeyVerificationMethod") {

                it("should expose the raw values used by the Authentication API") {
                    expect(PasskeyVerificationMethod.email.rawValue) == "email"
                    expect(PasskeyVerificationMethod.phone.rawValue) == "phone"
                    expect(PasskeyVerificationMethod.unknown("username").rawValue) == "username"
                }

                it("should map raw values to known cases and keep unrecognized ones") {
                    expect(PasskeyVerificationMethod(rawValue: "email")) == .email
                    expect(PasskeyVerificationMethod(rawValue: "phone")) == .phone
                    expect(PasskeyVerificationMethod(rawValue: "username")) == .unknown("username")
                }

                it("should compare and hash by raw value") {
                    expect(PasskeyVerificationMethod.unknown("email")) == PasskeyVerificationMethod.email
                    expect(Set([PasskeyVerificationMethod.email, .unknown("email"), .phone]).count) == 2
                }

                it("should decode from a string") {
                    let data = Data(#"["email","phone","sms"]"#.utf8)
                    let methods = try? JSONDecoder().decode([PasskeyVerificationMethod].self, from: data)
                    expect(methods) == [.email, .phone, .unknown("sms")]
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

            it("should use DPoP when it is enabled") {
                let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                let request = auth.renew(withRefreshToken: refreshToken)

                expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).toNot(beNil())
            }

            it("should not use DPoP when it is not enabled") {
                let request = auth.renew(withRefreshToken: refreshToken)

                expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).to(beNil())
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

                it("should use DPoP when it is enabled") {
                    let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                    let request = auth.login(appleAuthorizationCode: validCode)

                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).toNot(beNil())
                }

                it("should not use DPoP when it is not enabled") {
                    let request = auth.login(appleAuthorizationCode: validCode)

                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).to(beNil())
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

                it("should use DPoP when it is enabled") {
                    let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                    let request = auth.login(facebookSessionAccessToken: sessionAccessToken, profile: profile)

                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).toNot(beNil())
                }

                it("should not use DPoP when it is not enabled") {
                    let request = auth.login(facebookSessionAccessToken: sessionAccessToken, profile: profile)

                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).to(beNil())
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

            it("should not use DPoP") {
                let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                let request = auth.revoke(refreshToken: refreshToken)

                expect((request as? Request<Void, AuthenticationError>)?.dpop).to(beNil())
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

            it("should use DPoP when it is enabled") {
                let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                let request = auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "myrealm")

                expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).toNot(beNil())
            }

            it("should not use DPoP when it is not enabled") {
                let request = auth.login(usernameOrEmail: SupportAtAuth0, password: ValidPassword, realmOrConnection: "myrealm")

                expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).to(beNil())
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

            it("should use DPoP when it is enabled") {
                let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                let request = auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword)

                expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).toNot(beNil())
            }

            it("should not use DPoP when it is not enabled") {
                let request = auth.loginDefaultDirectory(withUsername: SupportAtAuth0, password: ValidPassword)

                expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).to(beNil())
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
            
            it("should create a user with default connection") {
                NetworkStub.clearStubs()
                NetworkStub.addStub(condition: { $0.isSignUp(Domain) && $0.hasAllOf(["email": SupportAtAuth0, "password": ValidPassword, "connection": "Username-Password-Authentication", "client_id": ClientId])}, response: createdUser(email: SupportAtAuth0))
                waitUntil(timeout: Timeout) { done in
                    auth.signup(email: SupportAtAuth0, password: ValidPassword).start { result in
                        expect(result).to(haveCreatedUser(SupportAtAuth0))
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

            it("should not use DPoP") {
                let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                let request = auth.signup(email: SupportAtAuth0, password: ValidPassword, connection: ConnectionName)

                expect((request as? Request<DatabaseUser, AuthenticationError>)?.dpop).to(beNil())
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

            it("should reset password with organization") {
                NetworkStub.addStub(condition: { $0.isResetPassword(Domain) && $0.hasAllOf(["email": SupportAtAuth0, "connection": ConnectionName, "client_id": ClientId, "organization": OrganizationId])}, response: resetPasswordResponse())
                waitUntil(timeout: Timeout) { done in
                    auth.resetPassword(email: SupportAtAuth0, connection: ConnectionName, organization: OrganizationId).start { result in
                        guard case .success = result else { return fail("Failed to reset password") }
                        done()
                    }
                }
            }

            it("should not use DPoP") {
                let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                let request = auth.resetPassword(email: SupportAtAuth0, connection: ConnectionName)

                expect((request as? Request<Void, AuthenticationError>)?.dpop).to(beNil())
            }

            it("should not send an organization when it is nil") {
                NetworkStub.addStub(condition: { $0.isResetPassword(Domain) && $0.hasAllOf(["email": SupportAtAuth0, "connection": ConnectionName, "client_id": ClientId])}, response: resetPasswordResponse())
                waitUntil(timeout: Timeout) { done in
                    auth.resetPassword(email: SupportAtAuth0, connection: ConnectionName, organization: nil).start { result in
                        guard case .success = result else { return fail("Failed to reset password") }
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

            it("should not use DPoP") {
                let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                let request = auth.startPasswordless(email: SupportAtAuth0)

                expect((request as? Request<Void, AuthenticationError>)?.dpop).to(beNil())
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

                it("should use DPoP when it is enabled") {
                    let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                    let request = auth.login(email: SupportAtAuth0, code: OTP)

                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).toNot(beNil())
                }

                it("should not use DPoP when it is not enabled") {
                    let request = auth.login(email: SupportAtAuth0, code: OTP)

                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).to(beNil())
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

            it("should not use DPoP") {
                let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                let request = auth.startPasswordless(phoneNumber: Phone)

                expect((request as? Request<Void, AuthenticationError>)?.dpop).to(beNil())
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

                it("should use DPoP when it is enabled") {
                    let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                    let request = auth.login(phoneNumber: Phone, code: OTP)

                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).toNot(beNil())
                }

                it("should not use DPoP when it is not enabled") {
                    let request = auth.login(phoneNumber: Phone, code: OTP)

                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).to(beNil())
                }

            }
        }

        describe("passwordless db challenge") {
            let AuthSession = "test-auth-session"

            afterEach {
                NetworkStub.clearStubs()
            }

            context("challenge with email") {

                it("should request challenge with default allowSignup false") {
                    NetworkStub.addStub(condition: {
                        $0.isOTPChallenge(Domain) &&
                        $0.hasAtLeast(["email": SupportAtAuth0,
                                       "connection": ConnectionName,
                                       "client_id": ClientId]) &&
                        ($0.payload?["allow_signup"] as? Bool) == false
                    }, response: passwordlessChallengeResponse(authSession: AuthSession))
                    waitUntil(timeout: Timeout) { done in
                        auth.passwordlessChallenge(email: SupportAtAuth0, connection: ConnectionName).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

                it("should send allow_signup true when specified") {
                    NetworkStub.addStub(condition: {
                        $0.isOTPChallenge(Domain) &&
                        $0.hasAtLeast(["email": SupportAtAuth0,
                                       "connection": ConnectionName,
                                       "client_id": ClientId]) &&
                        ($0.payload?["allow_signup"] as? Bool) == true
                    }, response: passwordlessChallengeResponse(authSession: AuthSession))
                    waitUntil(timeout: Timeout) { done in
                        auth.passwordlessChallenge(email: SupportAtAuth0, connection: ConnectionName, allowSignup: true).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

                it("should return the auth session from the response") {
                    NetworkStub.addStub(condition: { $0.isOTPChallenge(Domain) },
                                        response: passwordlessChallengeResponse(authSession: AuthSession))
                    waitUntil(timeout: Timeout) { done in
                        auth.passwordlessChallenge(email: SupportAtAuth0, connection: ConnectionName).start { result in
                            if case .success(let challenge) = result {
                                expect(challenge.authSession).to(equal(AuthSession))
                            } else {
                                fail("Expected success but got failure")
                            }
                            done()
                        }
                    }
                }

                it("should fail on invalid_connection") {
                    NetworkStub.addStub(condition: { $0.isOTPChallenge(Domain) },
                                        response: authFailure(error: "invalid_connection", description: "Unknown connection"))
                    waitUntil(timeout: Timeout) { done in
                        auth.passwordlessChallenge(email: SupportAtAuth0, connection: ConnectionName).start { result in
                            expect(result).to(haveAuthenticationError(code: "invalid_connection", description: "Unknown connection"))
                            done()
                        }
                    }
                }

                it("should use DPoP when it is enabled") {
                    let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                    let request = auth.passwordlessChallenge(email: SupportAtAuth0, connection: ConnectionName)
                    expect((request as? Request<PasswordlessChallenge, AuthenticationError>)?.dpop).toNot(beNil())
                }

                it("should not use DPoP when it is not enabled") {
                    let request = auth.passwordlessChallenge(email: SupportAtAuth0, connection: ConnectionName)
                    expect((request as? Request<PasswordlessChallenge, AuthenticationError>)?.dpop).to(beNil())
                }

                it("should include the Auth0-Client telemetry header on challenge requests") {
                    var capturedHeaders: [String: String] = [:]
                    NetworkStub.addStub(condition: { $0.isOTPChallenge(Domain) },
                                        response: { request in
                        capturedHeaders = request.allHTTPHeaderFields ?? [:]
                        return passwordlessChallengeResponse(authSession: AuthSession)(request)
                    })
                    waitUntil(timeout: Timeout) { done in
                        auth.passwordlessChallenge(email: SupportAtAuth0, connection: ConnectionName).start { _ in
                            expect(capturedHeaders["Auth0-Client"]).toNot(beNil())
                            done()
                        }
                    }
                }

            }

            context("challenge with phone number") {

                it("should request challenge with default delivery method text") {
                    NetworkStub.addStub(condition: {
                        $0.isOTPChallenge(Domain) &&
                        $0.hasAtLeast(["phone_number": Phone,
                                       "connection": ConnectionName,
                                       "client_id": ClientId,
                                       "delivery_method": "text"]) &&
                        ($0.payload?["allow_signup"] as? Bool) == false
                    }, response: passwordlessChallengeResponse(authSession: AuthSession))
                    waitUntil(timeout: Timeout) { done in
                        auth.passwordlessChallenge(phoneNumber: Phone, connection: ConnectionName).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

                it("should send delivery_method voice when specified") {
                    NetworkStub.addStub(condition: {
                        $0.isOTPChallenge(Domain) &&
                        $0.hasAtLeast(["phone_number": Phone,
                                       "connection": ConnectionName,
                                       "client_id": ClientId,
                                       "delivery_method": "voice"])
                    }, response: passwordlessChallengeResponse(authSession: AuthSession))
                    waitUntil(timeout: Timeout) { done in
                        auth.passwordlessChallenge(phoneNumber: Phone, connection: ConnectionName, deliveryMethod: .voice).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

                it("should fail on invalid_request") {
                    NetworkStub.addStub(condition: { $0.isOTPChallenge(Domain) },
                                        response: authFailure(error: "invalid_request", description: "Missing phone_number"))
                    waitUntil(timeout: Timeout) { done in
                        auth.passwordlessChallenge(phoneNumber: Phone, connection: ConnectionName).start { result in
                            expect(result).to(haveAuthenticationError(code: "invalid_request", description: "Missing phone_number"))
                            done()
                        }
                    }
                }

                it("should use DPoP when it is enabled") {
                    let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                    let request = auth.passwordlessChallenge(phoneNumber: Phone, connection: ConnectionName)
                    expect((request as? Request<PasswordlessChallenge, AuthenticationError>)?.dpop).toNot(beNil())
                }

                it("should not use DPoP when it is not enabled") {
                    let request = auth.passwordlessChallenge(phoneNumber: Phone, connection: ConnectionName)
                    expect((request as? Request<PasswordlessChallenge, AuthenticationError>)?.dpop).to(beNil())
                }

            }

            context("login with auth session and OTP") {

                it("should exchange auth session and OTP for credentials") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) &&
                        $0.hasAtLeast(["auth_session": AuthSession,
                                       "otp": OTP,
                                       "grant_type": PasswordlessGrantType,
                                       "client_id": ClientId])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(otp: OTP, challenge: PasswordlessChallenge(authSession: AuthSession)).start { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                    }
                }

                it("should include audience and scope when provided") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) &&
                        $0.hasAtLeast(["auth_session": AuthSession,
                                       "otp": OTP,
                                       "audience": Audience,
                                       "scope": Scope])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(otp: OTP, challenge: PasswordlessChallenge(authSession: AuthSession), audience: Audience, scope: Scope).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

                it("should not include audience by default") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasNoneOf(["audience"])
                    }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(otp: OTP, challenge: PasswordlessChallenge(authSession: AuthSession)).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

                it("should fail on invalid_grant") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) },
                                        response: authFailure(error: "invalid_grant", description: "Invalid OTP"))
                    waitUntil(timeout: Timeout) { done in
                        auth.login(otp: OTP, challenge: PasswordlessChallenge(authSession: AuthSession)).start { result in
                            expect(result).to(haveAuthenticationError(code: "invalid_grant", description: "Invalid OTP"))
                            done()
                        }
                    }
                }

                it("should use DPoP when it is enabled") {
                    let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                    let request = auth.login(otp: OTP, challenge: PasswordlessChallenge(authSession: AuthSession))
                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).toNot(beNil())
                }

                it("should not use DPoP when it is not enabled") {
                    let request = auth.login(otp: OTP, challenge: PasswordlessChallenge(authSession: AuthSession))
                    expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).to(beNil())
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

            it("should use DPoP when it is enabled") {
                let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                let request = auth.userInfo(withAccessToken: AccessToken)

                expect((request as? Request<UserProfile, AuthenticationError>)?.dpop).toNot(beNil())
            }

            it("should not use DPoP when it is not enabled") {
                let request = auth.userInfo(withAccessToken: AccessToken)

                expect((request as? Request<UserProfile, AuthenticationError>)?.dpop).to(beNil())
            }

            context("token type") {

                it("should return user information using a Bearer token") {
                    NetworkStub.addStub(condition: { $0.isUserInfo(Domain) && $0.hasBearerToken(AccessToken) },
                                        response: apiSuccessResponse(json: basicProfile()))
                    waitUntil(timeout: Timeout) { done in
                        auth.userInfo(withAccessToken: AccessToken, tokenType: "Bearer").start { result in
                            expect(result).to(haveProfile(Sub))
                            done()
                        }
                    }
                }

                it("should return user information using a DPoP token") {
                    NetworkStub.addStub(condition: { $0.isUserInfo(Domain) && $0.hasDPoPToken(AccessToken) },
                                        response: apiSuccessResponse(json: basicProfile()))
                    waitUntil(timeout: Timeout) { done in
                        auth.userInfo(withAccessToken: AccessToken, tokenType: "DPoP").start { result in
                            expect(result).to(haveProfile(Sub))
                            done()
                        }
                    }
                }

                it("should use Bearer as the default token type") {
                    NetworkStub.addStub(condition: { $0.isUserInfo(Domain) && $0.hasBearerToken(AccessToken) },
                                        response: apiSuccessResponse(json: basicProfile()))
                    waitUntil(timeout: Timeout) { done in
                        auth.userInfo(withAccessToken: AccessToken).start { result in
                            expect(result).to(haveProfile(Sub))
                            done()
                        }
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

            it("should use DPoP when it is enabled") {
                let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                let request = auth.codeExchange(withCode: code, codeVerifier: codeVerifier, redirectURI: redirectURI)

                expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).toNot(beNil())
            }

            it("should not use DPoP when it is not enabled") {
                let request = auth.codeExchange(withCode: code, codeVerifier: codeVerifier, redirectURI: redirectURI)

                expect((request as? TokenRequest<Credentials, AuthenticationError>)?.dpop).to(beNil())
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

            it("should use DPoP when it is enabled") {
                let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                let request = auth.ssoExchange(withRefreshToken: RefreshToken)

                expect((request as? TokenRequest<SSOCredentials, AuthenticationError>)?.dpop).toNot(beNil())
            }

            it("should not use DPoP when it is not enabled") {
                let request = auth.ssoExchange(withRefreshToken: RefreshToken)

                expect((request as? TokenRequest<SSOCredentials, AuthenticationError>)?.dpop).to(beNil())
            }

        }
        
        describe("customTokenExchange") {
            let subjectToken = "example-token"
            let subjectTokenType = "urn:ietf:params:oauth:token-type:jwt"
            let orgId = "org_id"
            
            it("should exchange custom token for credentials") {
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) && $0.hasAllOf([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": subjectToken,
                        "subject_token_type": subjectTokenType,
                        "scope": defaultScope,
                        "client_id": ClientId
                    ])
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                
                waitUntil(timeout: Timeout) { done in
                    auth.customTokenExchange(subjectToken: subjectToken,
                                           subjectTokenType: subjectTokenType)
                        .start { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                }
            }
            
            it("should exchange custom token with audience and scope") {
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) && $0.hasAllOf([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": subjectToken,
                        "subject_token_type": subjectTokenType,
                        "scope": "openid email",
                        "audience": Audience,
                        "client_id": ClientId
                    ])
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                
                waitUntil(timeout: Timeout) { done in
                    auth.customTokenExchange(subjectToken: subjectToken,
                                           subjectTokenType: subjectTokenType,
                                           audience: Audience,
                                           scope: "openid email")
                        .start { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                }
            }
            
            it("should exchange custom token with organization") {
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) && $0.hasAllOf([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": subjectToken,
                        "subject_token_type": subjectTokenType,
                        "scope": defaultScope,
                        "organization": orgId,
                        "client_id": ClientId
                    ])
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))
                
                waitUntil(timeout: Timeout) { done in
                    auth.customTokenExchange(subjectToken: subjectToken,
                                             subjectTokenType: subjectTokenType,
                                             organization: orgId)
                        .start { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                }
            }
            
            it("should produce authentication error") {
                let code = "invalid_grant"
                let description = "Invalid subject token"
                
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) && $0.hasAllOf([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": subjectToken,
                        "subject_token_type": subjectTokenType,
                        "scope": defaultScope,
                        "client_id": ClientId
                    ])
                }, response: authFailure(code: code, description: description))
                
                waitUntil(timeout: Timeout) { done in
                    auth.customTokenExchange(subjectToken: subjectToken,
                                           subjectTokenType: subjectTokenType)
                        .start { result in
                            expect(result).to(haveAuthenticationError(code: code, description: description))
                            done()
                        }
                }
            }

            it("should include custom parameters in the oauth/token request") {
                let customParam = "session_context"
                let deviceFingerprint = "a3d8f7xyz123"
                let extraParameters: [String: Any] = [
                    "custom_param": customParam,
                    "device_fingerprint": deviceFingerprint
                ]

                NetworkStub.addStub(condition: {
                    guard $0.isToken(Domain) else { return false }
                    guard $0.hasAtLeast([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": subjectToken,
                        "subject_token_type": subjectTokenType,
                        "client_id": ClientId
                    ]) else { return false }
                    return $0.hasAtLeast(extraParameters)
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))

                waitUntil(timeout: Timeout) { done in
                    auth.customTokenExchange(subjectToken: subjectToken,
                                            subjectTokenType: subjectTokenType,
                                            parameters: extraParameters)
                        .start { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                }
            }

            it("should exchange custom token with actor token") {
                let actor = ActorToken(token: "actor-id-token",
                                       tokenType: "urn:ietf:params:oauth:token-type:id_token")

                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) && $0.hasAllOf([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": subjectToken,
                        "subject_token_type": subjectTokenType,
                        "scope": defaultScope,
                        "actor_token": actor.token,
                        "actor_token_type": actor.tokenType,
                        "client_id": ClientId
                    ])
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))

                waitUntil(timeout: Timeout) { done in
                    auth.customTokenExchange(subjectToken: subjectToken,
                                            subjectTokenType: subjectTokenType,
                                            actorToken: actor)
                        .start { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                }
            }

            it("should not include actor token params when actorToken is nil") {
                NetworkStub.addStub(condition: {
                    guard $0.isToken(Domain) else { return false }
                    guard $0.hasAllOf([
                        "grant_type": TokenExchangeGrantType,
                        "subject_token": subjectToken,
                        "subject_token_type": subjectTokenType,
                        "scope": defaultScope,
                        "client_id": ClientId
                    ]) else { return false }
                    return $0.hasNoneOf(["actor_token", "actor_token_type"])
                }, response: authResponse(accessToken: AccessToken, idToken: IdToken))

                waitUntil(timeout: Timeout) { done in
                    auth.customTokenExchange(subjectToken: subjectToken,
                                            subjectTokenType: subjectTokenType)
                        .start { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
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

            it("should not use DPoP") {
                let auth = Auth0Authentication(clientId: ClientId, url: DomainURL).useDPoP()
                let request = auth.jwks()

                expect((request as? Request<JWKS, AuthenticationError>)?.dpop).to(beNil())
            }

        }

    }
}

#if PASSKEYS_PLATFORM

/// Records which requirements a ``LegacyAuthentication`` received.
private final class CallRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [String] = []

    var calls: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func record(_ call: String) {
        lock.lock()
        defer { lock.unlock() }
        recorded.append(call)
    }
}

/// An `Authentication` conformer written before `login(passkey:...verification:)` and
/// `passkeySignupChallenge(...deliveryMethod:)` existed: it implements every requirement except those two, so it gets
/// their default implementations. Only the two base requirements it receives are recorded and forwarded to a real client.
///
/// Generated from the protocol: when a requirement is added to `Authentication`, this type has to implement it too.
private struct LegacyAuthentication: Authentication {
    let wrapped: any Authentication
    let recorder: CallRecorder
    var dpop: DPoP?
    var auth0ClientInfo = Auth0ClientInfo()
    var logger: Logger?

    let clientId = "CLIENT_ID"
    let url = URL(string: "http://passkeystestdomain.acmetest.org")!
    func login(email: String, code: String, audience: String?, scope: String) -> any TokenRequestable<Credentials, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func login(phoneNumber: String, code: String, audience: String?, scope: String) -> any TokenRequestable<Credentials, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func login(usernameOrEmail username: String, password: String, realmOrConnection realm: String, audience: String?, scope: String) -> any TokenRequestable<Credentials, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func login(appleAuthorizationCode authorizationCode: String,
               fullName: PersonNameComponents?,
               profile: [String: Any]?,
               audience: String?,
               scope: String) -> any TokenRequestable<Credentials, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func login(facebookSessionAccessToken sessionAccessToken: String,
               profile: [String: Any],
               audience: String?,
               scope: String) -> any TokenRequestable<Credentials, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func loginDefaultDirectory(withUsername username: String, password: String, audience: String?, scope: String) -> any TokenRequestable<Credentials, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func signup(email: String, username: String?, password: String, connection: String, userMetadata: [String: Any]?, rootAttributes: [String: Any]?) -> any Requestable<DatabaseUser, AuthenticationError> {
        fatalError("Not used by this test")
    }
    #if PASSKEYS_PLATFORM
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func login(passkey: LoginPasskey,
               challenge: PasskeyLoginChallenge,
               connection: String?,
               audience: String?,
               scope: String,
               organization: String?) -> any TokenRequestable<Credentials, AuthenticationError> {
        fatalError("Not used by this test")
    }
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyLoginChallenge(connection: String?,
                               organization: String?) -> any Requestable<PasskeyLoginChallenge, AuthenticationError> {
        fatalError("Not used by this test")
    }
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func login(passkey: SignupPasskey,
               challenge: PasskeySignupChallenge,
               connection: String?,
               audience: String?,
               scope: String,
               organization: String?) -> any TokenRequestable<Credentials, AuthenticationError> {
        recorder.record("login(passkey:challenge:connection:audience:scope:organization:)")
        return wrapped.login(passkey: passkey, challenge: challenge, connection: connection, audience: audience, scope: scope, organization: organization)
    }
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeySignupChallenge(email: String?,
                                phoneNumber: String?,
                                username: String?,
                                name: String?,
                                givenName: String?,
                                familyName: String?,
                                nickname: String?,
                                picture: String?,
                                userMetadata: [String: String]?,
                                connection: String?,
                                organization: String?) -> any Requestable<PasskeySignupChallenge, AuthenticationError> {
        recorder.record("passkeySignupChallenge(...organization:)")
        return wrapped.passkeySignupChallenge(email: email, phoneNumber: phoneNumber, username: username, name: name, givenName: givenName, familyName: familyName, nickname: nickname, picture: picture, userMetadata: userMetadata, connection: connection, organization: organization)
    }
    #endif
    func resetPassword(email: String, connection: String, organization: String?) -> any Requestable<Void, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func startPasswordless(email: String, type: PasswordlessType, connection: String) -> any Requestable<Void, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func startPasswordless(phoneNumber: String, type: PasswordlessType, connection: String) -> any Requestable<Void, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func userInfo(withAccessToken accessToken: String, tokenType: String) -> any Requestable<UserProfile, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func codeExchange(withCode code: String, codeVerifier: String, redirectURI: String) -> any TokenRequestable<Credentials, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func ssoExchange(withRefreshToken refreshToken: String) -> any TokenRequestable<SSOCredentials, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func renew(withRefreshToken refreshToken: String, audience: String?, scope: String?) -> any TokenRequestable<Credentials, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func revoke(refreshToken: String) -> any Requestable<Void, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func jwks() -> any Requestable<JWKS, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func customTokenExchange(subjectToken: String,
                             subjectTokenType: String,
                             audience: String?,
                             scope: String,
                             organization: String?,
                             parameters: [String: Any]) -> any TokenRequestable<Credentials, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func passwordlessChallenge(email: String, connection: String, allowSignup: Bool) -> any Requestable<PasswordlessChallenge, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func passwordlessChallenge(phoneNumber: String, connection: String, deliveryMethod: DeliveryMethod, allowSignup: Bool) -> any Requestable<PasswordlessChallenge, AuthenticationError> {
        fatalError("Not used by this test")
    }
    func login(otp: String, challenge: PasswordlessChallenge, audience: String?, scope: String) -> any TokenRequestable<Credentials, AuthenticationError> {
        fatalError("Not used by this test")
    }
}

#endif
