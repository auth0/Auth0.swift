import Testing
import Foundation
@testable import Auth0

// Dedicated mock — never share static state with other test suites.
private final class EmbeddedAuthSignupMockProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        // The client verifies ID tokens, so it fetches the signing keys; serve them without involving the handler,
        // so the request bodies and sequences the tests assert on only ever contain the signup calls.
        if request.url?.path == "/.well-known/jwks.json" {
            let (data, response, _) = jwksResponse()(request)
            if let response { client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed) }
            if let data { client?.urlProtocol(self, didLoad: data) }
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        // A request nothing expected fails this one test instead of crashing the whole test process.
        guard let handler = EmbeddedAuthSignupMockProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
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

private let signupClientId = "TEST_CLIENT_ID"
private let signupDomain   = "test.auth0.com"

// MARK: - Helpers

private func makeSignupClient() -> EmbeddedAuth {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [EmbeddedAuthSignupMockProtocol.self]
    return Auth0.embeddedAuth(clientId: signupClientId, domain: signupDomain, session: URLSession(configuration: config))
}

private func signupContinuation(session: String,
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

private func signupAuthCode(code: String = "auth0_ac_test123") -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: ["authorization_code": code])
}

private func signupCredentials(accessToken: String = "test_access_token") -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: [
        "access_token": accessToken,
        "token_type": "Bearer",
        "id_token": generateJWT(iss: "https://\(signupDomain)/", aud: [signupClientId]).string,
        "expires_in": 86400
    ])
}

private func signupErrorBody(_ json: [String: Any]) -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: json)
}

private func signupResponse(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://\(signupDomain)/")!,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: nil)!
}

private let identifyEmailAction: [String: Any] = ["action": "action:identify:email:v1"]
private let identifyPhoneAction: [String: Any] = ["action": "action:identify:phone:v1"]
private let confirmSignupAction: [String: Any] = ["action": "action:signup:confirm:v1"]

private func signupAction(_ identifiers: [String: Any]) -> [String: Any] {
    ["action": "action:signup:v1", "identifiers": identifiers]
}

private func isTokenRequest(_ request: URLRequest) -> Bool {
    request.url?.path.hasSuffix("/oauth/token") == true
}

/// The fields these tests read from a request body, plus the total number of keys sent.
private struct SignupRequestBody: Decodable {
    let action: String?
    let clientId: String?
    let authSession: String?
    let email: String?
    let phone: String?
    let otp: String?
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
        clientId = try container.decodeIfPresent(String.self, forKey: Key("client_id"))
        authSession = try container.decodeIfPresent(String.self, forKey: Key("auth_session"))
        email = try container.decodeIfPresent(String.self, forKey: Key("email"))
        phone = try container.decodeIfPresent(String.self, forKey: Key("phone"))
        otp = try container.decodeIfPresent(String.self, forKey: Key("otp"))
        code = try container.decodeIfPresent(String.self, forKey: Key("code"))
        grantType = try container.decodeIfPresent(String.self, forKey: Key("grant_type"))
        keyCount = container.allKeys.count
    }
}

private struct SignupCapabilitiesBody: Decodable {
    let capabilities: [String]
}

private func signupRequestBody(_ request: URLRequest) -> SignupRequestBody? {
    request.httpBody.flatMap { try? JSONDecoder().decode(SignupRequestBody.self, from: $0) }
}

/// Establishes an auth session by running authorize() through the mock.
private func establishSignupSession(_ client: EmbeddedAuth, session: String = "sess_001") async {
    EmbeddedAuthSignupMockProtocol.requestHandler = { _ in
        (signupResponse(status: 403),
         signupContinuation(session: session,
                            nextActions: [identifyEmailAction, signupAction(["email": ["required": true]])]))
    }
    _ = try? await client.authorize(connection: "test-connection").start()
}

/// The name of a reason's case, since `EmbeddedAuthErrorReason` is not `Equatable`.
private func signupReasonName(_ reason: EmbeddedAuthErrorReason) -> String {
    String(describing: reason).prefix { $0 != "(" }.description
}

