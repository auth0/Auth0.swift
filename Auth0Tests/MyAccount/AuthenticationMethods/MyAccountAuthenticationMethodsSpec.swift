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
private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let AuthenticationMethodId = "PASSKEY_ID"
private let Connection = "Username-Password-Authentication"
private let Email = "user@example.com"
private let Timeout: NimbleTimeInterval = .seconds(2)

class MyAccountAuthenticationMethodsSpec: QuickSpec {
    override class func spec() {

        let myAccount = myAccount(token: AccessToken, domain: Domain)
        let authMethods = myAccount.authenticationMethods

        beforeEach {
            URLProtocol.registerClass(StubURLProtocol.self)
        }

        afterEach {
            NetworkStub.clearStubs()
            URLProtocol.unregisterClass(StubURLProtocol.self)
        }

        describe("init") {

            it("should init with token and url") {
                let authMethods = Auth0MyAccountAuthenticationMethods(token: AccessToken, url: DomainURL)
                expect(authMethods.token) == AccessToken
                expect(authMethods.url) == DomainURL.appending("authentication-methods")
            }

            it("should init with token, url, and session") {
                let session = URLSession(configuration: URLSession.shared.configuration)
                let authMethods = Auth0MyAccountAuthenticationMethods(token: AccessToken,
                                                                      url: DomainURL,
                                                                      session: session)
                expect(authMethods.session).to(be(session))
            }

            it("should init with token, url, and telemetry") {
                let telemetryInfo = "info"
                var telemetry = Telemetry()
                telemetry.info = telemetryInfo
                let authMethods = Auth0MyAccountAuthenticationMethods(token: AccessToken,
                                                                      url: DomainURL,
                                                                      telemetry: telemetry)
                expect(authMethods.telemetry.info) == telemetryInfo
            }

        }

        #if PASSKEYS_PLATFORM
        if #available(iOS 16.6, macOS 13.5, visionOS 1.0, *) {
            struct MockNewPasskey: NewPasskey {
                let credentialID: Data
                let attachment: ASAuthorizationPublicKeyCredentialAttachment = .platform
                let rawAttestationObject: Data?
                let rawClientDataJSON: Data
            }

            let authSession = "y1PI7ue7QX85WMxoR6Qa-9INuqA3xxKLVoDOxBOD6yYQL1Fl-zgwjFtZIQfRORhY"
            let userId = "LcICuavHdO2zbcA8zRgnTRIkzPrruI_HQqe0J3RL0ou5VSrWhRybCQqyNMXWj1LDdxOzat6KVf9xpW3qLw5qjw"
            let userIdData = userId.a0_decodeBase64URLSafe()!
            let userIdentityId = "681359da4a20c7993310ff1d"
            let challenge = "L4SaSxx8tpqrScT_hbpZX-50qfKh12_oxmSUIKSGFpM"
            let challengeData = challenge.a0_decodeBase64URLSafe()!

            describe("enroll passkey") {

                let endpoint = "\(AuthenticationMethodId)/verify"
                let credentialId = "mXTk10IfDhdxZnJltERtBRyNUkE"
                let credentialType = "public-key"
                let authenticatorAttachment = "platform"
                let attestationObject = "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YViYlDH4SiOEQFwNz4z4dy3yWLJ5CkueUJPzpqu" +
                "lBxP_X_9dAAAAAPv8MAcVTk7MjAtuAgVX170AFJl05NdCHw4XcWZyZbREbQUcjVJBpQECAyYgASFYII53hB2t9eUcxo6B4PdeSa" +
                "WKQCb-sQRSSJIsSl1iXE6VIlgg9SFUiFdAPMrCwC-RQaNKVwNrMFzsRkiu0Djz-GPjDfA"
                let clientData = "eyJ0eXBlIjoid2ViYXV0aG4uY3JlYXRlIiwiY2hhbGxlbmdlIjoiTDRTYVN4eDh0cHFyU2NUX2hicFpYLT" +
                "UwcWZLaDEyX294bVNVSUtTR0ZwTSIsIm9yaWdpbiI6Imh0dHBzOi8vbG9naW4ud2lkY2tldC5jb20ifQ-MN8A"

                let newPasskey = MockNewPasskey(credentialID: credentialId.a0_decodeBase64URLSafe()!,
                                                rawAttestationObject: attestationObject.a0_decodeBase64URLSafe(),
                                                rawClientDataJSON: clientData.a0_decodeBase64URLSafe()!)
                let enrollmentChallenge = PasskeyEnrollmentChallenge(authenticationMethodId: AuthenticationMethodId,
                                                                     authenticationSession: authSession,
                                                                     relyingPartyId: Domain,
                                                                     userId: userIdData,
                                                                     userName: Email,
                                                                     challengeData: challengeData)

                it("should enroll passkey") {
                    let publicKey = "pQECAyYgASFYIGK0OMbKXIHgb1Es/MrVoCTrGDzi96vGxUpAGJOhUOp4IlggxIbnS81JDZHWv+NZtWV" +
                    "7wMzbg7sTOJbACvk7xY6DE7A="
                    let publicKeyData = Data(base64Encoded: publicKey)!
                    let createdAt = "2025-05-15T13:29:32.321Z"
                    let createdAtDateFormatter = ISO8601DateFormatter()
                    createdAtDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    let createdAtDate = createdAtDateFormatter.date(from: createdAt)!

                    NetworkStub.addStub(condition: {
                        $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                        $0.isMethodPOST &&
                        $0.hasAtLeast([
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
                    }, response: passkeyAuthenticationMethodResponse(id: AuthenticationMethodId,
                                                                     userIdentityId: userIdentityId,
                                                                     userHandle: userId,
                                                                     keyId: credentialId,
                                                                     publicKey: publicKey,
                                                                     credentialDeviceType: .singleDevice,
                                                                     createdAt: createdAt))

                    waitUntil(timeout: Timeout) { done in
                        authMethods
                            .enroll(passkey: newPasskey, challenge: enrollmentChallenge)
                            .start { result in
                                expect(result)
                                    .to(havePasskeyAuthenticationMethod(id: AuthenticationMethodId,
                                                                        userIdentityId: userIdentityId,
                                                                        credentialId: credentialId,
                                                                        credentialPublicKey: publicKeyData,
                                                                        credentialUserHandle: userIdData,
                                                                        credentialDeviceType: .singleDevice,
                                                                        createdAt: createdAtDate))
                                done()
                            }
                    }
                }

                it("should fail to enroll passkey") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                        $0.isMethodPOST &&
                        $0.hasAtLeast([
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
                    }, response: apiFailureResponse())

                    waitUntil(timeout: Timeout) { done in
                        authMethods
                            .enroll(passkey: newPasskey, challenge: enrollmentChallenge)
                            .start { result in
                                expect(result).to(beUnsuccessful())
                                done()
                            }
                    }
                }

            }

            describe("passkey enrollment challenge") {

                let locationHeader = "https://example.com/foo/\(AuthenticationMethodId)"

                it("should request passkey enrollment challenge with default parameters") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                        $0.isMethodPOST &&
                        $0.hasAllOf(["type": "passkey"])
                    }, response: passkeyEnrollmentChallengeResponse(authSession: authSession,
                                                                    rpId: Domain,
                                                                    userId: userId,
                                                                    userName: Email,
                                                                    challenge: challenge,
                                                                    headers: ["Location": locationHeader]))

                    waitUntil(timeout: Timeout) { done in
                        authMethods
                            .passkeyEnrollmentChallenge()
                            .start { result in
                                expect(result)
                                    .to(havePasskeyEnrollmentChallenge(authenticationMethodId: AuthenticationMethodId,
                                                                       authenticationSession: authSession,
                                                                       relyingPartyId: Domain,
                                                                       userId: userIdData,
                                                                       userName: Email,
                                                                       challengeData: challengeData))
                                done()
                            }
                    }
                }

