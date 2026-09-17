import Testing
import Foundation
@testable import Auth0

// Dedicated mock — never share static state with other test suites.
private final class EmbeddedAuthClientMockProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = EmbeddedAuthClientMockProtocol.requestHandler else {
            fatalError("EmbeddedAuthClientMockProtocol requires a requestHandler")
        }
        // URLSession delivers body via httpBodyStream to URLProtocol, not httpBody.
        // Reconstruct httpBody so handlers can access it via req.httpBody.
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

private let clientId = "TEST_CLIENT_ID"
private let domain   = "test.auth0.com"

// MARK: - Helpers

private func makeClient() -> EmbeddedAuthClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [EmbeddedAuthClientMockProtocol.self]
    return Auth0.embeddedAuthClient(clientId: clientId, domain: domain, session: URLSession(configuration: config))
}

private func insufficientAuthData(session: String, nextActions: [[String: Any]]) -> Data {
    try! JSONSerialization.data(withJSONObject: [
        "error": "insufficient_authorization",
        "auth_session": session,
        "next": nextActions
    ])
}

private func authCodeData(code: String = "auth0_ac_test123") -> Data {
    try! JSONSerialization.data(withJSONObject: ["authorization_code": code])
}

private func response(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://\(domain)/")!,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: nil)!
}

private func capturedBody(from request: URLRequest) -> [String: Any]? {
    guard let data = request.httpBody else { return nil }
    return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
}

// MARK: - Suite

@Suite(.serialized)
struct EmbeddedAuthClientTests {

    // MARK: Factory

    @Test func factoryCreatesClientWithExplicitParams() {
        let client = Auth0.embeddedAuthClient(clientId: clientId, domain: domain) as! Auth0EmbeddedAuthClient
        #expect(client.clientId == clientId)
        #expect(client.url.absoluteString == "https://\(domain)/")
    }

    @Test func factoryUsesSharedSessionByDefault() {
        let client = Auth0.embeddedAuthClient(clientId: clientId, domain: domain) as! Auth0EmbeddedAuthClient
        #expect(client.session === URLSession.shared)
    }

    // MARK: authorize() — request body

    @Test func authorizePostsToCorrectURL() async {
        let sut = makeClient()
        var capturedURL: URL?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            capturedURL = req.url
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize().start()
        #expect(capturedURL?.path.hasSuffix("/e/authorize") == true)
    }

    @Test func authorizeUsesPostMethod() async {
        let sut = makeClient()
        var capturedMethod: String?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            capturedMethod = req.httpMethod
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize().start()
        #expect(capturedMethod == "POST")
    }

    @Test func authorizeSendsClientIdInBody() async {
        let sut = makeClient()
        var capturedBody: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            capturedBody = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize().start()
        #expect(capturedBody?["client_id"] as? String == clientId)
    }

