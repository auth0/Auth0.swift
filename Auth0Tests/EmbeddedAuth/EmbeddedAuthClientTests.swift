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

private func makeClient() -> EmbeddedAuth {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [EmbeddedAuthClientMockProtocol.self]
    return Auth0.embeddedAuth(clientId: clientId, domain: domain, session: URLSession(configuration: config))
}

private func insufficientAuthData(session: String, nextActions: [[String: Any]]) -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: [
        "error": "insufficient_authorization",
        "auth_session": session,
        "next": nextActions
    ])
}

private func authCodeData(code: String = "auth0_ac_test123") -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: ["authorization_code": code])
}

private func credentialsData(accessToken: String = "test_access_token") -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: [
        "access_token": accessToken,
        "token_type": "Bearer",
        "id_token": "test_id_token",
        "expires_in": 86400
    ])
}

private func response(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://\(domain)/")!,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: nil)!
}

// MARK: - Suite

@Suite(.serialized)
struct EmbeddedAuthClientTests {

    // MARK: Factory

    @Test func factoryCreatesClientWithExplicitParams() throws {
        let client = try #require(Auth0.embeddedAuth(clientId: clientId, domain: domain) as? Auth0EmbeddedAuth)
        #expect(client.clientId == clientId)
        #expect(client.url.absoluteString == "https://\(domain)/")
    }

    @Test func factoryUsesSharedSessionByDefault() throws {
        let client = try #require(Auth0.embeddedAuth(clientId: clientId, domain: domain) as? Auth0EmbeddedAuth)
        #expect(client.session === URLSession.shared)
    }

    @Test func factoryAcceptsCustomSession() throws {
        let custom = URLSession(configuration: .ephemeral)
        let client = try #require(Auth0.embeddedAuth(clientId: clientId, domain: domain, session: custom) as? Auth0EmbeddedAuth)
        #expect(client.session === custom)
    }

    // MARK: authorize() — request body

    @Test func authorizePostsToCorrectURL() async {
        let sut = makeClient()
        var capturedURL: URL?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            capturedURL = req.url
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()
        #expect(capturedURL?.path.hasSuffix("/e/authorize") == true)
    }

    @Test func authorizeSendsClientIdInBody() async {
        let sut = makeClient()
        var capturedBody: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            capturedBody = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()
        #expect(capturedBody?["client_id"] as? String == clientId)
    }

    @Test func authorizeSendsDefaultScopeInBody() async {
        let sut = makeClient()
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()
        #expect(body?["scope"] as? String == "openid profile email offline_access")
    }