                it("should request passkey signup challenge with all parameters") {
                    let identityUserId = "681359da4a20c7993310ff1d"

                    NetworkStub.addStub(condition: {
                        $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                        $0.isMethodPOST &&
                        $0.hasAllOf([
                            "type": "passkey",
                            "connection": Connection,
                            "identity_user_id": identityUserId
                        ])
                    }, response: passkeyEnrollmentChallengeResponse(authSession: authSession,
                                                                    rpId: Domain,
                                                                    userId: userId,
                                                                    userName: Email,
                                                                    challenge: challenge,
                                                                    headers: ["Location": locationHeader]))

                    waitUntil(timeout: Timeout) { done in
                        authMethods
                            .passkeyEnrollmentChallenge(userIdentityId: identityUserId, connection: Connection)
                            .start { result in
                                expect(result)
                                    .to(havePasskeyEnrollmentChallenge(authenticationMethodId: AuthenticationMethodId,
                                                                       authenticationSession: authSession,
                                                                       relyingPartyId: Domain,
                                                                       userId: userIdData,
                                                                       userName: Email,
                                                                       challengeData: challengeData))
                                done()
                            }
                    }

                }

                it("should fail to request passkey signup challenge") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                        $0.isMethodPOST &&
                        $0.hasAllOf(["type": "passkey"])
                    }, response: apiFailureResponse())

                    waitUntil(timeout: Timeout) { done in
                        authMethods
                            .passkeyEnrollmentChallenge()
                            .start { result in
                                expect(result).to(beUnsuccessful())
                                done()
                            }
                    }

                }

            }

        }
        #endif

    }
}