    @Test func authorizeSendsCapabilitiesInBody() async {
        let sut = makeClient()
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: nil,
                                       capabilities: [.identifyEmail, .challengeEmail, .verifyOTP],
                                       scope: nil,
                                       audience: nil).start()
        let caps = body?["capabilities"] as? [String]
        #expect(caps?.contains("action:identify:email:v1") == true)
        #expect(caps?.contains("action:challenge:email:v1") == true)
        #expect(caps?.contains("action:verify:otp:v1") == true)
    }

    @Test func authorizeSendsOptionalConnectionWhenProvided() async {
        let sut = makeClient()
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "my-db", capabilities: EmbeddedCapability.all, scope: nil, audience: nil).start()
        #expect(body?["connection"] as? String == "my-db")
    }

    @Test func authorizeOmitsConnectionWhenNil() async {
        let sut = makeClient()
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: nil, capabilities: EmbeddedCapability.all, scope: nil, audience: nil).start()
        #expect(body?["connection"] == nil)
    }

    // MARK: authorize() — response parsing

    @Test func authorizeThrowsInsufficientAuthorizationWith403() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        do {
            _ = try await sut.authorize().start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.isInsufficientAuthorization)
            #expect(error.nextActions == [.identifyEmail])
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: identifyEmail — local session guard

    @Test func identifyEmailFailsLocallyWithNoSession() async {
        let sut = makeClient()
        // No network handler set — any network call would crash
        do {
            _ = try await sut.identifyEmail("alice@example.com").start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
            #expect(error.statusCode == 0)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: identifyEmail — request body (after session established)

    @Test func identifyEmailSendsCorrectBody() async throws {
        let sut = makeClient()

        // First call: establish session
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize().start()

        // Second call: capture identifyEmail body
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:challenge:email:v1"]]))
        }
        _ = try? await sut.identifyEmail("alice@example.com").start()

        #expect(body?["action"] as? String == "action:identify:email:v1")
        #expect(body?["email"] as? String == "alice@example.com")
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    @Test func identifyEmailDoesNotExposeAuthSession() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize().start()
        // auth_session is stored internally — there is no public accessor on EmbeddedAuthClient
        // This test documents the invariant: the protocol has no authSession property
        let mirror = Mirror(reflecting: sut)
        let hasPublicSession = mirror.children.contains { $0.label == "authSession" }
        #expect(!hasPublicSession)
    }

    // MARK: challengeEmail

    @Test func challengeEmailFailsLocallyWithNoSession() async {
        let sut = makeClient()
        do {
            _ = try await sut.challengeEmail().start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func challengeEmailSendsCorrectAction() async {
        let sut = makeClient()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:challenge:email:v1"]]))
        }
        _ = try? await sut.authorize().start()

        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:verify:otp:v1", "channel": "email", "identifier": "al**@example.com"]]))
        }
        _ = try? await sut.challengeEmail().start()
        #expect(body?["action"] as? String == "action:challenge:email:v1")
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    @Test func challengeEmailRotatesSession() async {
        let sut = makeClient()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:challenge:email:v1"]]))
        }
        _ = try? await sut.authorize().start()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:verify:otp:v1"]]))
        }
        _ = try? await sut.challengeEmail().start()

        // Next call should use the rotated session
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 200), authCodeData())
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()
        #expect(body?["auth_session"] as? String == "sess_002")
    }

    // MARK: verifyOtp

    @Test func verifyOtpFailsLocallyWithNoSession() async {
        let sut = makeClient()
        do {
            _ = try await sut.verifyOtp("000000", type: .oob).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyOtpSendsCorrectBody() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1"]]))
        }
        _ = try? await sut.authorize().start()

        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 200), authCodeData())
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()

        #expect(body?["action"] as? String == "action:verify:otp:v1")
        #expect(body?["otp"] as? String == "123456")
        #expect(body?["binding_method"] as? String == "oob")
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    @Test func verifyOtpReturnsAuthorizationCodeOn200() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1"]]))
        }
        _ = try? await sut.authorize().start()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 200), authCodeData(code: "auth0_ac_theCode"))
        }
        do {
            let code = try await sut.verifyOtp("123456", type: .oob).start()
            #expect(code.code == "auth0_ac_theCode")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func verifyOtpClearsSessionOnSuccess() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1"]]))
        }
        _ = try? await sut.authorize().start()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 200), authCodeData())
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()

        // Session cleared — next continuation call must fail locally
        do {
            _ = try await sut.verifyOtp("000000", type: .oob).start()
            Issue.record("Expected no_active_session after successful code exchange")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyOtpDoesNotClearSessionOnWrongOtp() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1"]]))
        }
        _ = try? await sut.authorize().start()

        // Wrong OTP: server returns 403 insufficient_authorization again
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:verify:otp:v1"]]))
        }
        _ = try? await sut.verifyOtp("000000", type: .oob).start()

        // Retry should still work (session is updated to sess_002)
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 200), authCodeData())
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()
        #expect(body?["auth_session"] as? String == "sess_002")
    }

    // MARK: Error paths

    @Test func authorizeThrowsAccessDeniedOnTerminalDenial() async {
        let sut = makeClient()
        let terminalData = try! JSONSerialization.data(withJSONObject: [
            "error": "access_denied",
            "error_description": "too_many_wrong_otp_attempts"
        ])
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in (response(status: 403), terminalData) }
        _ = try? await sut.authorize().start()  // establish session

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in (response(status: 403), terminalData) }
        do {
            _ = try await sut.verifyOtp("000000", type: .oob).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.isAccessDenied)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: Sequential flow — full e2e with mock data

    @Test func fullEmailOtpFlowReturnsAuthorizationCode() async throws {
        let sut = makeClient()
        var callCount = 0

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            callCount += 1
            switch callCount {
            case 1:  // authorize()
                return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
            case 2:  // identifyEmail()
                return (response(status: 403), insufficientAuthData(session: "s2", nextActions: [["action": "action:challenge:email:v1"]]))
            case 3:  // challengeEmail()
                return (response(status: 403), insufficientAuthData(session: "s3", nextActions: [["action": "action:verify:otp:v1", "channel": "email", "identifier": "al**@example.com"]]))
            case 4:  // verifyOtp()
                return (response(status: 200), authCodeData(code: "auth0_ac_final"))
            default:
                fatalError("Unexpected call \(callCount)")
            }
        }

        do {
            _ = try await sut.authorize().start()
            Issue.record("authorize() should throw with nextActions")
        } catch let e as EmbeddedAuthError where e.isInsufficientAuthorization {
            #expect(e.nextActions.first == .identifyEmail)
        } catch { Issue.record("Unexpected: \(error)") }

        do {
            _ = try await sut.identifyEmail("alice@example.com").start()
            Issue.record("identifyEmail() should throw with nextActions")
        } catch let e as EmbeddedAuthError where e.isInsufficientAuthorization {
            #expect(e.nextActions.first == .challengeEmail)
        } catch { Issue.record("Unexpected: \(error)") }

        do {
            _ = try await sut.challengeEmail().start()
            Issue.record("challengeEmail() should throw with nextActions")
        } catch let e as EmbeddedAuthError where e.isInsufficientAuthorization {
            if case .verifyOTP(let ch, let id) = e.nextActions.first {
                #expect(ch == "email")
                #expect(id == "al**@example.com")
            } else {
                Issue.record("Expected .verifyOTP")
            }
        } catch { Issue.record("Unexpected: \(error)") }

        let code = try await sut.verifyOtp("123456", type: .oob).start()
        #expect(code.code == "auth0_ac_final")
        #expect(callCount == 4)
    }

}
