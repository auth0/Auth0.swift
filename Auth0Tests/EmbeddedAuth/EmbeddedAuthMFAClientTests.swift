import Testing
import Foundation
@testable import Auth0

// Dedicated mock — never share static state with other test suites.
private final class EmbeddedAuthMFAMockProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = EmbeddedAuthMFAMockProtocol.requestHandler else {
            fatalError("EmbeddedAuthMFAMockProtocol requires a requestHandler")
        }
        var req = request
        if req.httpBody == nil, let stream = req.httpBodyStream {
            stream.open()
            var bodyData = Data()
            let bufferSize = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read > 0 { bodyData.append(buffer, count: read) }
            }
            stream.close()
            req.httpBody = bodyData
        }
        do {
            let (response, data) = try handler(req)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data { client?.urlProtocol(self, didLoad: data) }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private let mfaClientId = "TEST_CLIENT_ID"
private let mfaDomain   = "test.auth0.com"

// MARK: - Helpers

private func makeMFAClient() -> EmbeddedAuth {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [EmbeddedAuthMFAMockProtocol.self]
    return Auth0.embeddedAuth(clientId: mfaClientId, domain: mfaDomain, session: URLSession(configuration: config))
}

private func insufficientAuthMFA(session: String, nextActions: [[String: Any]]) -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: [
        "error": "insufficient_authorization",
        "auth_session": session,
        "next": nextActions
    ])
}

private func authCodeMFA(code: String = "auth0_ac_test123") -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: ["authorization_code": code])
}

private func credentialsMFA(accessToken: String = "test_access_token") -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: [
        "access_token": accessToken,
        "token_type": "Bearer",
        "id_token": "test_id_token",
        "expires_in": 86400
    ])
}

private func responseMFA(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://\(mfaDomain)/")!,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: nil)!
}

/// Establishes an auth session by running authorize() through the mock.
private func establishSession(_ client: EmbeddedAuth, session: String = "sess_001") async {
    EmbeddedAuthMFAMockProtocol.requestHandler = { _ in
        (responseMFA(status: 403), insufficientAuthMFA(session: session, nextActions: [["action": "action:identify:email:v1"]]))
    }
    _ = try? await client.authorize(connection: "test-connection").start()
}

// MARK: - Suite

@Suite(.serialized)
struct EmbeddedAuthMFAClientTests {

    // MARK: EmbeddedCapability.all includes MFA actions

    @Test func capabilitiesAllIncludesMfaActions() {
        let all = EmbeddedCapability.all.map { $0.action.rawValue }
        #expect(all.contains("action:identify:phone:v1"))
        #expect(all.contains("action:challenge:phone:v1"))
        #expect(all.contains("action:challenge:push:v1"))
        #expect(all.contains("action:verify:oob:v1"))
        #expect(all.contains("action:verify:recovery-code:v1"))
        #expect(all.contains("action:confirm:recovery-code:v1"))
    }

    // MARK: identify(.phone)

    @Test func identifyPhoneFailsLocallyWithNoSession() async {
        let sut = makeMFAClient()
        do {
            _ = try await sut.identify("+15551234567", type: .phone).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
            #expect(error.statusCode == 0)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func identifyPhoneSendsCorrectBody() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        var body: [String: Any]?
        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (responseMFA(status: 403), insufficientAuthMFA(session: "sess_002", nextActions: []))
        }
        _ = try? await sut.identify("+15551234567", type: .phone).start()

        #expect(body?["action"] as? String == "action:identify:phone:v1")
        #expect(body?["phone"] as? String == "+15551234567")
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    // MARK: challengePhone

    @Test func challengePhoneFailsLocallyWithNoSession() async {
        let sut = makeMFAClient()
        do {
            _ = try await sut.challengePhone(index: 0, deliveryMethod: .text).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func challengePhoneSendsCorrectBodyForTextDelivery() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        var body: [String: Any]?
        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (responseMFA(status: 403), insufficientAuthMFA(session: "sess_002", nextActions: []))
        }
        _ = try? await sut.challengePhone(index: 0, deliveryMethod: .text).start()

        #expect(body?["action"] as? String == "action:challenge:phone:v1")
        #expect(body?["index"] as? Int == 0)
        #expect(body?["delivery_method"] as? String == "text")
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    @Test func challengePhoneSendsVoiceDeliveryMethod() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        var body: [String: Any]?
        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (responseMFA(status: 403), insufficientAuthMFA(session: "sess_002", nextActions: []))
        }
        _ = try? await sut.challengePhone(index: 1, deliveryMethod: .voice).start()

        #expect(body?["delivery_method"] as? String == "voice")
        #expect(body?["index"] as? Int == 1)
    }

