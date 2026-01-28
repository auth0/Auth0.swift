import Testing
import Foundation
@testable import Auth0

@Suite(.serialized)
struct Auth0MFAClientTests {
    private let mockToken = "mock_access_token_123"
    private let mockDomain = "test-tenant.auth0.com"

    private func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    // MARK: - Mock Data

    var phoneEnrollmentChallengeWithRecoveryCode: Data {
        return """
        {
            "authenticator_type": "oob",
            "recovery_codes": ["G14KWJB572GUSD2T3NJV625L"],
            "oob_channel": "sms",
            "oob_code": "Fe26.2*SERVER_1767928705*daa9fa2ffcba664cb93f89206cfc54723a0b5519c9ecda29298a6df21adf4004*M41PongaBqP2XZJTn8sUVQ*mwLS8id8uwaqNyHA_JVHNVrNnzeoWTCKXx111mw771EhvKeqh2A_pn6a6__D4frkELpahaioDomAeRs9Hmmx9_ZblTXdylNzDS-RSCwKtGUj6py2ZlcShIJcDNJSYXiQwb-9j7GgS0DbTyNiqRiSm--CZK_RvR68D8RdcQGMhib64vmXzCM92q_SUVDbhyvDmFi9m2_RioWpa8EahpAbXmf-AwP4mBLIZkslMOjfu8j5OMgCt3KYLyhT4zC_4kA-y3FptIHrrRnqAB3SQoJXJzi4Cu2CxWIZ_sydIPZUm7MI2YfHYOQLMSC5oGGNIVWSmG3pU4Vwxmg8-GIO0FQ2TeBzOF1lm4I1-ITSeLMBsXy6HrglyLsppa56tCHKqBVV*1768202403647*8c706fc66eb5cc3481ab2d351aafb2d15be9ac44c509d593bea0c4aa86bd515a*6kDRUDe5YrFkX1kstD2hZC2f4tMS8mT_LO9cjhNnNRY",
            "binding_method": "prompt"
        }
        """.data(using: .utf8)!
    }

    var phoneEnrollmentChallengeWithoutRecoveryCode: Data {
        return """
        {
            "authenticator_type": "oob",
            "oob_channel": "sms",
            "oob_code": "Fe26.2*SERVER_1767928705*daa9fa2ffcba664cb93f89206cfc54723a0b5519c9ecda29298a6df21adf4004*M41PongaBqP2XZJTn8sUVQ*mwLS8id8uwaqNyHA_JVHNVrNnzeoWTCKXx111mw771EhvKeqh2A_pn6a6__D4frkELpahaioDomAeRs9Hmmx9_ZblTXdylNzDS-RSCwKtGUj6py2ZlcShIJcDNJSYXiQwb-9j7GgS0DbTyNiqRiSm--CZK_RvR68D8RdcQGMhib64vmXzCM92q_SUVDbhyvDmFi9m2_RioWpa8EahpAbXmf-AwP4mBLIZkslMOjfu8j5OMgCt3KYLyhT4zC_4kA-y3FptIHrrRnqAB3SQoJXJzi4Cu2CxWIZ_sydIPZUm7MI2YfHYOQLMSC5oGGNIVWSmG3pU4Vwxmg8-GIO0FQ2TeBzOF1lm4I1-ITSeLMBsXy6HrglyLsppa56tCHKqBVV*1768202403647*8c706fc66eb5cc3481ab2d351aafb2d15be9ac44c509d593bea0c4aa86bd515a*6kDRUDe5YrFkX1kstD2hZC2f4tMS8mT_LO9cjhNnNRY",
            "binding_method": "prompt"
        }
        """.data(using: .utf8)!
    }