    @Test func authorizeSendsCustomScopeInBody() async {
        let sut = makeClient()
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection",
                                     capabilities: EmbeddedCapability.all,
                                     scope: "openid",
                                     audience: nil).start()
        #expect(body?["scope"] as? String == "openid")
    }

    @Test func authorizeSendsConnectionInBody() async {
        let sut = makeClient()
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection",
                                     capabilities: EmbeddedCapability.all,
                                     scope: "openid profile email offline_access",
                                     audience: nil).start()
        #expect(body?["connection"] as? String == "test-connection")
    }

    @Test func authorizeSendsCapabilitiesInBody() async {
        let sut = makeClient()
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection",
                                     capabilities: [.identifyEmail, .challengeEmail, .verifyOTP],
                                     scope: "openid profile email offline_access",
                                     audience: nil).start()
        let caps = body?["capabilities"] as? [String]
        #expect(caps?.contains("action:identify:email:v1") == true)
        #expect(caps?.contains("action:challenge:email:v1") == true)
        #expect(caps?.contains("action:verify:otp:v1") == true)
    }

    // MARK: authorize() — response parsing

    @Test func authorizeThrowsInsufficientAuthorizationWith403() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        do {
            _ = try await sut.authorize(connection: "test-connection").start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            guard case .insufficientAuthorization(let actions) = error.kind else {
                Issue.record("Expected .insufficientAuthorization, got \(error.kind)"); return
            }
            #expect(actions == [.identifyEmail])
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: identify — local session guard

    @Test func identifyFailsLocallyWithNoSession() async {
        let sut = makeClient()
        // No network handler set — any network call would crash
        do {
            _ = try await sut.identify("alice@example.com", type: .email).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
            #expect(error.statusCode == 0)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: identify — request body (after session established)

    @Test func identifySendsCorrectBody() async throws {
        let sut = makeClient()

        // First call: establish session
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        // Second call: capture identify body
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:challenge:email:v1"]]))
        }
        _ = try? await sut.identify("alice@example.com", type: .email).start()

        #expect(body?["action"] as? String == "action:identify:email:v1")
        #expect(body?["email"] as? String == "alice@example.com")
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    @Test func identifyDoesNotExposeAuthSession() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()
        // auth_session is stored internally — there is no public accessor on EmbeddedAuth
        // This test documents the invariant: the protocol has no authSession property
        let mirror = Mirror(reflecting: sut)
        let hasPublicSession = mirror.children.contains { $0.label == "authSession" }
        #expect(!hasPublicSession)
    }

    // MARK: challengeEmail

    @Test func challengeEmailFailsLocallyWithNoSession() async {
        let sut = makeClient()
        do {
            _ = try await sut.challengeEmail(index: 0).start()
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
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:challenge:email:v1", "index": 0, "identifier": "al**@example.com"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:verify:otp:v1", "channel": "email", "identifier": "al**@example.com"]]))
        }
        _ = try? await sut.challengeEmail(index: 0).start()
        #expect(body?["action"] as? String == "action:challenge:email:v1")
        #expect(body?["auth_session"] as? String == "sess_001")
        #expect(body?["index"] as? Int == 0)
    }

    @Test func challengeEmailSendsIndexInBody() async {
        let sut = makeClient()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:challenge:email:v1", "index": 2, "identifier": "al**@example.com"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: []))
        }
        _ = try? await sut.challengeEmail(index: 2).start()
        #expect(body?["index"] as? Int == 2)
    }

    @Test func challengeEmailRotatesSession() async {
        let sut = makeClient()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:challenge:email:v1", "index": 0, "identifier": "al**@example.com"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:verify:otp:v1", "channel": "email"]]))
        }
        _ = try? await sut.challengeEmail(index: 0).start()

        // Next call should use the rotated session
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (response(status: 200), credentialsData())
            }
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
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1", "channel": "email"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (response(status: 200), credentialsData())
            }
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 200), authCodeData())
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()

        #expect(body?["action"] as? String == "action:verify:otp:v1")
        #expect(body?["otp"] as? String == "123456")
        #expect(body?["type"] as? String == "oob")
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    @Test func verifyOtpReturnsCredentialsOn200() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1", "channel": "email"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        nonisolated(unsafe) var tokenBody: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                tokenBody = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
                return (response(status: 200), credentialsData(accessToken: "the_access_token"))
            }
            return (response(status: 200), authCodeData(code: "auth0_ac_theCode"))
        }
        do {
            let credentials = try await sut.verifyOtp("123456", type: .oob).start()
            #expect(credentials.accessToken == "the_access_token")
            // G2: token exchange must not include empty PKCE/redirect fields
            #expect(tokenBody?["code_verifier"] == nil)
            #expect(tokenBody?["redirect_uri"] == nil)
            #expect(tokenBody?["code"] as? String == "auth0_ac_theCode")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func verifyOtpClearsSessionOnSuccess() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1", "channel": "email"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (response(status: 200), credentialsData())
            }
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
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1", "channel": "email"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        // Wrong OTP: server returns 403 insufficient_authorization again
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:verify:otp:v1", "channel": "email"]]))
        }
        _ = try? await sut.verifyOtp("000000", type: .oob).start()

        // Retry should still work (session is updated to sess_002)
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (response(status: 200), credentialsData())
            }
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 200), authCodeData())
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()
        #expect(body?["auth_session"] as? String == "sess_002")
    }

    // MARK: Error paths

    @Test func authorizeThrowsAccessDeniedOnTerminalDenial() async {
        let sut = makeClient()
        let verifyNextAction: [[String: Any]] = [["action": "action:verify:otp:v1", "channel": "email"]]

        // Step 1: establish session via insufficient_authorization
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: verifyNextAction))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        // Step 2: verifyOtp returns terminal access_denied
        // swiftlint:disable:next force_try
        let terminalData = try! JSONSerialization.data(withJSONObject: [
            "error": "access_denied",
            "error_description": "too_many_wrong_otp_attempts"
        ])
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in (response(status: 403), terminalData) }
        do {
            _ = try await sut.verifyOtp("000000", type: .oob).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            guard case .tooManyWrongOtpAttempts = error.kind else {
                Issue.record("Expected .tooManyWrongOtpAttempts, got \(error.kind)"); return
            }
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func unknownErrorClearsSession() async {
        let sut = makeClient()
        // Establish session
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        // A 500 server_error maps to .unknown → session cleared
        // swiftlint:disable:next force_try
        let serverErrorData = try! JSONSerialization.data(withJSONObject: [
            "error": "server_error",
            "error_description": "internal server error"
        ])
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in (response(status: 500), serverErrorData) }
        _ = try? await sut.identify("alice@example.com", type: .email).start()

        // Session is cleared — the next step fails locally
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            Issue.record("No network call expected once the session is cleared")
            return (response(status: 200), authCodeData())
        }
        do {
            _ = try await sut.identify("alice@example.com", type: .email).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func terminalFailureClearsSession() async {
        let sut = makeClient()
        // Establish session
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        // A terminal failure clears the session
        // swiftlint:disable:next force_try
        let terminalData = try! JSONSerialization.data(withJSONObject: ["error": "access_denied"])
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in (response(status: 403), terminalData) }
        _ = try? await sut.identify("alice@example.com", type: .email).start()

        // The next step is rejected locally without hitting the network
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            Issue.record("No network call expected once the session is cleared")
            return (response(status: 200), authCodeData())
        }
        do {
            _ = try await sut.identify("alice@example.com", type: .email).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func networkErrorPreservesSession() async {
        let sut = makeClient()
        // Establish session
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        // A network-layer failure (URLError) must preserve the session for retry
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await sut.identify("alice@example.com", type: .email).start()
        } catch let error as EmbeddedAuthError {
            guard case .network = error.kind else {
                Issue.record("Expected .network, got \(error.kind)"); return
            }
        } catch { Issue.record("Wrong error type: \(error)") }

        // Session still active — retry reaches the network again, not the local guard
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: []))
        }
        _ = try? await sut.identify("alice@example.com", type: .email).start()
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    @Test func sessionExpiredClearsSession() async {
        let sut = makeClient()
        // Establish session
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:challenge:email:v1", "index": 0, "identifier": "al**@example.com"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        // Server returns invalid_grant (expired auth_session)
        // swiftlint:disable:next force_try
        let expiredData = try! JSONSerialization.data(withJSONObject: [
            "error": "invalid_grant",
            "error_description": "The auth_session has expired."
        ])
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in (response(status: 400), expiredData) }
        do {
            _ = try await sut.challengeEmail(index: 0).start()
        } catch let error as EmbeddedAuthError {
            guard case .sessionExpired = error.kind else {
                Issue.record("Expected .sessionExpired, got \(error.kind)"); return
            }
        } catch { Issue.record("Wrong error type: \(error)") }

        // Session cleared — next step fails locally
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            Issue.record("No network call expected after sessionExpired")
            return (response(status: 200), authCodeData())
        }
        do {
            _ = try await sut.challengeEmail(index: 0).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func insufficientAuthorizationRotatesSession() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:challenge:email:v1", "index": 0, "identifier": "al**@example.com"]]))
        }
        _ = try? await sut.identify("alice@example.com", type: .email).start()

        // Next step must send the rotated sess_002, not the original sess_001
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "sess_003", nextActions: []))
        }
        _ = try? await sut.challengeEmail(index: 0).start()
        #expect(body?["auth_session"] as? String == "sess_002")
    }

    @Test func authorizeResetsActiveSession() async {
        let sut = makeClient()
        // Establish a session via the first authorize call
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1", "channel": "email"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        // Second authorize() must reset the session so the first session is abandoned
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        // Verify the new session is active by confirming the next step uses sess_002
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "sess_003", nextActions: []))
        }
        _ = try? await sut.identify("alice@example.com", type: .email).start()
        #expect(body?["auth_session"] as? String == "sess_002")
    }

    @Test func verifyOtpExchangeFailureClearsSession() async {
        let sut = makeClient()
        // Establish session
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1", "channel": "email"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        // verifyOtp succeeds on /e/authorize but the token exchange fails
        // swiftlint:disable:next force_try
        let exchangeErrorData = try! JSONSerialization.data(withJSONObject: ["error": "server_error"])
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (response(status: 500), exchangeErrorData)
            }
            return (response(status: 200), authCodeData())
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()

        // The authorization_code is single-use, so the flow is over: the session must be cleared.
        // A subsequent step is rejected locally without hitting the network.
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            Issue.record("No network call expected once the session is cleared")
            return (response(status: 200), authCodeData())
        }
        do {
            _ = try await sut.verifyOtp("123456", type: .oob).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
            #expect(error.statusCode == 0)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: Sequential flow — full e2e with mock data

    @Test func fullEmailOtpFlowReturnsCredentials() async throws {
        let sut = makeClient()
        var callCount = 0

        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (response(status: 200), credentialsData(accessToken: "final_access_token"))
            }
            callCount += 1
            switch callCount {
            case 1:  // authorize()
                return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
            case 2:  // identify()
                return (response(status: 403), insufficientAuthData(session: "s2", nextActions: [["action": "action:challenge:email:v1", "index": 0, "identifier": "al**@example.com"]]))
            case 3:  // challengeEmail()
                return (response(status: 403), insufficientAuthData(session: "s3", nextActions: [["action": "action:verify:otp:v1", "channel": "email", "identifier": "al**@example.com"]]))
            case 4:  // verifyOtp() — /e/authorize leg
                return (response(status: 200), authCodeData(code: "auth0_ac_final"))
            default:
                fatalError("Unexpected call \(callCount)")
            }
        }

        do {
            _ = try await sut.authorize(connection: "test-connection").start()
            Issue.record("authorize() should throw with nextActions")
        } catch let e as EmbeddedAuthError {
            guard case .insufficientAuthorization(let actions) = e.kind else {
                Issue.record("Expected .insufficientAuthorization, got \(e.kind)"); return
            }
            #expect(actions.first == .identifyEmail)
        } catch { Issue.record("Unexpected: \(error)") }

        do {
            _ = try await sut.identify("alice@example.com", type: .email).start()
            Issue.record("identify() should throw with nextActions")
        } catch let e as EmbeddedAuthError {
            guard case .insufficientAuthorization(let actions) = e.kind else {
                Issue.record("Expected .insufficientAuthorization, got \(e.kind)"); return
            }
            guard case .challengeEmail(let index, _) = actions.first else {
                Issue.record("Expected .challengeEmail"); return
            }
            #expect(index == 0)
        } catch { Issue.record("Unexpected: \(error)") }

        do {
            _ = try await sut.challengeEmail(index: 0).start()
            Issue.record("challengeEmail() should throw with nextActions")
        } catch let e as EmbeddedAuthError {
            guard case .insufficientAuthorization(let actions) = e.kind else {
                Issue.record("Expected .insufficientAuthorization, got \(e.kind)"); return
            }
            if case .verifyOTP(let ch, let id) = actions.first {
                #expect(ch == .email)
                #expect(id == "al**@example.com")
            } else {
                Issue.record("Expected .verifyOTP")
            }
        } catch { Issue.record("Unexpected: \(error)") }

        let credentials = try await sut.verifyOtp("123456", type: .oob).start()
        #expect(credentials.accessToken == "final_access_token")
        #expect(callCount == 4)
    }

}
