import Testing
import Foundation
@testable import Auth0

// Dedicated mock — never share static state with other test suites.
private final class EmbeddedAuthPasswordMockProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = EmbeddedAuthPasswordMockProtocol.requestHandler else {
            fatalError("EmbeddedAuthPasswordMockProtocol requires a requestHandler")
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

private let passwordClientId = "TEST_CLIENT_ID"
private let passwordDomain   = "test.auth0.com"

// MARK: - Helpers

private func makePasswordClient() -> EmbeddedAuth {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [EmbeddedAuthPasswordMockProtocol.self]
    return Auth0.embeddedAuth(clientId: passwordClientId, domain: passwordDomain, session: URLSession(configuration: config))
}

private func insufficientAuthPassword(session: String,
                                      description: String? = nil,
                                      nextActions: [[String: Any]]) -> Data {
    var json: [String: Any] = [
        "error": "insufficient_authorization",
        "auth_session": session,
        "next": nextActions
    ]
    if let description { json["error_description"] = description }
    // swiftlint:disable:next force_try
    return try! JSONSerialization.data(withJSONObject: json)
}

private func authCodePassword(code: String = "auth0_ac_test123") -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: ["authorization_code": code])
}

private func credentialsPassword(accessToken: String = "test_access_token") -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: [
        "access_token": accessToken,
        "token_type": "Bearer",
        "id_token": "test_id_token",
        "expires_in": 86400
    ])
}

private func responsePassword(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://\(passwordDomain)/")!,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: nil)!
}

/// The fields these tests read from a request body, plus the total number of keys sent.
private struct PasswordRequestBody: Decodable {
    let action: String?
    let password: String?
    let clientId: String?
    let authSession: String?
    let code: String?
    let grantType: String?
    let keyCount: Int

    private struct Key: CodingKey {
        let stringValue: String
        let intValue: Int? = nil

        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
        init(_ name: String) { stringValue = name }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        action = try container.decodeIfPresent(String.self, forKey: Key("action"))
        password = try container.decodeIfPresent(String.self, forKey: Key("password"))
        clientId = try container.decodeIfPresent(String.self, forKey: Key("client_id"))
        authSession = try container.decodeIfPresent(String.self, forKey: Key("auth_session"))
        code = try container.decodeIfPresent(String.self, forKey: Key("code"))
        grantType = try container.decodeIfPresent(String.self, forKey: Key("grant_type"))
        keyCount = container.allKeys.count
    }
}

private func passwordRequestBody(_ request: URLRequest) -> PasswordRequestBody? {
    request.httpBody.flatMap { try? JSONDecoder().decode(PasswordRequestBody.self, from: $0) }
}

/// Establishes an auth session by running authorize() through the mock.
private func establishPasswordSession(_ client: EmbeddedAuth, session: String = "sess_001") async {
    EmbeddedAuthPasswordMockProtocol.requestHandler = { _ in
        (responsePassword(status: 403),
         insufficientAuthPassword(session: session, nextActions: [["action": "action:verify:password:v1"]]))
    }
    _ = try? await client.authorize(connection: "test-connection").start()
}

// MARK: - Suite

@Suite(.serialized)
struct EmbeddedAuthPasswordClientTests {

    // MARK: Capabilities

    @Test func capabilitiesAllIncludesVerifyPassword() {
        let all = EmbeddedCapability.all.map { $0.action.rawValue }
        #expect(all.contains("action:verify:password:v1"))
    }

    // MARK: verifyPassword — request