    var challengeData: Data {
        return """
        {
            "challenge_type": "oob",
            "oob_code": "Fe26.2*SERVER_1767928705*c07b491097a63f380a635dcd122f3191e10a671f8a136e53d261d3a99e53abc1*YVe_7o7SbFNURbjXSQzTEg*1BDWU0i-IO1kE_WRLjHcXQhszHgoQcVKsHAniyWMnOaUwRxTc5uKlfoWz2poYwS2cwFPbf868KFmAshTlXlytlQe4uGvLBkwjwdAYL8VL2BwV9e2rDtoqBCAgP4qESzLiNWuN8vRN_eddsG7mrfmEkz3t_k7LNYTHLIkyC1zgTLww4QVbsHwHGL3TvBu1U3xvzMQ_Abv3xbnLtIrWcZbMzxe-JXRQ5Fw9-pD5zx6-2xeU3zcBzUQ2SQSC_cs5fuwzUzKm7TiMAE2kGV_EJ_8UmAoc6yPnRAvudm2kNvY_G6jfuzriqsV8mhfJVrCKM8dQGwwnMye1Nqe9tavMs9Tk7bm6KEjEAYk7x6CepdIeVajtlpjlef_Mwwn02nuK_pC*1768216113061*a7b60435bf02e470f56767477678fb852edb9c032d8e1528f64b003078286a11*tfFIO4_1BFvlNdzs5s7mKjW6ajvrlkBF7HUrGur9VIk",
            "binding_method": "prompt"
        }
        """.data(using: .utf8)!
    }

    var authenticatorsData: Data {
        return """
        [
            {
                "authenticator_type": "oob",
                "id": "sms|dev_WNScJzYAmuV1enCR",
                "active": true,
                "oob_channel": "sms",
                "name": "XXXXXXXXX2046",
                "type": "phone"
            },
            {
                "authenticator_type": "oob",
                "id": "voice|dev_WNScJzYAmuV1enCR",
                "active": true,
                "oob_channel": "voice",
                "name": "XXXXXXXXX2046",
                "type": "phone"
            },
            {
                "id": "recovery-code|dev_ZdXKDYctdGHWWAN5",
                "authenticator_type": "recovery-code",
                "active": true,
                "type": "recovery-code"
            },
            {
                "authenticator_type": "oob",
                "id": "email|dev_6fOgD5yp5UMV52Ns",
                "active": true,
                "oob_channel": "email",
                "name": "example******@gmai*****", 
                "type": "email"
            }
        ]
        """.data(using: .utf8)!
    }

    var otpEnrollmentChallengeWithRecoveryCodes: Data {
        return """
        {
            "authenticator_type": "otp",
            "secret": "ABCDEFGHIJKLMNOP",
            "barcode_uri": "otpauth://totp/Auth0:user@example.com?secret=ABCDEFGHIJKLMNOP&issuer=Auth0",
            "recovery_codes": ["CODE1", "CODE2", "CODE3"]
        }
        """.data(using: .utf8)!
    }

    var otpEnrollmentChallengeWithoutRecoveryCodes: Data {
        return """
        {
            "authenticator_type": "otp",
            "secret": "ABCDEFGHIJKLMNOP",
            "barcode_uri": "otpauth://totp/Auth0:user@example.com?secret=ABCDEFGHIJKLMNOP&issuer=Auth0"
        }
        """.data(using: .utf8)!
    }

    var pushEnrollmentChallengeWithRecoveryCodes: Data {
        return """
        {
            "authenticator_type": "oob",
            "oob_channel": "auth0",
            "oob_code": "ABC123XYZ",
            "barcode_uri": "otpauth://totp/Auth0:user@example.com?secret=SECRET&enrollment=push",
            "recovery_codes": ["PUSH1", "PUSH2"]
        }
        """.data(using: .utf8)!
    }

    var pushEnrollmentChallengeWithoutRecoveryCodes: Data {
        return """
        {
            "authenticator_type": "oob",
            "oob_channel": "auth0",
            "oob_code": "ABC123XYZ",
            "barcode_uri": "otpauth://totp/Auth0:user@example.com?secret=SECRET&enrollment=push"
        }
        """.data(using: .utf8)!
    }

    var credentialsData: Data {
        return """
        {
            "access_token": "access_token_123",
            "token_type": "Bearer",
            "id_token": "id_token_456",
            "expires_in": 3600
        }
        """.data(using: .utf8)!
    }