/// Collects what a `DefaultLogger` writes so a test can inspect it.
private final class SignupCapturingOutput: LoggerOutput, @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [String] = []

    var text: String {
        lock.lock()
        defer { lock.unlock() }
        return messages.joined(separator: "\n")
    }

    func log(message: String) {
        lock.lock()
        messages.append(message)
        lock.unlock()
    }

    func newLine() {
        log(message: "")
    }
}

// MARK: - Suite

// swiftlint:disable:next type_body_length
@Suite(.serialized)
struct EmbeddedAuthSignupClientTests {

    init() {
        EmbeddedAuthSignupMockProtocol.requestHandler = nil
    }

    /// Asserts the flow has ended: any further step fails locally.
    private func expectNoSession(_ sut: EmbeddedAuth, sourceLocation: SourceLocation = #_sourceLocation) async {
        let next = await #expect(throws: EmbeddedAuthError.self, sourceLocation: sourceLocation) {
            _ = try await sut.signup().start()
        }
        #expect(next?.code == "no_active_session", sourceLocation: sourceLocation)
    }

    // MARK: Capabilities

    @Test func capabilitiesAllIncludesSignup() {
        let all = EmbeddedCapability.all.map { $0.action.rawValue }
        #expect(all.contains("action:signup:v1"))
        #expect(all.contains("action:signup:confirm:v1"))
    }

    @Test func authorizeAdvertisesSignupCapabilities() async {
        let sut = makeSignupClient()
        nonisolated(unsafe) var capabilities: [String] = []
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            let body = req.httpBody.flatMap { try? JSONDecoder().decode(SignupCapabilitiesBody.self, from: $0) }
            capabilities = body?.capabilities ?? []
            return (signupResponse(status: 403), signupContinuation(session: "sess_001", nextActions: [identifyEmailAction]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()
        #expect(capabilities.contains("action:signup:v1"))
        #expect(capabilities.contains("action:signup:confirm:v1"))
    }

    @Test func authorizeCanOmitSignupCapabilitiesForLogin() async {
        let sut = makeSignupClient()
        nonisolated(unsafe) var capabilities: [String] = []
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            let body = req.httpBody.flatMap { try? JSONDecoder().decode(SignupCapabilitiesBody.self, from: $0) }
            capabilities = body?.capabilities ?? []
            return (signupResponse(status: 403), signupContinuation(session: "sess_001", nextActions: [identifyEmailAction]))
        }
        let loginCapabilities = EmbeddedCapability.all.filter { $0 != .signup && $0 != .confirmSignup }
        _ = try? await sut.authorize(connection: "test-connection",
                                     capabilities: loginCapabilities,
                                     scope: "openid",
                                     audience: nil).start()
        #expect(capabilities.contains("action:identify:email:v1"))
        #expect(!capabilities.contains("action:signup:v1"))
        #expect(!capabilities.contains("action:signup:confirm:v1"))
    }

    // MARK: signup() — request

    @Test func signupFailsLocallyWithNoSessionAndMakesNoRequest() async {
        let sut = makeSignupClient()
        nonisolated(unsafe) var requestCount = 0
        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in
            requestCount += 1
            return (signupResponse(status: 403), signupContinuation(session: "sess_x", nextActions: []))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.signup().start()
        }
        #expect(error?.code == "no_active_session")
        #expect(error?.statusCode == 0)
        #expect(requestCount == 0)
    }

    @Test func signupSendsCorrectBody() async {
        let sut = makeSignupClient()
        await establishSignupSession(sut, session: "sess_001")

        nonisolated(unsafe) var body: SignupRequestBody?
        nonisolated(unsafe) var path: String?
        nonisolated(unsafe) var method: String?
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            path = req.url?.path
            method = req.httpMethod
            body = signupRequestBody(req)
            return (signupResponse(status: 403), signupContinuation(session: "sess_002", nextActions: [identifyEmailAction]))
        }
        _ = try? await sut.signup().start()

        #expect(path == "/e/authorize")
        #expect(method == "POST")
        #expect(body?.action == "action:signup:v1")
        #expect(body?.clientId == signupClientId)
        #expect(body?.authSession == "sess_001")
        #expect(body?.keyCount == 3)
    }

    // MARK: signup() — continuation

    @Test func signupContinuationRotatesSessionAndExposesNextActions() async {
        let sut = makeSignupClient()
        await establishSignupSession(sut, session: "sess_001")

        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in
            (signupResponse(status: 403),
             signupContinuation(session: "sess_002",
                                nextActions: [["action": "action:challenge:email:v1", "index": 0, "identifier": "al**@example.com"]]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.signup().start()
        }
        guard case .insufficientAuthorization(.none, let actions) = error?.reason else {
            Issue.record("Expected plain continuation, got \(String(describing: error?.reason))"); return
        }
        #expect(actions == [.challengeEmail(index: 0, identifier: "al**@example.com")])

        // The next step continues on the rotated session
        nonisolated(unsafe) var body: SignupRequestBody?
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            body = signupRequestBody(req)
            return (signupResponse(status: 403), signupContinuation(session: "sess_003", nextActions: []))
        }
        _ = try? await sut.challengeEmail(index: 0).start()
        #expect(body?.authSession == "sess_002")
    }

    @Test func signupUnexpectedSuccessClearsSession() async {
        let sut = makeSignupClient()
        await establishSignupSession(sut)

        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in
            (signupResponse(status: 200), Data("{}".utf8))
        }
        // An intermediate step is never expected to succeed; the SDK forwards it and ends the flow.
        _ = try? await sut.signup().start()
        await expectNoSession(sut)
    }

    @Test func signupSupportsCallbackAPI() async {
        let sut = makeSignupClient()
        await establishSignupSession(sut)

        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in
            (signupResponse(status: 403), signupContinuation(session: "sess_002", nextActions: [identifyEmailAction]))
        }
        let actions: [NextAction]? = await withCheckedContinuation { continuation in
            sut.signup().start { result in
                if case .failure(let error) = result, case .insufficientAuthorization(_, let next) = error.reason {
                    continuation.resume(returning: next)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
        #expect(actions == [.identifyEmail])
    }

    // MARK: signup() — failures

    @Test(arguments: [
        (403, "access_denied", "validation_error", "accessDenied"),
        (403, "access_denied", "denied", "accessDenied"),
        (403, "access_denied", "no_next_steps", "noNextSteps"),
        (429, "too_many_requests", "too_many_attempts", "tooManyAttempts"),
        (429, "too_many_requests", "ip_blocked", "ipBlocked"),
        (429, "too_many_requests", "too_many_logins", "tooManyLogins"),
        (400, "invalid_request", "Invalid request", "invalidRequest")
    ])
    func signupTerminalErrorsClearSession(status: Int, code: String, description: String, expectedReason: String) async {
        let sut = makeSignupClient()
        await establishSignupSession(sut)

        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in
            (signupResponse(status: status), signupErrorBody(["error": code, "error_description": description]))
        }
        let first = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.signup().start()
        }
        #expect(first.map { signupReasonName($0.reason) } == expectedReason)
        await expectNoSession(sut)
    }

    @Test func signupNetworkFailureKeepsSessionForRetry() async {
        let sut = makeSignupClient()
        await establishSignupSession(sut, session: "sess_001")

        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.signup().start()
        }
        guard case .network = error?.reason else {
            Issue.record("Expected .network, got \(String(describing: error?.reason))"); return
        }

        nonisolated(unsafe) var body: SignupRequestBody?
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            body = signupRequestBody(req)
            return (signupResponse(status: 403), signupContinuation(session: "sess_002", nextActions: [identifyEmailAction]))
        }
        _ = try? await sut.signup().start()
        #expect(body?.authSession == "sess_001")
    }

    // MARK: confirmSignup() — request

    @Test func confirmSignupFailsLocallyWithNoSessionAndMakesNoRequest() async {
        let sut = makeSignupClient()
        nonisolated(unsafe) var requestCount = 0
        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in
            requestCount += 1
            return (signupResponse(status: 200), signupAuthCode())
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup().start()
        }
        #expect(error?.code == "no_active_session")
        #expect(error?.statusCode == 0)
        #expect(requestCount == 0)
    }

    @Test func confirmSignupSendsCorrectBody() async {
        let sut = makeSignupClient()
        await establishSignupSession(sut, session: "sess_001")

        nonisolated(unsafe) var body: SignupRequestBody?
        nonisolated(unsafe) var path: String?
        nonisolated(unsafe) var method: String?
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            if isTokenRequest(req) { return (signupResponse(status: 200), signupCredentials()) }
            path = req.url?.path
            method = req.httpMethod
            body = signupRequestBody(req)
            return (signupResponse(status: 200), signupAuthCode())
        }
        _ = try? await sut.confirmSignup().start()

        #expect(path == "/e/authorize")
        #expect(method == "POST")
        #expect(body?.action == "action:signup:confirm:v1")
        #expect(body?.clientId == signupClientId)
        #expect(body?.authSession == "sess_001")
        #expect(body?.keyCount == 3)
    }

    // MARK: confirmSignup() — success

    @Test func confirmSignupReturnsCredentialsAfterCodeExchangeAndClearsSession() async throws {
        let sut = makeSignupClient()
        await establishSignupSession(sut)

        nonisolated(unsafe) var tokenBody: SignupRequestBody?
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            if isTokenRequest(req) {
                tokenBody = signupRequestBody(req)
                return (signupResponse(status: 200), signupCredentials(accessToken: "the_access_token"))
            }
            return (signupResponse(status: 200), signupAuthCode(code: "auth0_ac_theCode"))
        }
        let credentials = try await sut.confirmSignup().start()
        #expect(credentials.accessToken == "the_access_token")
        #expect(tokenBody?.code == "auth0_ac_theCode")
        #expect(tokenBody?.grantType == "authorization_code")

        let next = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup().start()
        }
        #expect(next?.code == "no_active_session")
    }

    @Test func confirmSignupSupportsCallbackAPI() async {
        let sut = makeSignupClient()
        await establishSignupSession(sut)

        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            if isTokenRequest(req) { return (signupResponse(status: 200), signupCredentials(accessToken: "cb_token")) }
            return (signupResponse(status: 200), signupAuthCode())
        }
        let credentials = await withCheckedContinuation { continuation in
            sut.confirmSignup().start { result in
                continuation.resume(returning: try? result.get())
            }
        }
        #expect(credentials?.accessToken == "cb_token")
    }

    // MARK: confirmSignup() — failures

    @Test func confirmSignupNetworkFailureOnTheTokenExchangeKeepsTheSessionForRetry() async throws {
        let sut = makeSignupClient()
        await establishSignupSession(sut, session: "sess_001")

        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            if isTokenRequest(req) { throw URLError(.notConnectedToInternet) }
            return (signupResponse(status: 200), signupAuthCode())
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup().start()
        }
        guard case .network = error?.reason else {
            Issue.record("Expected .network, got \(String(describing: error?.reason))"); return
        }

        // Only the token call failed, so the step can be retried on the same session.
        nonisolated(unsafe) var authorizeBody: SignupRequestBody?
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            if isTokenRequest(req) { return (signupResponse(status: 200), signupCredentials(accessToken: "retry_token")) }
            authorizeBody = signupRequestBody(req)
            return (signupResponse(status: 200), signupAuthCode(code: "auth0_ac_second"))
        }
        let credentials = try await sut.confirmSignup().start()
        #expect(credentials.accessToken == "retry_token")
        #expect(authorizeBody?.authSession == "sess_001")
    }

    @Test func confirmSignupNetworkFailureOnTheAuthorizeCallKeepsTheSession() async {
        let sut = makeSignupClient()
        await establishSignupSession(sut, session: "sess_001")

        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in throw URLError(.timedOut) }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup().start()
        }
        guard case .network = error?.reason else {
            Issue.record("Expected .network, got \(String(describing: error?.reason))"); return
        }

        nonisolated(unsafe) var body: SignupRequestBody?
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            body = signupRequestBody(req)
            return (signupResponse(status: 403), signupContinuation(session: "sess_002", nextActions: []))
        }
        _ = try? await sut.confirmSignup().start()
        #expect(body?.authSession == "sess_001")
    }

    @Test func confirmSignupExchangeFailureClearsSession() async {
        let sut = makeSignupClient()
        await establishSignupSession(sut)

        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            if isTokenRequest(req) {
                return (signupResponse(status: 403), signupErrorBody(["error": "invalid_grant"]))
            }
            return (signupResponse(status: 200), signupAuthCode())
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup().start()
        }
        guard case .sessionExpired = error?.reason else {
            Issue.record("Expected .sessionExpired, got \(String(describing: error?.reason))"); return
        }
        await expectNoSession(sut)
    }

    @Test func confirmSignupMalformedSuccessClearsSession() async {
        let sut = makeSignupClient()
        await establishSignupSession(sut)

        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in
            // 200 without an authorization_code
            (signupResponse(status: 200), Data("{}".utf8))
        }
        let first = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup().start()
        }
        #expect(first.map { signupReasonName($0.reason) } == "unknown")
        await expectNoSession(sut)
    }

    @Test func confirmSignupContinuationRotatesSession() async {
        let sut = makeSignupClient()
        await establishSignupSession(sut, session: "sess_001")

        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in
            (signupResponse(status: 403),
             signupContinuation(session: "sess_002",
                                nextActions: [["action": "action:verify:otp:v1", "channel": "email", "identifier": "al**@example.com"]]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup().start()
        }
        guard case .insufficientAuthorization(_, let actions) = error?.reason else {
            Issue.record("Expected continuation, got \(String(describing: error?.reason))"); return
        }
        #expect(actions == [.verifyOTP(channel: .email, identifier: "al**@example.com")])

        nonisolated(unsafe) var body: SignupRequestBody?
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            body = signupRequestBody(req)
            return (signupResponse(status: 403), signupContinuation(session: "sess_003", nextActions: []))
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()
        #expect(body?.authSession == "sess_002")
    }

    @Test(arguments: [
        (403, "access_denied", "validation_error", "accessDenied"),
        (403, "access_denied", "denied", "accessDenied"),
        (403, "access_denied", "no_next_steps", "noNextSteps"),
        (429, "too_many_requests", "too_many_attempts", "tooManyAttempts"),
        (429, "too_many_requests", "ip_blocked", "ipBlocked"),
        (429, "too_many_requests", "too_many_logins", "tooManyLogins"),
        (400, "invalid_request", "Invalid request", "invalidRequest")
    ])
    func confirmSignupTerminalErrorsClearSession(status: Int, code: String, description: String, expectedReason: String) async {
        let sut = makeSignupClient()
        await establishSignupSession(sut)

        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in
            (signupResponse(status: status), signupErrorBody(["error": code, "error_description": description]))
        }
        let first = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup().start()
        }
        #expect(first.map { signupReasonName($0.reason) } == expectedReason)
        await expectNoSession(sut)
    }

    // MARK: Full flows

    /// Walks a sign-up from `authorize` to credentials and checks that every step used the session the previous step returned.
    private func runFullFlow(identifier: String,
                             type: IdentifierType,
                             identifyAction: [String: Any],
                             identifierKey: String,
                             channel: String) async throws {
        let sut = makeSignupClient()
        nonisolated(unsafe) var bodies: [SignupRequestBody] = []

        // authorize -> identify or sign up
        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in
            (signupResponse(status: 403),
             signupContinuation(session: "sess_1",
                                nextActions: [identifyAction, signupAction([identifierKey: ["required": true]])]))
        }
        let authorized = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.authorize(connection: "test-connection").start()
        }
        guard case .insufficientAuthorization(_, let offered) = authorized?.reason else {
            Issue.record("Expected continuation, got \(String(describing: authorized?.reason))"); return
        }
        #expect(offered.contains(.signup(identifiers: [SignupIdentifier(type: type, isRequired: true)])))

        // signup -> identify
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            bodies.append(try #require(signupRequestBody(req)))
            return (signupResponse(status: 403), signupContinuation(session: "sess_2", nextActions: [identifyAction]))
        }
        _ = try? await sut.signup().start()

        // identify -> verify OTP
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            bodies.append(try #require(signupRequestBody(req)))
            return (signupResponse(status: 403),
                    signupContinuation(session: "sess_3",
                                       nextActions: [["action": "action:verify:otp:v1", "channel": channel]]))
        }
        _ = try? await sut.identify(identifier, type: type).start()

        // verify OTP -> confirm signup
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            bodies.append(try #require(signupRequestBody(req)))
            return (signupResponse(status: 403), signupContinuation(session: "sess_4", nextActions: [confirmSignupAction]))
        }
        let verified = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyOtp("123456", type: .oob).start()
        }
        guard case .insufficientAuthorization(_, let confirmActions) = verified?.reason else {
            Issue.record("Expected continuation, got \(String(describing: verified?.reason))"); return
        }
        #expect(confirmActions == [.confirmSignup])

        // confirm signup -> credentials
        EmbeddedAuthSignupMockProtocol.requestHandler = { req in
            if isTokenRequest(req) { return (signupResponse(status: 200), signupCredentials(accessToken: "signup_token")) }
            bodies.append(try #require(signupRequestBody(req)))
            return (signupResponse(status: 200), signupAuthCode())
        }
        let credentials = try await sut.confirmSignup().start()
        #expect(credentials.accessToken == "signup_token")

        #expect(bodies.map(\.authSession) == ["sess_1", "sess_2", "sess_3", "sess_4"])
        #expect(bodies.map(\.action) == ["action:signup:v1",
                                          identifyAction["action"] as? String,
                                          "action:verify:otp:v1",
                                          "action:signup:confirm:v1"])
        #expect(bodies[1].email == (type == .email ? identifier : nil))
        #expect(bodies[1].phone == (type == .phone ? identifier : nil))
        await expectNoSession(sut)
    }

    @Test func fullEmailOnlySignupFlowReturnsCredentials() async throws {
        try await runFullFlow(identifier: "new.user@example.com",
                              type: .email,
                              identifyAction: identifyEmailAction,
                              identifierKey: "email",
                              channel: "email")
    }

    @Test func fullPhoneOnlySignupFlowReturnsCredentials() async throws {
        try await runFullFlow(identifier: "+15551234567",
                              type: .phone,
                              identifyAction: identifyPhoneAction,
                              identifierKey: "phone_number",
                              channel: "sms")
    }

    // MARK: Logging

    @Test func signupLogsTheActionButNeverTheSession() async {
        let sut = makeSignupClient()
        await establishSignupSession(sut, session: "sess_super_secret_value")

        // Attach the logger only now, so everything it records belongs to the signup call.
        let output = SignupCapturingOutput()
        let logged = sut.using(logger: DefaultLogger(output: output))
        EmbeddedAuthSignupMockProtocol.requestHandler = { _ in
            (signupResponse(status: 403), signupContinuation(session: "sess_rotated_value", nextActions: [identifyEmailAction]))
        }
        _ = try? await logged.signup().start()

        // The logger writes asynchronously, in order: wait for the response to be logged too.
        for _ in 0..<100 where !output.text.contains("insufficient_authorization") {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        #expect(output.text.contains("action:signup:v1"))
        #expect(output.text.contains("<REDACTED>"))
        #expect(!output.text.contains("sess_super_secret_value"))
        #expect(!output.text.contains("sess_rotated_value"))
    }
}