    @Test func challengePhoneRotatesSession() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        EmbeddedAuthMFAMockProtocol.requestHandler = { _ in
            (responseMFA(status: 403), insufficientAuthMFA(session: "sess_002", nextActions: [["action": "action:verify:otp:v1", "channel": "sms"]]))
        }
        _ = try? await sut.challengePhone(index: 0, deliveryMethod: .text).start()

        var body: [String: Any]?
        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responseMFA(status: 200), credentialsMFA())
            }
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (responseMFA(status: 200), authCodeMFA())
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()
        #expect(body?["auth_session"] as? String == "sess_002")
    }

    // MARK: challengePush

    @Test func challengePushFailsLocallyWithNoSession() async {
        let sut = makeMFAClient()
        do {
            _ = try await sut.challengePush(index: 0).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func challengePushSendsCorrectBody() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        var body: [String: Any]?
        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (responseMFA(status: 403), insufficientAuthMFA(session: "sess_002", nextActions: [["action": "action:verify:oob:v1", "poll_in_ms": 2000]]))
        }
        _ = try? await sut.challengePush(index: 0).start()

        #expect(body?["action"] as? String == "action:challenge:push:v1")
        #expect(body?["index"] as? Int == 0)
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    // MARK: verifyOob

    @Test func verifyOobFailsLocallyWithNoSession() async {
        let sut = makeMFAClient()
        do {
            _ = try await sut.verifyOob().start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyOobSendsBodyWithoutExtraFields() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        var body: [String: Any]?
        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responseMFA(status: 200), credentialsMFA())
            }
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (responseMFA(status: 200), authCodeMFA())
        }
        _ = try? await sut.verifyOob().start()

        #expect(body?["action"] as? String == "action:verify:oob:v1")
        #expect(body?["auth_session"] as? String == "sess_001")
        // No extra fields
        #expect(body?["otp"] == nil)
        #expect(body?["type"] == nil)
    }

    @Test func verifyOobReturnsCredentialsOn200() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responseMFA(status: 200), credentialsMFA(accessToken: "mfa_access_token"))
            }
            return (responseMFA(status: 200), authCodeMFA(code: "auth0_ac_mfa"))
        }
        do {
            let credentials = try await sut.verifyOob().start()
            #expect(credentials.accessToken == "mfa_access_token")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func verifyOobClearsSessionOnSuccess() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responseMFA(status: 200), credentialsMFA())
            }
            return (responseMFA(status: 200), authCodeMFA())
        }
        _ = try? await sut.verifyOob().start()

        do {
            _ = try await sut.verifyOob().start()
            Issue.record("Expected no_active_session after success")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyOobAuthorizationPendingPreservesFlow() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        EmbeddedAuthMFAMockProtocol.requestHandler = { _ in
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: [
                "error": "insufficient_authorization",
                "error_description": "authorization_pending",
                "auth_session": "sess_002",
                "next": [["action": "action:verify:oob:v1", "poll_in_ms": 2000]]
            ])
            return (responseMFA(status: 403), data)
        }
        do {
            _ = try await sut.verifyOob().start()
            Issue.record("Expected continuation")
        } catch let error as EmbeddedAuthError {
            guard case .insufficientAuthorization(.authorizationPending, _) = error.reason else {
                Issue.record("Expected .authorizationPending, got \(error.reason)"); return
            }
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyOobSlowDownIsContinuation() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        EmbeddedAuthMFAMockProtocol.requestHandler = { _ in
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: [
                "error": "insufficient_authorization",
                "error_description": "slow_down",
                "auth_session": "sess_002",
                "next": [["action": "action:verify:oob:v1", "poll_in_ms": 2000]]
            ])
            return (responseMFA(status: 403), data)
        }
        do {
            _ = try await sut.verifyOob().start()
            Issue.record("Expected continuation")
        } catch let error as EmbeddedAuthError {
            guard case .insufficientAuthorization(.slowDown, _) = error.reason else {
                Issue.record("Expected .slowDown, got \(error.reason)"); return
            }
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyOobAuthorizationRejectedClearsSession() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        EmbeddedAuthMFAMockProtocol.requestHandler = { _ in
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: [
                "error": "access_denied",
                "error_description": "authorization_rejected"
            ])
            return (responseMFA(status: 403), data)
        }
        do {
            _ = try await sut.verifyOob().start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            guard case .authorizationRejected = error.reason else {
                Issue.record("Expected .authorizationRejected, got \(error.reason)"); return
            }
        } catch {
            Issue.record("Wrong error type: \(error)")
        }

        do {
            _ = try await sut.verifyOob().start()
            Issue.record("Expected no_active_session after rejection")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyOobChallengeExpiredClearsSession() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        EmbeddedAuthMFAMockProtocol.requestHandler = { _ in
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: [
                "error": "access_denied",
                "error_description": "challenge_expired"
            ])
            return (responseMFA(status: 403), data)
        }
        do {
            _ = try await sut.verifyOob().start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            guard case .challengeExpired = error.reason else {
                Issue.record("Expected .challengeExpired, got \(error.reason)"); return
            }
        } catch {
            Issue.record("Wrong error type: \(error)")
        }

        do {
            _ = try await sut.verifyOob().start()
            Issue.record("Expected no_active_session after expiry")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyOobExchangeFailureClearsSession() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        // swiftlint:disable:next force_try
        let exchangeErrorData = try! JSONSerialization.data(withJSONObject: ["error": "server_error"])
        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responseMFA(status: 500), exchangeErrorData)
            }
            return (responseMFA(status: 200), authCodeMFA())
        }
        _ = try? await sut.verifyOob().start()

        do {
            _ = try await sut.verifyOob().start()
            Issue.record("Expected no_active_session after failed exchange")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: verifyRecoveryCode

    @Test func verifyRecoveryCodeFailsLocallyWithNoSession() async {
        let sut = makeMFAClient()
        do {
            _ = try await sut.verifyRecoveryCode("ABCD-1234").start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyRecoveryCodeSendsCorrectBody() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        var body: [String: Any]?
        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (responseMFA(status: 403), insufficientAuthMFA(session: "sess_002", nextActions: [
                ["action": "action:confirm:recovery-code:v1", "new_code": "EFGH-5678"]
            ]))
        }
        _ = try? await sut.verifyRecoveryCode("ABCD-1234").start()

        #expect(body?["action"] as? String == "action:verify:recovery-code:v1")
        #expect(body?["code"] as? String == "ABCD-1234")
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    @Test func verifyRecoveryCodeContinuesToConfirm() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        EmbeddedAuthMFAMockProtocol.requestHandler = { _ in
            (responseMFA(status: 403), insufficientAuthMFA(session: "sess_002", nextActions: [
                ["action": "action:confirm:recovery-code:v1", "new_code": "EFGH-5678"]
            ]))
        }
        do {
            _ = try await sut.verifyRecoveryCode("ABCD-1234").start()
            Issue.record("Expected continuation")
        } catch let error as EmbeddedAuthError {
            guard case .insufficientAuthorization(_, let actions) = error.reason,
                  case .confirmRecoveryCode(let newCode) = actions.first else {
                Issue.record("Expected .confirmRecoveryCode in nextActions, got \(error.reason)"); return
            }
            #expect(newCode == "EFGH-5678")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: confirmRecoveryCode

    @Test func confirmRecoveryCodeFailsLocallyWithNoSession() async {
        let sut = makeMFAClient()
        do {
            _ = try await sut.confirmRecoveryCode().start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func confirmRecoveryCodeSendsBodyWithoutExtraFields() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        var body: [String: Any]?
        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responseMFA(status: 200), credentialsMFA())
            }
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (responseMFA(status: 200), authCodeMFA())
        }
        _ = try? await sut.confirmRecoveryCode().start()

        #expect(body?["action"] as? String == "action:confirm:recovery-code:v1")
        #expect(body?["auth_session"] as? String == "sess_001")
        #expect(body?["code"] == nil)
    }

    @Test func confirmRecoveryCodeReturnsCredentialsOn200() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responseMFA(status: 200), credentialsMFA(accessToken: "recovery_access_token"))
            }
            return (responseMFA(status: 200), authCodeMFA())
        }
        do {
            let credentials = try await sut.confirmRecoveryCode().start()
            #expect(credentials.accessToken == "recovery_access_token")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func confirmRecoveryCodeClearsSessionOnSuccess() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responseMFA(status: 200), credentialsMFA())
            }
            return (responseMFA(status: 200), authCodeMFA())
        }
        _ = try? await sut.confirmRecoveryCode().start()

        do {
            _ = try await sut.confirmRecoveryCode().start()
            Issue.record("Expected no_active_session after success")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: noEligibleFactors

    @Test func noEligibleFactorsClearsSession() async {
        let sut = makeMFAClient()
        await establishSession(sut)

        // swiftlint:disable:next force_try
        let terminalData = try! JSONSerialization.data(withJSONObject: [
            "error": "access_denied",
            "error_description": "no_eligible_factors"
        ])
        EmbeddedAuthMFAMockProtocol.requestHandler = { _ in (responseMFA(status: 403), terminalData) }
        do {
            _ = try await sut.identify("+15551234567", type: .phone).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            guard case .noEligibleFactors = error.reason else {
                Issue.record("Expected .noEligibleFactors, got \(error.reason)"); return
            }
        } catch {
            Issue.record("Wrong error type: \(error)")
        }

        do {
            _ = try await sut.identify("+15551234567", type: .phone).start()
            Issue.record("Expected no_active_session after terminal")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: Full MFA flows

    @Test func fullPhoneOtpFlowReturnsCredentials() async throws {
        let sut = makeMFAClient()
        var callCount = 0

        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responseMFA(status: 200), credentialsMFA(accessToken: "phone_token"))
            }
            callCount += 1
            switch callCount {
            case 1:  // authorize()
                return (responseMFA(status: 403), insufficientAuthMFA(session: "s1", nextActions: [["action": "action:identify:phone:v1"]]))
            case 2:  // identify(phone)
                return (responseMFA(status: 403), insufficientAuthMFA(session: "s2", nextActions: [["action": "action:challenge:phone:v1", "index": 0, "identifier": "+1*****567", "delivery_methods": ["text", "voice"]]]))
            case 3:  // challengePhone()
                return (responseMFA(status: 403), insufficientAuthMFA(session: "s3", nextActions: [["action": "action:verify:otp:v1", "channel": "sms"]]))
            case 4:  // verifyOtp() — /e/authorize leg
                return (responseMFA(status: 200), authCodeMFA())
            default:
                fatalError("Unexpected call \(callCount)")
            }
        }

        _ = try? await sut.authorize(connection: "test-connection").start()
        _ = try? await sut.identify("+15551234567", type: .phone).start()
        _ = try? await sut.challengePhone(index: 0, deliveryMethod: .text).start()
        let credentials = try await sut.verifyOtp("123456", type: .oob).start()
        #expect(credentials.accessToken == "phone_token")
        #expect(callCount == 4)
    }

    @Test func fullPushFlowReturnsCredentials() async throws {
        let sut = makeMFAClient()
        var callCount = 0

        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responseMFA(status: 200), credentialsMFA(accessToken: "push_token"))
            }
            callCount += 1
            switch callCount {
            case 1:  // authorize()
                return (responseMFA(status: 403), insufficientAuthMFA(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
            case 2:  // challengePush()
                return (responseMFA(status: 403), insufficientAuthMFA(session: "s2", nextActions: [["action": "action:verify:oob:v1", "poll_in_ms": 2000]]))
            case 3:  // verifyOob() — approved
                return (responseMFA(status: 200), authCodeMFA())
            default:
                fatalError("Unexpected call \(callCount)")
            }
        }

        _ = try? await sut.authorize(connection: "test-connection").start()
        _ = try? await sut.challengePush(index: 0).start()
        let credentials = try await sut.verifyOob().start()
        #expect(credentials.accessToken == "push_token")
        #expect(callCount == 3)
    }

    @Test func fullRecoveryCodeFlowReturnsCredentials() async throws {
        let sut = makeMFAClient()
        var callCount = 0

        EmbeddedAuthMFAMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responseMFA(status: 200), credentialsMFA(accessToken: "recovery_token"))
            }
            callCount += 1
            switch callCount {
            case 1:  // authorize()
                return (responseMFA(status: 403), insufficientAuthMFA(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
            case 2:  // verifyRecoveryCode()
                return (responseMFA(status: 403), insufficientAuthMFA(session: "s2", nextActions: [["action": "action:confirm:recovery-code:v1", "new_code": "WXYZ-9012"]]))
            case 3:  // confirmRecoveryCode()
                return (responseMFA(status: 200), authCodeMFA())
            default:
                fatalError("Unexpected call \(callCount)")
            }
        }

        _ = try? await sut.authorize(connection: "test-connection").start()
        _ = try? await sut.verifyRecoveryCode("ABCD-1234").start()
        let credentials = try await sut.confirmRecoveryCode().start()
        #expect(credentials.accessToken == "recovery_token")
        #expect(callCount == 3)
    }
}