    var credentialsWithRecoveryCodeData: Data {
        return """
        {
            "access_token": "recovery_access_token",
            "token_type": "Bearer",
            "id_token": "recovery_id_token",
            "expires_in": 3600,
            "recovery_code": "NEW_RECOVERY_CODE"
        }
        """.data(using: .utf8)!
    }

    var unauthorizedErrorData: Data {
        return """
        {
            "error": "unauthorized",
            "error_description": "Invalid or expired MFA token"
        }
        """.data(using: .utf8)!
    }

    var invalidRequestErrorData: Data {
        return """
        {
            "error": "invalid_request",
            "error_description": "Invalid phone number format"
        }
        """.data(using: .utf8)!
    }

    var invalidTokenErrorData: Data {
        return """
        {
            "error": "invalid_token",
            "error_description": "MFA token is invalid or expired"
        }
        """.data(using: .utf8)!
    }

    var invalidAuthenticatorErrorData: Data {
        return """
        {
            "error": "invalid_authenticator",
            "error_description": "Authenticator not found or inactive"
        }
        """.data(using: .utf8)!
    }

    var invalidGrantErrorData: Data {
        return """
        {
            "error": "invalid_grant",
            "error_description": "Invalid or expired OOB code"
        }
        """.data(using: .utf8)!
    }

    var invalidOTPErrorData: Data {
        return """
        {
            "error": "invalid_otp",
            "error_description": "The OTP code is invalid"
        }
        """.data(using: .utf8)!
    }

    var invalidRecoveryCodeErrorData: Data {
        return """
        {
            "error": "invalid_recovery_code",
            "error_description": "Recovery code is invalid or already used"
        }
        """.data(using: .utf8)!
    }

    var invalidEmailErrorData: Data {
        return """
        {
            "error": "invalid_email",
            "error_description": "Email address is invalid"
        }
        """.data(using: .utf8)!
    }

    var serverErrorData: Data {
        return """
        {
            "error": "server_error",
            "error_description": "Internal server error"
        }
        """.data(using: .utf8)!
    }
    
    // MARK: - Get Authenticators Tests