    @Test func verifyPasswordFailsLocallyWithNoSession() async {
        let sut = makePasswordClient()
        do {
            _ = try await sut.verifyPassword("hunter2").start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
            #expect(error.statusCode == 0)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyPasswordSendsCorrectBody() async {
        let sut = makePasswordClient()
        await establishPasswordSession(sut, session: "sess_001")

        nonisolated(unsafe) var body: PasswordRequestBody?
        nonisolated(unsafe) var path: String?
        nonisolated(unsafe) var method: String?
        EmbeddedAuthPasswordMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responsePassword(status: 200), credentialsPassword())
            }
            path = req.url?.path
            method = req.httpMethod
            body = passwordRequestBody(req)
            return (responsePassword(status: 200), authCodePassword())
        }
        _ = try? await sut.verifyPassword("hunter2").start()

        #expect(path == "/e/authorize")
        #expect(method == "POST")
        #expect(body?.action == "action:verify:password:v1")
        #expect(body?.password == "hunter2")
        #expect(body?.clientId == passwordClientId)
        #expect(body?.authSession == "sess_001")
        #expect(body?.keyCount == 4)
    }

    // MARK: verifyPassword — success

    @Test func verifyPasswordReturnsCredentialsAfterCodeExchange() async {
        let sut = makePasswordClient()
        await establishPasswordSession(sut)

        nonisolated(unsafe) var tokenBody: PasswordRequestBody?
        EmbeddedAuthPasswordMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                tokenBody = passwordRequestBody(req)
                return (responsePassword(status: 200), credentialsPassword(accessToken: "the_access_token"))
            }
            return (responsePassword(status: 200), authCodePassword(code: "auth0_ac_theCode"))
        }
        do {
            let credentials = try await sut.verifyPassword("hunter2").start()
            #expect(credentials.accessToken == "the_access_token")
            #expect(tokenBody?.code == "auth0_ac_theCode")
            #expect(tokenBody?.grantType == "authorization_code")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func verifyPasswordClearsSessionOnSuccess() async {
        let sut = makePasswordClient()
        await establishPasswordSession(sut)

        EmbeddedAuthPasswordMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responsePassword(status: 200), credentialsPassword())
            }
            return (responsePassword(status: 200), authCodePassword())
        }
        _ = try? await sut.verifyPassword("hunter2").start()

        do {
            _ = try await sut.verifyPassword("hunter2").start()
            Issue.record("Expected no_active_session after successful code exchange")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyPasswordSupportsCallbackAPI() async {
        let sut = makePasswordClient()
        await establishPasswordSession(sut)

        EmbeddedAuthPasswordMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responsePassword(status: 200), credentialsPassword(accessToken: "cb_token"))
            }
            return (responsePassword(status: 200), authCodePassword())
        }
        let credentials = await withCheckedContinuation { continuation in
            sut.verifyPassword("hunter2").start { result in
                continuation.resume(returning: try? result.get())
            }
        }
        #expect(credentials?.accessToken == "cb_token")
    }

    // MARK: verifyPassword — failures

    @Test func verifyPasswordWrongPasswordIsRetryableAndRotatesSession() async {
        let sut = makePasswordClient()
        await establishPasswordSession(sut, session: "sess_001")

        EmbeddedAuthPasswordMockProtocol.requestHandler = { _ in
            (responsePassword(status: 403),
             insufficientAuthPassword(session: "sess_002",
                                      description: "invalid_identifier_or_password",
                                      nextActions: [["action": "action:verify:password:v1"]]))
        }
        do {
            _ = try await sut.verifyPassword("wrong").start()
            Issue.record("Expected continuation error")
        } catch let error as EmbeddedAuthError {
            guard case .insufficientAuthorization(.invalidIdentifierOrPassword, let actions) = error.reason else {
                Issue.record("Expected .invalidIdentifierOrPassword, got \(error.reason)"); return
            }
            #expect(actions == [.verifyPassword])
        } catch {
            Issue.record("Wrong error type: \(error)")
        }

        // Retry uses the rotated session
        nonisolated(unsafe) var body: PasswordRequestBody?
        EmbeddedAuthPasswordMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responsePassword(status: 200), credentialsPassword())
            }
            body = passwordRequestBody(req)
            return (responsePassword(status: 200), authCodePassword())
        }
        _ = try? await sut.verifyPassword("right").start()
        #expect(body?.authSession == "sess_002")
        #expect(body?.password == "right")
    }

    @Test func verifyPasswordMfaRequiredRotatesSessionAndExposesNextActions() async {
        let sut = makePasswordClient()
        await establishPasswordSession(sut, session: "sess_001")

        EmbeddedAuthPasswordMockProtocol.requestHandler = { _ in
            (responsePassword(status: 403),
             insufficientAuthPassword(session: "sess_002",
                                      nextActions: [["action": "action:challenge:push:v1", "index": 0, "name": "Diego's iPhone"]]))
        }
        do {
            _ = try await sut.verifyPassword("hunter2").start()
            Issue.record("Expected MFA continuation")
        } catch let error as EmbeddedAuthError {
            guard case .insufficientAuthorization(.none, let actions) = error.reason else {
                Issue.record("Expected plain continuation, got \(error.reason)"); return
            }
            #expect(actions == [.challengePush(index: 0, name: "Diego's iPhone")])
        } catch {
            Issue.record("Wrong error type: \(error)")
        }

        // The MFA step continues on the rotated session
        nonisolated(unsafe) var body: PasswordRequestBody?
        EmbeddedAuthPasswordMockProtocol.requestHandler = { req in
            body = passwordRequestBody(req)
            return (responsePassword(status: 403),
                    insufficientAuthPassword(session: "sess_003",
                                             nextActions: [["action": "action:verify:oob:v1", "poll_in_ms": 2000]]))
        }
        _ = try? await sut.challengePush(index: 0).start()
        #expect(body?.authSession == "sess_002")
    }

    @Test func verifyPasswordTooManyAttemptsClearsSession() async {
        let sut = makePasswordClient()
        await establishPasswordSession(sut)

        EmbeddedAuthPasswordMockProtocol.requestHandler = { _ in
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: [
                "error": "too_many_requests",
                "error_description": "too_many_attempts"
            ])
            return (responsePassword(status: 429), data)
        }
        do {
            _ = try await sut.verifyPassword("hunter2").start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            guard case .tooManyAttempts = error.reason else {
                Issue.record("Expected .tooManyAttempts, got \(error.reason)"); return
            }
        } catch {
            Issue.record("Wrong error type: \(error)")
        }

        do {
            _ = try await sut.verifyPassword("hunter2").start()
            Issue.record("Expected no_active_session after terminal error")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyPasswordExchangeFailureClearsSession() async {
        let sut = makePasswordClient()
        await establishPasswordSession(sut)

        EmbeddedAuthPasswordMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                // swiftlint:disable:next force_try
                let data = try! JSONSerialization.data(withJSONObject: ["error": "invalid_grant"])
                return (responsePassword(status: 403), data)
            }
            return (responsePassword(status: 200), authCodePassword())
        }
        do {
            _ = try await sut.verifyPassword("hunter2").start()
            Issue.record("Expected exchange failure")
        } catch let error as EmbeddedAuthError {
            guard case .sessionExpired = error.reason else {
                Issue.record("Expected .sessionExpired, got \(error.reason)"); return
            }
        } catch {
            Issue.record("Wrong error type: \(error)")
        }

        do {
            _ = try await sut.verifyPassword("hunter2").start()
            Issue.record("Expected no_active_session after exchange failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyPasswordNetworkFailurePreservesSession() async {
        let sut = makePasswordClient()
        await establishPasswordSession(sut, session: "sess_001")

        EmbeddedAuthPasswordMockProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await sut.verifyPassword("hunter2").start()
            Issue.record("Expected network failure")
        } catch let error as EmbeddedAuthError {
            guard case .network = error.reason else {
                Issue.record("Expected .network, got \(error.reason)"); return
            }
        } catch {
            Issue.record("Wrong error type: \(error)")
        }

        // Same step can be retried on the original session
        nonisolated(unsafe) var body: PasswordRequestBody?
        EmbeddedAuthPasswordMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responsePassword(status: 200), credentialsPassword())
            }
            body = passwordRequestBody(req)
            return (responsePassword(status: 200), authCodePassword())
        }
        _ = try? await sut.verifyPassword("hunter2").start()
        #expect(body?.authSession == "sess_001")
    }

    // MARK: verifyPassword — empty password

    @Test func verifyPasswordEmptyPasswordFailsLocallyWithoutNetworkCall() async {
        let sut = makePasswordClient()
        await establishPasswordSession(sut)

        nonisolated(unsafe) var requestCount = 0
        EmbeddedAuthPasswordMockProtocol.requestHandler = { _ in
            requestCount += 1
            return (responsePassword(status: 200), authCodePassword())
        }
        do {
            _ = try await sut.verifyPassword("").start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            guard case .invalidRequest = error.reason else {
                Issue.record("Expected .invalidRequest, got \(error.reason)"); return
            }
            #expect(error.statusCode == 0)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
        #expect(requestCount == 0)
    }

    @Test func verifyPasswordEmptyPasswordPreservesSessionForRetry() async {
        let sut = makePasswordClient()
        await establishPasswordSession(sut, session: "sess_001")

        // If the empty password reached the server it would answer 400 invalid_request,
        // which ends the flow — so the retry below only works when nothing was sent.
        EmbeddedAuthPasswordMockProtocol.requestHandler = { _ in
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: ["error": "invalid_request"])
            return (responsePassword(status: 400), data)
        }
        _ = try? await sut.verifyPassword("").start()

        nonisolated(unsafe) var body: PasswordRequestBody?
        EmbeddedAuthPasswordMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responsePassword(status: 200), credentialsPassword(accessToken: "retry_token"))
            }
            body = passwordRequestBody(req)
            return (responsePassword(status: 200), authCodePassword())
        }
        do {
            let credentials = try await sut.verifyPassword("hunter2").start()
            #expect(credentials.accessToken == "retry_token")
            #expect(body?.authSession == "sess_001")
        } catch {
            Issue.record("Retry after empty password should succeed, got: \(error)")
        }
    }

    // MARK: Full flow

    @Test func fullIdentifyThenPasswordFlowReturnsCredentials() async throws {
        let sut = makePasswordClient()

        EmbeddedAuthPasswordMockProtocol.requestHandler = { _ in
            (responsePassword(status: 403),
             insufficientAuthPassword(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()

        EmbeddedAuthPasswordMockProtocol.requestHandler = { _ in
            (responsePassword(status: 403),
             insufficientAuthPassword(session: "sess_002", nextActions: [["action": "action:verify:password:v1"]]))
        }
        do {
            _ = try await sut.identify("user@example.com", type: .email).start()
            Issue.record("Expected continuation")
        } catch let error as EmbeddedAuthError {
            guard case .insufficientAuthorization(_, let actions) = error.reason else {
                Issue.record("Expected continuation, got \(error.reason)"); return
            }
            #expect(actions == [.verifyPassword])
        }

        nonisolated(unsafe) var body: PasswordRequestBody?
        EmbeddedAuthPasswordMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responsePassword(status: 200), credentialsPassword(accessToken: "flow_token"))
            }
            body = passwordRequestBody(req)
            return (responsePassword(status: 200), authCodePassword())
        }
        let credentials = try await sut.verifyPassword("hunter2").start()
        #expect(credentials.accessToken == "flow_token")
        #expect(body?.authSession == "sess_002")
    }
}
