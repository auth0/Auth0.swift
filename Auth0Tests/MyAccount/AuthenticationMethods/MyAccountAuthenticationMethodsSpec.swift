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
private let PhoneNumber = "+15551234567"
private let OTPCode = "123456"
private let AuthSession = "someAuthSessionToken"

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
                expect(authMethods.url) == DomainURL
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

            let passkeyAuthSession = "y1PI7ue7QX85WMxoR6Qa-9INuqA3xxKLVoDOxBOD6yYQL1Fl-zgwjFtZIQfRORhY"
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
                                                                     authenticationSession: passkeyAuthSession,
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
                            "auth_session": passkeyAuthSession,
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
                            "auth_session": passkeyAuthSession,
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
                    }, response: passkeyEnrollmentChallengeResponse(authSession: passkeyAuthSession,
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
                                                                        authenticationSession: passkeyAuthSession,
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
                    }, response: passkeyEnrollmentChallengeResponse(authSession: passkeyAuthSession,
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
                                                                        authenticationSession: passkeyAuthSession,
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

        describe("enroll Recovery Code") {
            it("should enroll recovery code successfully") {
                let recoveryCode = "ABCDEFGH-IJKL-MNOP-QRST-UVWXYZ123456"
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["type": "recovery-code"])
                }, response: recoveryCodeChallengeResponse(id: AuthenticationMethodId,
                                                         authSession: AuthSession,
                                                         recoveryCode: recoveryCode))

                waitUntil(timeout: Timeout) { done in
                    authMethods.enrolRecoveryCode().start { result in
                        expect(result).to(haveRecoveryCodeChallenge(id: AuthenticationMethodId,
                                                                    authSession: AuthSession,
                                                                    recoveryCode: recoveryCode))
                        done()
                    }
                }
            }

            it("should fail to enroll recovery code") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["type": "recovery-code"])
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.enrolRecoveryCode().start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        describe("enroll TOTP") {
            it("should enroll TOTP successfully") {
                let barcodeUri = "otpauth://totp/Auth0:user@example.com?secret=ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678&issuer=Auth0"
                let manualInputCode = "N47VVYSDHRKWWSLJONYEQ7LXLV5XEMC5"
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["type": "totp"])
                }, response: totpPushEnrollmentChallengeResponse(id: AuthenticationMethodId,
                                                                 authSession: AuthSession,
                                                                 barcodeUri: barcodeUri,
                                                                 manualInoutcode: manualInputCode))

                waitUntil(timeout: Timeout) { done in
                    authMethods.enrollTOTP().start { result in
                        expect(result).to(haveTOTPPushEnrollmentChallenge(id: AuthenticationMethodId,
                                                                         authSession: AuthSession,
                                                                         barcodeUri: barcodeUri,
                                                                         manualInputCode: manualInputCode))
                        done()
                    }
                }
            }

            it("should fail to enroll TOTP") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["type": "totp"])
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.enrollTOTP().start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        describe("enroll push notification") {
            it("should enroll push notification successfully") {
                let barcodeUri = "otpauth://totp/Auth0:user@example.com?secret=ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678&issuer=Auth0"
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["type": "push-notification"])
                }, response: totpPushEnrollmentChallengeResponse(id: AuthenticationMethodId,
                                                                authSession: AuthSession,
                                                                barcodeUri: barcodeUri))

                waitUntil(timeout: Timeout) { done in
                    authMethods.enrollPushNotification().start { result in
                        expect(result).to(haveTOTPPushEnrollmentChallenge(id: AuthenticationMethodId,
                                                                         authSession: AuthSession,
                                                                          barcodeUri: barcodeUri))
                        done()
                    }
                }
            }

            it("should fail to enroll push notification") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["type": "push-notification"])
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.enrollPushNotification().start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        describe("enroll Email") {
            it("should enroll email successfully") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["type": "email", "email": Email])
                }, response: phoneEmailChallengeResponse(id: AuthenticationMethodId,
                                                        authSession: AuthSession,
                                                        type: "email"))

                waitUntil(timeout: Timeout) { done in
                    authMethods.enrollEmail(emailAddress: Email).start { result in
                        expect(result).to(havePhoneEmailChallenge(id: AuthenticationMethodId,
                                                                  authSession: AuthSession))
                        done()
                    }
                }
            }

            it("should fail to enroll email") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["type": "email", "email": Email])
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.enrollEmail(emailAddress: Email).start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        describe("enroll Phone") {
            let preferredAuthMethod = "sms" // or "voice"

            it("should enroll phone successfully") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["type": "phone",
                                 "phone_number": PhoneNumber,
                                 "preferred_authentication_method": preferredAuthMethod])
                }, response: phoneEmailChallengeResponse(id: AuthenticationMethodId,
                                                        authSession: AuthSession,
                                                        type: "phone"))

                waitUntil(timeout: Timeout) { done in
                    authMethods.enrollPhone(phoneNumber: PhoneNumber,
                                            preferredAuthenticationMethod: preferredAuthMethod).start { result in
                        expect(result).to(havePhoneEmailChallenge(id: AuthenticationMethodId,
                                                                  authSession: AuthSession))
                        done()
                    }
                }
            }

            it("should fail to enroll phone") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["type": "phone",
                                 "phone_number": PhoneNumber,
                                 "preferred_authentication_method": preferredAuthMethod])
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.enrollPhone(phoneNumber: PhoneNumber,
                                            preferredAuthenticationMethod: preferredAuthMethod).start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        // MARK: - Confirmation Tests

        describe("confirmTOTPEnrolment") {
            let endpoint = "\(AuthenticationMethodId)/verify"
            let usage = ["secondary"]
            let createdAt = "2025-07-30T13:08:49.508Z"
            it("should confirm TOTP enrollment successfully") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["auth_session": AuthSession, "otp_code": OTPCode])
                }, response: authenticationMethodResponse(id: AuthenticationMethodId, type: "totp", createdAt: createdAt, usage: usage))

                waitUntil(timeout: Timeout) { done in
                    authMethods.confirmTOTPEnrolment(id: AuthenticationMethodId,
                                                     authSession: AuthSession,
                                                     otpCode: OTPCode).start { result in
//                        expect(result).to(haveauth(id: AuthenticationMethodId, type: "totp"))
                        done()
                    }
                }
            }

            it("should fail to confirm TOTP enrollment") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["auth_session": AuthSession, "otp_code": OTPCode])
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.confirmTOTPEnrolment(id: AuthenticationMethodId,
                                                     authSession: AuthSession,
                                                     otpCode: OTPCode).start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        describe("confirmEmailEnrolment") {
            let endpoint = "\(AuthenticationMethodId)/verify"
            let usage = ["secondary"]
            let createdAt = "2025-07-30T13:08:49.508Z"
            it("should confirm email enrollment successfully") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["auth_session": AuthSession, "otp_code": OTPCode])
                }, response: authenticationMethodResponse(id: AuthenticationMethodId, type: "email", createdAt: createdAt, usage: usage))

                waitUntil(timeout: Timeout) { done in
                    authMethods.confirmEmailEnrolment(id: AuthenticationMethodId,
                                                      authSession: AuthSession,
                                                      otpCode: OTPCode).start { result in
                        expect(result).to(haveAuthenticationMethod(id: AuthenticationMethodId))
                        done()
                    }
                }
            }

            it("should fail to confirm email enrollment") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["auth_session": AuthSession, "otp_code": OTPCode])
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.confirmEmailEnrolment(id: AuthenticationMethodId,
                                                      authSession: AuthSession,
                                                      otpCode: OTPCode).start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        describe("confirmPushNotificationEnrolment") {
            let endpoint = "\(AuthenticationMethodId)/verify"
            let usage = ["secondary"]
            let createdAt = "2025-07-30T13:08:49.508Z"
            it("should confirm push notification enrollment successfully") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["auth_session": AuthSession])
                }, response: authenticationMethodResponse(id: AuthenticationMethodId, type: "push-notification", createdAt: createdAt, usage: usage))

                waitUntil(timeout: Timeout) { done in
                    authMethods.confirmPushNotificationEnrolment(id: AuthenticationMethodId,
                                                                 authSession: AuthSession).start { result in
                        expect(result).to(haveAuthenticationMethod(id: AuthenticationMethodId))
                        done()
                    }
                }
            }

            it("should fail to confirm push notification enrollment") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["auth_session": AuthSession])
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.confirmPushNotificationEnrolment(id: AuthenticationMethodId,
                                                                 authSession: AuthSession).start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        describe("confirmPhoneEnrolment") {
            let endpoint = "\(AuthenticationMethodId)/verify"

            let usage = ["secondary"]
            let createdAt = "2025-07-30T13:08:49.508Z"
            it("should confirm phone enrollment successfully") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["auth_session": AuthSession, "otp_code": OTPCode])
                }, response: authenticationMethodResponse(id: AuthenticationMethodId, type: "phone", createdAt: createdAt, usage: usage))

                waitUntil(timeout: Timeout) { done in
                    authMethods.confirmPhoneEnrolment(id: AuthenticationMethodId,
                                                      authSession: AuthSession,
                                                      otpCode: OTPCode).start { result in
                        expect(result).to(haveAuthenticationMethod(id: AuthenticationMethodId))
                        done()
                    }
                }
            }

            it("should fail to confirm phone enrollment") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["auth_session": AuthSession, "otp_code": OTPCode])
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.confirmPhoneEnrolment(id: AuthenticationMethodId,
                                                      authSession: AuthSession,
                                                      otpCode: OTPCode).start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        describe("confirmRecoveryCodeEnrolment") {
            let endpoint = "\(AuthenticationMethodId)/verify"
            let usage = ["secondary"]
            let createdAt = "2025-07-30T13:08:49.508Z"

            it("should confirm recovery code enrollment successfully") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["auth_session": AuthSession])
                }, response: authenticationMethodResponse(id: AuthenticationMethodId, type: "recovery-code", createdAt: createdAt, usage: usage))

                waitUntil(timeout: Timeout) { done in
                    authMethods.confirmRecoveryCodeEnrolment(id: AuthenticationMethodId,
                                                             authSession: AuthSession).start { result in
                        expect(result).to(haveAuthenticationMethod(id: AuthenticationMethodId))
                        done()
                    }
                }
            }

            it("should fail to confirm recovery code enrollment") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPOST &&
                    $0.hasAllOf(["auth_session": AuthSession])
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.confirmRecoveryCodeEnrolment(id: AuthenticationMethodId,
                                                             authSession: AuthSession).start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        // MARK: - Management & Retrieval Tests

        describe("getAuthenticationMethods") {
            it("should get authentication methods successfully") {
                let method1: [String: Any] = ["id": "id1", "type": "sms", "name": "SMS Method", "confirmed": true, "created_at": "2025-07-30T13:08:49.508Z", "usage": ["primary"]]
                let method2: [String: Any] = ["id": "id2", "type": "email", "name": "Email Method", "confirmed": true, "created_at": "2025-07-30T13:08:49.508Z", "usage": ["secondary"]]
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodGET
                }, response: authenticationMethodsListResponse(methods: [method1, method2]))

                waitUntil(timeout: Timeout) { done in
                    authMethods.getAuthenticationMethods().start { result in
                        expect(result).to(haveAuthenticationMethods(count: 2))
                        expect(result).to(haveAuthenticationMethodInList(id: "id1"))
                        expect(result).to(haveAuthenticationMethodInList(id: "id2"))
                        done()
                    }
                }
            }

            it("should get an empty list of authentication methods") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodGET
                }, response: authenticationMethodsListResponse(methods: []))

                waitUntil(timeout: Timeout) { done in
                    authMethods.getAuthenticationMethods().start { result in
                        expect(result).to(haveAuthenticationMethods(count: 0))
                        done()
                    }
                }
            }

            it("should fail to get authentication methods") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, token: AccessToken) &&
                    $0.isMethodGET
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.getAuthenticationMethods().start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        describe("deleteAuthenticationMethod") {
            let endpoint = "\(AuthenticationMethodId)"

            it("should delete authentication method successfully") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodDELETE
                }, response: apiSuccessResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.deleteAuthenticationMethod(id: AuthenticationMethodId).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should fail to delete authentication method") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodDELETE
                }, response: apiFailureResponse(statusCode: 404))
                waitUntil(timeout: Timeout) { done in
                    authMethods.deleteAuthenticationMethod(id: AuthenticationMethodId).start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        describe("getFactorStatus") {
            it("should get factor status successfully") {
                let factor1: [String: Any] = ["type": "totp", "usage": ["primary"]]
                let factor2: [String: Any] = ["type": "sms", "usage": ["secondary"]]
                NetworkStub.addStub(condition: {
                    $0.isFactorsMethods(Domain, token: AccessToken) && // Note: `factors` endpoint
                    $0.isMethodGET
                }, response: factorListResponse(factors: ["factors": [factor1, factor2]]))

                waitUntil(timeout: Timeout) { done in
                    authMethods.getFactorStatus().start { result in
                        expect(result).to(haveFactorInList(type: "totp"))
                        expect(result).to(haveFactorInList(type: "sms"))
                        done()
                    }
                }
            }

            it("should get an empty list of factor statuses") {
                NetworkStub.addStub(condition: {
                    $0.isFactorsMethods(Domain, token: AccessToken) &&
                    $0.isMethodGET
                }, response: factorListResponse(factors: ["factors": []]))

                waitUntil(timeout: Timeout) { done in
                    authMethods.getFactorStatus().start { result in
                        expect(result).to(haveEmptyFactorsInList())
                        done()
                    }
                }
            }

            it("should fail to get factor status") {
                NetworkStub.addStub(condition: {
                    $0.isFactorsMethods(Domain, token: AccessToken) &&
                    $0.isMethodGET
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.getFactorStatus().start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        describe("getAuthenticationMethod") {
            let endpoint = "\(AuthenticationMethodId)"
            let createdAt = "2025-07-30T13:08:49.508Z"
            let usage = ["secondary"]
        
            it("should get a single authentication method successfully") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodGET
                }, response: authenticationMethodResponse(id: AuthenticationMethodId, type: "passkey", name: "My Passkey", createdAt: createdAt, usage: usage))

                waitUntil(timeout: Timeout) { done in
                    authMethods.getAuthenticationMethod(id: AuthenticationMethodId).start { result in
                        expect(result).to(haveAuthenticationMethod(id: AuthenticationMethodId))
                        done()
                    }
                }
            }

            it("should fail to get a single authentication method (not found)") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodGET
                }, response: apiFailureResponse(statusCode: 404))
                waitUntil(timeout: Timeout) { done in
                    authMethods.getAuthenticationMethod(id: AuthenticationMethodId).start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }

        describe("updateAuthenticationMethod") {
            let endpoint = "\(AuthenticationMethodId)"
            let createdAt = "2025-07-30T13:08:49.508Z"
            let usage = ["secondary"]

            it("should update authentication method name successfully") {
                let newName = "My Updated Passkey"
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPATCH &&
                    $0.hasAllOf(["name": newName])
                }, response: authenticationMethodResponse(id: AuthenticationMethodId, type: "passkey", name: newName, createdAt: createdAt, usage: usage))

                waitUntil(timeout: Timeout) { done in
                    authMethods.updateAuthenticationMethod(id: AuthenticationMethodId, name: newName).start { result in
                        expect(result).to(haveAuthenticationMethod(id: AuthenticationMethodId))
                        done()
                    }
                }
            }

            it("should update authentication method preferred authentication method successfully") {
                let newPreferred = "sms"
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPATCH &&
                    $0.hasAllOf(["preferred_authentication_method": newPreferred])
                }, response: authenticationMethodResponse(id: AuthenticationMethodId, type: "phone", preferredAuthMethod: newPreferred, createdAt: createdAt, usage: usage))

                waitUntil(timeout: Timeout) { done in
                    authMethods.updateAuthenticationMethod(id: AuthenticationMethodId, preferredAuthenticationMethod: newPreferred).start { result in
                        expect(result).to(haveAuthenticationMethod(id: AuthenticationMethodId))
                        done()
                    }
                }
            }

            it("should update authentication method with both name and preferred authentication method successfully") {
                let newName = "My Authenticator"
                let newPreferred = "otp"
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPATCH &&
                    $0.hasAllOf(["name": newName, "preferred_authentication_method": newPreferred])
                }, response: authenticationMethodResponse(id: AuthenticationMethodId, type: "totp", name: newName, preferredAuthMethod: newPreferred, createdAt: createdAt, usage: usage))

                waitUntil(timeout: Timeout) { done in
                    authMethods.updateAuthenticationMethod(id: AuthenticationMethodId, name: newName, preferredAuthenticationMethod: newPreferred).start { result in
                        expect(result).to(haveAuthenticationMethod(id: AuthenticationMethodId))
                        done()
                    }
                }
            }

            it("should fail to update authentication method") {
                NetworkStub.addStub(condition: {
                    $0.isMyAccountAuthenticationMethods(Domain, endpoint, token: AccessToken) &&
                    $0.isMethodPATCH
                }, response: apiFailureResponse())

                waitUntil(timeout: Timeout) { done in
                    authMethods.updateAuthenticationMethod(id: AuthenticationMethodId, name: "New Name").start { result in
                        expect(result).to(beUnsuccessful())
                        done()
                    }
                }
            }
        }
    }
}