    @Test
    func testGetAuthenticatorsSuccess() async {
        let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).getAuthenticators(mfaToken: "", factorsAllowed: ["phone"])

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.authenticatorsData)
                }

                let authenticators = try await request.start()
                #expect(authenticators.count == 2)
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - Phone Enrollment Tests

    @Test
    func testEnrollPhoneWithRecoveryCodes() async {
        let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "", phoneNumber: "")

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.phoneEnrollmentChallengeWithRecoveryCode)
                }

                let phoneChallenge = try await request.start()
                #expect(phoneChallenge.recoveryCodes?.first == "G14KWJB572GUSD2T3NJV625L")
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func testEnrollPhoneWithoutRecoveryCodes() async {
        let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "", phoneNumber: "")

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.phoneEnrollmentChallengeWithoutRecoveryCode)
                }

                let phoneChallenge = try await request.start()
                #expect(phoneChallenge.recoveryCodes == nil)
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - Challenge Tests

    @Test
    func testMFAChallenge() async {
        let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).challenge(with: "", mfaToken: "")

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.challengeData)
                }

                let challenge = try await request.start()
                #expect(challenge.oobCode == "Fe26.2*SERVER_1767928705*c07b491097a63f380a635dcd122f3191e10a671f8a136e53d261d3a99e53abc1*YVe_7o7SbFNURbjXSQzTEg*1BDWU0i-IO1kE_WRLjHcXQhszHgoQcVKsHAniyWMnOaUwRxTc5uKlfoWz2poYwS2cwFPbf868KFmAshTlXlytlQe4uGvLBkwjwdAYL8VL2BwV9e2rDtoqBCAgP4qESzLiNWuN8vRN_eddsG7mrfmEkz3t_k7LNYTHLIkyC1zgTLww4QVbsHwHGL3TvBu1U3xvzMQ_Abv3xbnLtIrWcZbMzxe-JXRQ5Fw9-pD5zx6-2xeU3zcBzUQ2SQSC_cs5fuwzUzKm7TiMAE2kGV_EJ_8UmAoc6yPnRAvudm2kNvY_G6jfuzriqsV8mhfJVrCKM8dQGwwnMye1Nqe9tavMs9Tk7bm6KEjEAYk7x6CepdIeVajtlpjlef_Mwwn02nuK_pC*1768216113061*a7b60435bf02e470f56767477678fb852edb9c032d8e1528f64b003078286a11*tfFIO4_1BFvlNdzs5s7mKjW6ajvrlkBF7HUrGur9VIk")
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - OTP Enrollment Tests

    @Test
    func testEnrollOTPWithRecoveryCodes() async {
        let request: Request<OTPMFAEnrollmentChallenge, MfaEnrollmentError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "")

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.otpEnrollmentChallengeWithRecoveryCodes)
                }

                let otpChallenge = try await request.start()
                #expect(otpChallenge.authenticatorType == "otp")
                #expect(otpChallenge.secret == "ABCDEFGHIJKLMNOP")
                #expect(otpChallenge.barcodeUri == "otpauth://totp/Auth0:user@example.com?secret=ABCDEFGHIJKLMNOP&issuer=Auth0")
                #expect(otpChallenge.recoveryCodes?.count == 3)
                #expect(otpChallenge.recoveryCodes?.first == "CODE1")
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func testEnrollOTPWithoutRecoveryCodes() async {
        let request: Request<OTPMFAEnrollmentChallenge, MfaEnrollmentError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "")

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.otpEnrollmentChallengeWithoutRecoveryCodes)
                }

                let otpChallenge = try await request.start()
                #expect(otpChallenge.authenticatorType == "otp")
                #expect(otpChallenge.recoveryCodes == nil)
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - Push Enrollment Tests

    @Test
    func testEnrollPushWithRecoveryCodes() async {
        let request: Request<PushMFAEnrollmentChallenge, MfaEnrollmentError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "")

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.pushEnrollmentChallengeWithRecoveryCodes)
                }

                let pushChallenge = try await request.start()
                #expect(pushChallenge.authenticatorType == "oob")
                #expect(pushChallenge.oobChannel == "auth0")
                #expect(pushChallenge.oobCode == "ABC123XYZ")
                #expect(pushChallenge.recoveryCodes?.count == 2)
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func testEnrollPushWithoutRecoveryCodes() async {
        let request: Request<PushMFAEnrollmentChallenge, MfaEnrollmentError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "")

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.pushEnrollmentChallengeWithoutRecoveryCodes)
                }

                let pushChallenge = try await request.start()
                #expect(pushChallenge.recoveryCodes == nil)
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - Email Enrollment Tests

    @Test
    func testEnrollEmailSuccess() async {
        let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "", email: "test@example.com")

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.phoneEnrollmentChallengeWithoutRecoveryCode)
                }

                let emailChallenge = try await request.start()
                #expect(emailChallenge.oobCode.isEmpty == false)
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - Verify OOB Tests

    @Test
    func testVerifyOOBSuccess() async {
        let request: Request<Credentials, MFAVerifyError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).verify(oobCode: "oob123", bindingCode: "bind456", mfaToken: "mfa_token")

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.credentialsData)
                }

                let credentials = try await request.start()
                #expect(credentials.accessToken == "access_token_123")
                #expect(credentials.tokenType == "Bearer")
                #expect(credentials.idToken == "id_token_456")
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func testVerifyOOBWithoutBindingCode() async {
        let request: Request<Credentials, MFAVerifyError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).verify(oobCode: "oob123", bindingCode: nil, mfaToken: "mfa_token")

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.credentialsData)
                }

                let credentials = try await request.start()
                #expect(credentials.accessToken == "access_token_123")
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - Verify OTP Tests

    @Test
    func testVerifyOTPSuccess() async {
        let request: Request<Credentials, MFAVerifyError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).verify(otp: "123456", mfaToken: "mfa_token")

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.credentialsData)
                }

                let credentials = try await request.start()
                #expect(credentials.accessToken == "access_token_123")
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - Verify Recovery Code Tests

    @Test
    func testVerifyRecoveryCodeSuccess() async {
        let request: Request<Credentials, MFAVerifyError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).verify(recoveryCode: "RECOVERY123", mfaToken: "mfa_token")

        do {
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.auth0.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.credentialsWithRecoveryCodeData)
                }

                let credentials = try await request.start()
                #expect(credentials.accessToken == "recovery_access_token")
                #expect(credentials.recoveryCode == "NEW_RECOVERY_CODE")
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - Failure Tests

    @Test
    func testGetAuthenticatorsFailureUnauthorized() async {
        let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).getAuthenticators(mfaToken: "invalid_token", factorsAllowed: [])

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test.auth0.com")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.unauthorizedErrorData)
        }

        do {
            _ = try await request.start()
            Issue.record("Expected error but got success")
        } catch let error as MfaListAuthenticatorsError {
            #expect(error.statusCode == 0)
            #expect(error.code == "mfa_list_authenticators_error")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func testPhoneEnrollmentFailure() async {
        let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "", phoneNumber: "invalid")

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test.auth0.com")!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.invalidRequestErrorData)
        }

        do {
            _ = try await request.start()
            Issue.record("Expected error but got success")
        } catch let error as MfaEnrollmentError {
            #expect(error.statusCode == 400)
            #expect(error.code == "invalid_request")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func testOTPEnrollmentFailure() async {
        let request: Request<OTPMFAEnrollmentChallenge, MfaEnrollmentError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "expired_token")

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test.auth0.com")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.invalidTokenErrorData)
        }

        do {
            _ = try await request.start()
            Issue.record("Expected error but got success")
        } catch let error as MfaEnrollmentError {
            #expect(error.statusCode == 401)
            #expect(error.code == "invalid_token")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func testChallengeFailure() async {
        let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).challenge(with: "invalid_id", mfaToken: "")

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test.auth0.com")!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.invalidAuthenticatorErrorData)
        }

        do {
            _ = try await request.start()
            Issue.record("Expected error but got success")
        } catch let error as MfaChallengeError {
            #expect(error.statusCode == 404)
            #expect(error.code == "invalid_authenticator")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func testVerifyOOBFailure() async {
        let request: Request<Credentials, MFAVerifyError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).verify(oobCode: "invalid", bindingCode: nil, mfaToken: "")

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test.auth0.com")!,
                statusCode: 403,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.invalidGrantErrorData)
        }

        do {
            _ = try await request.start()
            Issue.record("Expected error but got success")
        } catch let error as MFAVerifyError {
            #expect(error.statusCode == 403)
            #expect(error.code == "invalid_grant")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func testVerifyOTPFailure() async {
        let request: Request<Credentials, MFAVerifyError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).verify(otp: "000000", mfaToken: "")

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test.auth0.com")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.invalidOTPErrorData)
        }

        do {
            _ = try await request.start()
            Issue.record("Expected error but got success")
        } catch let error as MFAVerifyError {
            #expect(error.statusCode == 401)
            #expect(error.code == "invalid_otp")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func testVerifyRecoveryCodeFailure() async {
        let request: Request<Credentials, MFAVerifyError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).verify(recoveryCode: "INVALID", mfaToken: "")

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test.auth0.com")!,
                statusCode: 403,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.invalidRecoveryCodeErrorData)
        }

        do {
            _ = try await request.start()
            Issue.record("Expected error but got success")
        } catch let error as MFAVerifyError {
            #expect(error.statusCode == 403)
            #expect(error.code == "invalid_recovery_code")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func testEmailEnrollmentFailure() async {
        let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "", email: "invalid_email")

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test.auth0.com")!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.invalidEmailErrorData)
        }

        do {
            _ = try await request.start()
            Issue.record("Expected error but got success")
        } catch let error as MfaEnrollmentError {
            #expect(error.statusCode == 400)
            #expect(error.code == "invalid_email")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func testPushEnrollmentFailure() async {
        let request: Request<PushMFAEnrollmentChallenge, MfaEnrollmentError> = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "")

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test.auth0.com")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.serverErrorData)
        }

        do {
            _ = try await request.start()
            Issue.record("Expected error but got success")
        } catch let error as MfaEnrollmentError {
            #expect(error.statusCode == 500)
            #expect(error.code == "server_error")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
