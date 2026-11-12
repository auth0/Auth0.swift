import Testing
import Foundation
@testable import Auth0

// Dedicated mock — never share static state with other test suites.
private final class EmbeddedAuthPasswordSignupMockProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        // A request nothing expected fails this one test instead of crashing the whole test process.
        guard let handler = EmbeddedAuthPasswordSignupMockProtocol.requestHandler else {
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

private typealias Mock = EmbeddedAuthPasswordSignupMockProtocol

private let pwClientId = "TEST_CLIENT_ID"
private let pwDomain   = "test.auth0.com"

// Dummy fixture values only.
private let dummyPassword = "Dummy-Password-123"
private let otherDummyPassword = "Another-Dummy-456"

// MARK: - Helpers

private func makeClient() -> EmbeddedAuth {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [Mock.self]
    return Auth0.embeddedAuth(clientId: pwClientId, domain: pwDomain, session: URLSession(configuration: config))
}

private func continuation(session: String, description: String? = nil, next: [[String: Any]]) -> Data {
    var json: [String: Any] = [
        "error": "insufficient_authorization",
        "auth_session": session,
        "next": next
    ]
    if let description { json["error_description"] = description }
    return jsonData(json)
}

private func jsonData(_ json: [String: Any]) -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: json)
}

private func authCode(_ code: String = "auth0_ac_test123") -> Data {
    jsonData(["authorization_code": code])
}

private func credentialsBody(accessToken: String = "test_access_token") -> Data {
    jsonData([
        "access_token": accessToken,
        "token_type": "Bearer",
        "id_token": "test_id_token",
        "expires_in": 86400
    ])
}

private func response(_ status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://\(pwDomain)/")!,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: nil)!
}

private func isTokenRequest(_ request: URLRequest) -> Bool {
    request.url?.path.hasSuffix("/oauth/token") == true
}

/// The JSON body of a request.
private func bodyJSON(_ request: URLRequest) -> [String: Any] {
    request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
}

private let identifyEmailAction: [String: Any] = ["action": "action:identify:email:v1"]

/// What the first response of a flow offers.
private enum Offer {
    /// No sign-up entry at all.
    case noSignupOffer
    /// A sign-up entry without `authentication_methods`.
    case noPassword
    case requiredPassword
    case optionalPassword
}

private func signupOffer(_ offer: Offer) -> [[String: Any]] {
    var entry: [String: Any] = ["action": "action:signup:v1", "identifiers": ["email": ["required": true]]]
    switch offer {
    case .noSignupOffer: return []
    case .noPassword: break
    case .requiredPassword: entry["authentication_methods"] = ["password": ["required": true]]
    case .optionalPassword: entry["authentication_methods"] = ["password": ["required": false]]
    }
    return [entry]
}

private func confirmAction(options: [String: Any]? = ["min_length": 8, "character_types": ["lowercase", "number"]]) -> [String: Any] {
    var entry: [String: Any] = ["action": "action:signup:confirm:v1"]
    if let options { entry["password_complexity_options"] = options }
    return entry
}

/// Collects the non-token request bodies a flow sent, in order.
private final class Recorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storedBodies: [[String: Any]] = []

    var bodies: [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        return storedBodies
    }

    func record(_ body: [String: Any]) {
        lock.lock()
        storedBodies.append(body)
        lock.unlock()
    }

    var actions: [String?] { bodies.map { $0["action"] as? String } }
    var sessions: [String?] { bodies.map { $0["auth_session"] as? String } }
}

/// Walks authorize -> signup -> identify -> verify OTP and returns what the last response offers. The session after
/// it is `sess_4`.
@discardableResult
private func reachConfirm(_ client: EmbeddedAuth,
                          offer: Offer,
                          confirm: [String: Any] = confirmAction(),
                          recorder: Recorder = Recorder()) async -> [NextAction] {
    let steps: [(session: String, next: [[String: Any]])] = [
        ("sess_1", [identifyEmailAction] + signupOffer(offer)),
        ("sess_2", [identifyEmailAction]),
        ("sess_3", [["action": "action:verify:otp:v1", "channel": "email"]]),
        ("sess_4", [confirm])
    ]
    nonisolated(unsafe) var index = 0
    Mock.requestHandler = { req in
        recorder.record(bodyJSON(req))
        let step = steps[min(index, steps.count - 1)]
        index += 1
        return (response(403), continuation(session: step.session, next: step.next))
    }
    _ = try? await client.authorize(connection: "test-connection").start()
    _ = try? await client.signup().start()
    _ = try? await client.identify("new.user@example.com", type: .email).start()
    let error = await #expect(throws: EmbeddedAuthError.self) {
        _ = try await client.verifyOtp("123456", type: .oob).start()
    }
    guard case .insufficientAuthorization(_, let actions)? = error?.reason else { return [] }
    return actions
}

/// The password description of the first `confirmSignup` entry.
private func passwordOffer(in actions: [NextAction]) -> SignupPassword? {
    for case .confirmSignup(let password) in actions { return password }
    return nil
}

/// The name of the sub-reason and the offered actions, when the error is a continuation.
private func continuationInfo(_ error: EmbeddedAuthError?) -> (sub: String, actions: [NextAction])? {
    guard case .insufficientAuthorization(let sub, let actions)? = error?.reason else { return nil }
    return (String(describing: sub), actions)
}

/// The name of a reason's case, since `EmbeddedAuthErrorReason` is not `Equatable`.
private func reasonName(_ reason: EmbeddedAuthErrorReason?) -> String? {
    reason.map { String(describing: $0).prefix { $0 != "(" }.description }
}

/// Collects what a `DefaultLogger` writes so a test can inspect it.
private final class CapturingOutput: LoggerOutput, @unchecked Sendable {
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

/// An `EmbeddedAuth` that does not implement `confirmSignup(password:)`: it relies on the default implementation and
/// forwards every other step to a real client.
private struct PartialEmbeddedAuth: EmbeddedAuth {
    let inner: EmbeddedAuth

    var auth0ClientInfo: Auth0ClientInfo {
        get { inner.auth0ClientInfo }
        set { _ = newValue }
    }

    var logger: Logger? {
        get { inner.logger }
        set { _ = newValue }
    }

    func authorize(connection: String, capabilities: [EmbeddedCapability], scope: String, audience: String?) -> Request<Void, EmbeddedAuthError> {
        inner.authorize(connection: connection, capabilities: capabilities, scope: scope, audience: audience)
    }
    func identify(_ identifier: String, type: IdentifierType) -> Request<Void, EmbeddedAuthError> { inner.identify(identifier, type: type) }
    func challengeEmail(index: Int) -> Request<Void, EmbeddedAuthError> { inner.challengeEmail(index: index) }
    func verifyOtp(_ otp: String, type: OtpType) -> Request<Credentials, EmbeddedAuthError> { inner.verifyOtp(otp, type: type) }
    func verifyPassword(_ password: String) -> Request<Credentials, EmbeddedAuthError> { inner.verifyPassword(password) }
    func challengePhone(index: Int, deliveryMethod: PhoneDeliveryMethod) -> Request<Void, EmbeddedAuthError> {
        inner.challengePhone(index: index, deliveryMethod: deliveryMethod)
    }
    func challengePush(index: Int) -> Request<Void, EmbeddedAuthError> { inner.challengePush(index: index) }
    func verifyOob() -> Request<Credentials, EmbeddedAuthError> { inner.verifyOob() }
    func verifyRecoveryCode(_ code: String) -> Request<Void, EmbeddedAuthError> { inner.verifyRecoveryCode(code) }
    func confirmRecoveryCode() -> Request<Credentials, EmbeddedAuthError> { inner.confirmRecoveryCode() }
    func signup() -> Request<Void, EmbeddedAuthError> { inner.signup() }
    func confirmSignup() -> Request<Credentials, EmbeddedAuthError> { inner.confirmSignup() }
}

// MARK: - Suite

// swiftlint:disable:next type_body_length
@Suite(.serialized)
struct EmbeddedAuthPasswordSignupClientTests {

    init() {
        Mock.requestHandler = nil
    }

    /// Asserts the flow has ended: any further step fails locally.
    private func expectNoSession(_ sut: EmbeddedAuth, sourceLocation: SourceLocation = #_sourceLocation) async {
        let next = await #expect(throws: EmbeddedAuthError.self, sourceLocation: sourceLocation) {
            _ = try await sut.confirmSignup(password: dummyPassword).start()
        }
        #expect(next?.code == "no_active_session", sourceLocation: sourceLocation)
    }

    /// A client at the confirm step of a sign-up whose connection collects a required password.
    private func clientAtConfirm(offer: Offer = .requiredPassword) async -> EmbeddedAuth {
        let sut = makeClient()
        await reachConfirm(sut, offer: offer)
        return sut
    }

    // MARK: Capabilities

    @Test func signupCapabilitiesKeepTheirActions() {
        #expect(EmbeddedCapability.confirmSignup.action.rawValue == "action:signup:confirm:v1")
        #expect(EmbeddedCapability.signup.action.rawValue == "action:signup:v1")
    }

    // MARK: Request

    @Test func confirmSignupWithPasswordFailsLocallyWithNoSessionAndMakesNoRequest() async {
        let sut = makeClient()
        nonisolated(unsafe) var requestCount = 0
        Mock.requestHandler = { _ in
            requestCount += 1
            return (response(200), authCode())
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: dummyPassword).start()
        }
        #expect(error?.code == "no_active_session")
        #expect(error?.statusCode == 0)
        let withoutPassword = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: nil).start()
        }
        #expect(withoutPassword?.code == "no_active_session")
        #expect(requestCount == 0)
    }

    @Test func confirmSignupWithPasswordSendsExactlyFourKeys() async {
        let sut = await clientAtConfirm()
        nonisolated(unsafe) var body: [String: Any] = [:]
        nonisolated(unsafe) var path: String?
        nonisolated(unsafe) var method: String?
        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody()) }
            path = req.url?.path
            method = req.httpMethod
            body = bodyJSON(req)
            return (response(200), authCode())
        }
        _ = try? await sut.confirmSignup(password: dummyPassword).start()

        #expect(path == "/e/authorize")
        #expect(method == "POST")
        #expect(Set(body.keys) == ["action", "client_id", "auth_session", "password"])
        #expect(body["action"] as? String == "action:signup:confirm:v1")
        #expect(body["client_id"] as? String == pwClientId)
        #expect(body["auth_session"] as? String == "sess_4")
        #expect(body["password"] as? String == dummyPassword)
    }

    @Test func confirmSignupWithNilPasswordOmitsTheKey() async {
        for call in [0, 1] {
            let sut = await clientAtConfirm()
            nonisolated(unsafe) var body: [String: Any] = [:]
            Mock.requestHandler = { req in
                if isTokenRequest(req) { return (response(200), credentialsBody()) }
                body = bodyJSON(req)
                return (response(200), authCode())
            }
            if call == 0 {
                _ = try? await sut.confirmSignup(password: nil).start()
            } else {
                _ = try? await sut.confirmSignup().start()
            }
            #expect(Set(body.keys) == ["action", "client_id", "auth_session"])
            #expect(body["password"] == nil)
        }
    }

    @Test func confirmSignupSendsAnEmptyPasswordAndDoesNotTrim() async {
        for password in ["", "  padded password  ", "\tTab\n"] {
            let sut = await clientAtConfirm()
            nonisolated(unsafe) var body: [String: Any] = [:]
            Mock.requestHandler = { req in
                if isTokenRequest(req) { return (response(200), credentialsBody()) }
                body = bodyJSON(req)
                return (response(200), authCode())
            }
            _ = try? await sut.confirmSignup(password: password).start()
            #expect(body.keys.contains("password"))
            #expect(body["password"] as? String == password)
        }
    }

    @Test func confirmSignupSendsTheAuth0ClientHeader() async {
        let sut = await clientAtConfirm()
        nonisolated(unsafe) var header: String?
        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody()) }
            header = req.value(forHTTPHeaderField: "Auth0-Client")
            return (response(200), authCode())
        }
        _ = try? await sut.confirmSignup(password: dummyPassword).start()
        #expect(header?.isEmpty == false)
    }

    @Test func confirmSignupOmitsTheAuth0ClientHeaderWhenTrackingIsDisabled() async {
        var sut = await clientAtConfirm()
        sut.tracking(enabled: false)
        nonisolated(unsafe) var requests: [URLRequest] = []
        Mock.requestHandler = { req in
            requests.append(req)
            if isTokenRequest(req) { return (response(200), credentialsBody()) }
            return (response(200), authCode())
        }
        _ = try? await sut.confirmSignup(password: dummyPassword).start()
        #expect(requests.count == 2)
        #expect(requests.allSatisfy { $0.value(forHTTPHeaderField: "Auth0-Client") == nil })
    }

    // MARK: Success

    @Test func confirmSignupWithPasswordReturnsCredentialsAndClearsSession() async throws {
        let sut = await clientAtConfirm()
        nonisolated(unsafe) var tokenBody: [String: Any] = [:]
        Mock.requestHandler = { req in
            if isTokenRequest(req) {
                tokenBody = bodyJSON(req)
                return (response(200), credentialsBody(accessToken: "the_access_token"))
            }
            return (response(200), authCode("auth0_ac_theCode"))
        }
        let credentials = try await sut.confirmSignup(password: dummyPassword).start()
        #expect(credentials.accessToken == "the_access_token")
        #expect(tokenBody["code"] as? String == "auth0_ac_theCode")
        #expect(tokenBody["grant_type"] as? String == "authorization_code")
        #expect(tokenBody["password"] == nil)
        await expectNoSession(sut)
    }

    @Test func confirmSignupWithPasswordSupportsCallbackAPI() async {
        let sut = await clientAtConfirm()
        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody(accessToken: "cb_token")) }
            return (response(200), authCode())
        }
        let credentials = await withCheckedContinuation { continuation in
            sut.confirmSignup(password: dummyPassword).start { result in
                continuation.resume(returning: try? result.get())
            }
        }
        #expect(credentials?.accessToken == "cb_token")
        await expectNoSession(sut)
    }

    // MARK: isRequired follows the flow

    private func isRequired(after offer: Offer) async -> Bool? {
        let sut = makeClient()
        let actions = await reachConfirm(sut, offer: offer)
        return passwordOffer(in: actions)?.isRequired
    }

    @Test func isRequiredIsFalseWhenTheSignupOfferSaidOptional() async {
        #expect(await isRequired(after: .optionalPassword) == false)
    }

    @Test func isRequiredIsTrueWhenTheSignupOfferSaidRequired() async {
        #expect(await isRequired(after: .requiredPassword) == true)
    }

    @Test func isRequiredIsTrueWhenTheOfferHadNoPasswordInformation() async {
        #expect(await isRequired(after: .noPassword) == true)
    }

    @Test func isRequiredIsTrueWhenTheSignupOfferWasNeverSeen() async {
        #expect(await isRequired(after: .noSignupOffer) == true)
    }

    @Test func confirmSignupCarriesTheComplexityHints() async {
        let sut = makeClient()
        let actions = await reachConfirm(sut, offer: .requiredPassword,
                                         confirm: confirmAction(options: ["min_length": 10, "character_types": ["upper", "uppercase", "special"]]))
        let expected = SignupPassword(isRequired: true,
                                      complexity: SignupPasswordComplexity(minLength: 10, characterTypes: [.uppercase, .special]))
        #expect(actions == [.confirmSignup(password: expected)])
    }

    @Test func aNewAuthorizeResetsWhatWasLearnedAboutThePassword() async {
        let sut = makeClient()
        await reachConfirm(sut, offer: .optionalPassword)
        // Same client, new flow: the earlier offer must not leak into it.
        #expect(await isRequiredOnSameClient(sut, offer: .noSignupOffer) == true)
    }

    private func isRequiredOnSameClient(_ sut: EmbeddedAuth, offer: Offer) async -> Bool? {
        let actions = await reachConfirm(sut, offer: offer)
        return passwordOffer(in: actions)?.isRequired
    }

    @Test func aTerminalErrorClearsWhatWasLearnedAboutThePassword() async throws {
        let sut = makeClient()
        await reachConfirm(sut, offer: .optionalPassword)
        let client = try #require(sut as? Auth0EmbeddedAuth)
        #expect(client.signupPasswordRequirement == .optional)

        Mock.requestHandler = { _ in
            (response(403), jsonData(["error": "access_denied", "error_description": "validation_error"]))
        }
        _ = try? await sut.confirmSignup(password: dummyPassword).start()
        #expect(client.currentSession == nil)
        #expect(client.signupPasswordRequirement == nil)
    }

    @Test func aSuccessfulSignupClearsWhatWasLearnedAboutThePassword() async throws {
        let sut = makeClient()
        await reachConfirm(sut, offer: .optionalPassword)
        let client = try #require(sut as? Auth0EmbeddedAuth)
        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody()) }
            return (response(200), authCode())
        }
        _ = try await sut.confirmSignup(password: dummyPassword).start()
        #expect(client.signupPasswordRequirement == nil)
    }

    @Test func passwordRequiredUpgradesTheRequirementToRequired() async {
        let sut = makeClient()
        await reachConfirm(sut, offer: .optionalPassword)
        Mock.requestHandler = { _ in
            (response(403), continuation(session: "sess_5", description: "password_required", next: [confirmAction()]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup().start()
        }
        let info = continuationInfo(error)
        #expect(info?.sub == "passwordRequired")
        #expect(passwordOffer(in: info?.actions ?? [])?.isRequired == true)
    }

    @Test func passwordRequiredUpgradesTheRequirementEvenWhenTheOfferWasNeverSeen() async {
        let sut = makeClient()
        await reachConfirm(sut, offer: .noSignupOffer)
        Mock.requestHandler = { _ in
            (response(403), continuation(session: "sess_5", description: "password_required", next: [confirmAction()]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup().start()
        }
        let info = continuationInfo(error)
        #expect(info?.sub == "passwordRequired")
        #expect(passwordOffer(in: info?.actions ?? [])?.isRequired == true)
    }

    @Test func invalidPasswordKeepsAnOptionalPasswordOptional() async {
        let sut = makeClient()
        await reachConfirm(sut, offer: .optionalPassword)
        Mock.requestHandler = { _ in
            (response(403), continuation(session: "sess_5", description: "invalid_password", next: [confirmAction()]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: "short").start()
        }
        let info = continuationInfo(error)
        #expect(info?.sub == "invalidPassword")
        #expect(passwordOffer(in: info?.actions ?? [])?.isRequired == false)
    }

    // MARK: Recoverable flows

    @Test func passwordRequiredLetsTheCallerRetryWithAPasswordOnTheRotatedSession() async throws {
        let sut = await clientAtConfirm(offer: .requiredPassword)
        nonisolated(unsafe) var firstBody: [String: Any] = [:]
        Mock.requestHandler = { req in
            firstBody = bodyJSON(req)
            return (response(403), continuation(session: "sess_5", description: "password_required", next: [confirmAction()]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup().start()
        }
        #expect(firstBody["password"] == nil)
        let info = continuationInfo(error)
        #expect(info?.sub == "passwordRequired")
        #expect(passwordOffer(in: info?.actions ?? [])?.complexity.minLength == 8)

        nonisolated(unsafe) var body: [String: Any] = [:]
        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody(accessToken: "retry_token")) }
            body = bodyJSON(req)
            return (response(200), authCode())
        }
        let credentials = try await sut.confirmSignup(password: dummyPassword).start()
        #expect(credentials.accessToken == "retry_token")
        #expect(body["auth_session"] as? String == "sess_5")
        #expect(body["password"] as? String == dummyPassword)
    }

    @Test func passwordNotAcceptedLetsTheCallerRetryWithoutAPassword() async throws {
        let sut = await clientAtConfirm(offer: .noPassword)
        Mock.requestHandler = { _ in
            (response(403), continuation(session: "sess_5", description: "password_not_accepted", next: [confirmAction(options: nil)]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: dummyPassword).start()
        }
        let info = continuationInfo(error)
        #expect(info?.sub == "passwordNotAccepted")
        #expect(info?.actions == [.confirmSignup(password: nil)])

        nonisolated(unsafe) var body: [String: Any] = [:]
        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody()) }
            body = bodyJSON(req)
            return (response(200), authCode())
        }
        _ = try await sut.confirmSignup(password: nil).start()
        #expect(body["auth_session"] as? String == "sess_5")
        #expect(Set(body.keys) == ["action", "client_id", "auth_session"])
    }

    @Test func invalidPasswordLetsTheCallerRetryWithAnotherPassword() async throws {
        let sut = await clientAtConfirm(offer: .requiredPassword)
        Mock.requestHandler = { _ in
            (response(403), continuation(session: "sess_5", description: "invalid_password", next: [confirmAction()]))
        }
        let first = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: "short").start()
        }
        #expect(continuationInfo(first)?.sub == "invalidPassword")

        // And again: the flow stays open for as many attempts as the server allows.
        Mock.requestHandler = { _ in
            (response(403), continuation(session: "sess_6", description: "invalid_password", next: [confirmAction()]))
        }
        let second = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: "still short").start()
        }
        #expect(continuationInfo(second)?.sub == "invalidPassword")

        nonisolated(unsafe) var body: [String: Any] = [:]
        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody()) }
            body = bodyJSON(req)
            return (response(200), authCode())
        }
        _ = try await sut.confirmSignup(password: otherDummyPassword).start()
        #expect(body["auth_session"] as? String == "sess_6")
        #expect(body["password"] as? String == otherDummyPassword)
    }

    // MARK: Terminal errors

    @Test(arguments: [
        (403, "access_denied", "password_leaked", "passwordLeaked"),
        (403, "access_denied", "validation_error", "accessDenied"),
        (403, "access_denied", "no_next_steps", "noNextSteps"),
        (429, "too_many_requests", "too_many_attempts", "tooManyAttempts"),
        (429, "too_many_requests", "ip_blocked", "ipBlocked"),
        (429, "too_many_requests", "too_many_logins", "tooManyLogins"),
        (500, "server_error", "Internal error", "unknown")
    ])
    func terminalErrorsClearTheSession(status: Int, code: String, description: String, expectedReason: String) async {
        let sut = await clientAtConfirm()
        Mock.requestHandler = { _ in
            (response(status), jsonData(["error": code, "error_description": description]))
        }
        let first = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: dummyPassword).start()
        }
        #expect(reasonName(first?.reason) == expectedReason)
        await expectNoSession(sut)
    }

    @Test func aPasswordLongerThan2048CharactersIsSentUnmodifiedAndEndsTheFlow() async {
        let sut = await clientAtConfirm()
        let tooLong = String(repeating: "a", count: 2049)
        nonisolated(unsafe) var sent: String?
        Mock.requestHandler = { req in
            sent = bodyJSON(req)["password"] as? String
            return (response(400), jsonData(["error": "invalid_request", "error_description": "Invalid request"]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: tooLong).start()
        }
        #expect(sent == tooLong)
        guard case .invalidRequest? = error?.reason else {
            Issue.record("Expected .invalidRequest, got \(String(describing: error?.reason))"); return
        }
        await expectNoSession(sut)
    }

    @Test func invalidGrantOnTheTokenExchangeEndsTheFlow() async {
        let sut = await clientAtConfirm()
        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(403), jsonData(["error": "invalid_grant"])) }
            return (response(200), authCode())
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: dummyPassword).start()
        }
        guard case .sessionExpired? = error?.reason else {
            Issue.record("Expected .sessionExpired, got \(String(describing: error?.reason))"); return
        }
        await expectNoSession(sut)
    }

    @Test func aMalformedSuccessResponseEndsTheFlow() async {
        let sut = await clientAtConfirm()
        Mock.requestHandler = { _ in (response(200), Data("{}".utf8)) }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: dummyPassword).start()
        }
        #expect(reasonName(error?.reason) == "unknown")
        await expectNoSession(sut)
    }

    // MARK: Network failures

    @Test func aNetworkFailureOnTheAuthorizeCallKeepsTheSessionAndRetryResendsThePassword() async throws {
        let sut = await clientAtConfirm()
        Mock.requestHandler = { _ in throw URLError(.timedOut) }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: dummyPassword).start()
        }
        guard case .network? = error?.reason else {
            Issue.record("Expected .network, got \(String(describing: error?.reason))"); return
        }

        nonisolated(unsafe) var body: [String: Any] = [:]
        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody()) }
            body = bodyJSON(req)
            return (response(200), authCode())
        }
        _ = try await sut.confirmSignup(password: dummyPassword).start()
        #expect(body["auth_session"] as? String == "sess_4")
        #expect(body["password"] as? String == dummyPassword)
    }

    @Test func aNetworkFailureOnTheTokenCallKeepsTheSessionAndRetryResendsThePassword() async throws {
        let sut = await clientAtConfirm()
        Mock.requestHandler = { req in
            if isTokenRequest(req) { throw URLError(.notConnectedToInternet) }
            return (response(200), authCode())
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: dummyPassword).start()
        }
        guard case .network? = error?.reason else {
            Issue.record("Expected .network, got \(String(describing: error?.reason))"); return
        }

        nonisolated(unsafe) var body: [String: Any] = [:]
        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody(accessToken: "retry_token")) }
            body = bodyJSON(req)
            return (response(200), authCode("auth0_ac_second"))
        }
        let credentials = try await sut.confirmSignup(password: dummyPassword).start()
        #expect(credentials.accessToken == "retry_token")
        #expect(body["auth_session"] as? String == "sess_4")
        #expect(body["password"] as? String == dummyPassword)
    }

    // MARK: The password is never kept

    @Test func theClientAndTheErrorsNeverKeepThePassword() async {
        let secret = "Dummy-Secret-Never-Kept-789"
        let sut = await clientAtConfirm()

        // A network failure: the client must not remember the password for a retry.
        Mock.requestHandler = { _ in throw URLError(.timedOut) }
        let network = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: secret).start()
        }
        // A rejection: the response never echoes it.
        Mock.requestHandler = { _ in
            (response(403), continuation(session: "sess_5", description: "invalid_password", next: [confirmAction()]))
        }
        let rejected = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: secret).start()
        }

        for error in [network, rejected].compactMap({ $0 }) {
            #expect(!error.debugDescription.contains(secret))
            #expect(!"\(error.info)".contains(secret))
            #expect(!"\(error)".contains(secret))
        }
        let state = Mirror(reflecting: sut).children.map { "\($0.value)" }.joined(separator: "\n")
        #expect(!state.contains(secret))
        #expect(!String(reflecting: sut).contains(secret))
    }

    @Test func loggingRedactsThePasswordAndTheSession() async {
        let sut = await clientAtConfirm()
        let secret = "Dummy-Secret-Logged-Never-321"

        // Attach the logger only now, so everything it records belongs to the confirm call.
        let output = CapturingOutput()
        let logged = sut.using(logger: DefaultLogger(output: output))
        Mock.requestHandler = { _ in
            (response(403), continuation(session: "sess_rotated_value", description: "invalid_password", next: [confirmAction()]))
        }
        let failure = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await logged.confirmSignup(password: secret).start()
        }
        #expect(continuationInfo(failure)?.sub == "invalidPassword")

        // The logger writes asynchronously, in order: wait for the response to be logged too.
        for _ in 0..<100 where !output.text.contains("invalid_password") {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        #expect(output.text.contains("action:signup:confirm:v1"))
        #expect(output.text.contains("<REDACTED>"))
        #expect(!output.text.contains(secret))
        #expect(!output.text.contains("sess_4"))
        #expect(!output.text.contains("sess_rotated_value"))
    }

    // MARK: End-to-end flows

    @Test func requiredPasswordFlowReturnsCredentials() async throws {
        let sut = makeClient()
        let recorder = Recorder()
        let actions = await reachConfirm(sut, offer: .requiredPassword, recorder: recorder)
        let offer = try #require(passwordOffer(in: actions))
        #expect(offer.isRequired)
        #expect(offer.complexity == SignupPasswordComplexity(minLength: 8, characterTypes: [.lowercase, .number]))

        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody(accessToken: "signup_token")) }
            recorder.record(bodyJSON(req))
            return (response(200), authCode())
        }
        let credentials = try await sut.confirmSignup(password: dummyPassword).start()
        #expect(credentials.accessToken == "signup_token")
        // authorize has no action and no session yet.
        #expect(recorder.actions == [nil, "action:signup:v1", "action:identify:email:v1", "action:verify:otp:v1",
                                     "action:signup:confirm:v1"])
        #expect(recorder.sessions == [nil, "sess_1", "sess_2", "sess_3", "sess_4"])
        #expect(recorder.bodies.last?["password"] as? String == dummyPassword)
        // Only the last step carries the password.
        #expect(recorder.bodies.dropLast().allSatisfy { $0["password"] == nil })
        await expectNoSession(sut)
    }

    @Test func optionalPasswordFlowCanSkipThePassword() async throws {
        let sut = makeClient()
        let recorder = Recorder()
        let actions = await reachConfirm(sut, offer: .optionalPassword, recorder: recorder)
        #expect(passwordOffer(in: actions)?.isRequired == false)

        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody(accessToken: "skipped_token")) }
            recorder.record(bodyJSON(req))
            return (response(200), authCode())
        }
        let credentials = try await sut.confirmSignup().start()
        #expect(credentials.accessToken == "skipped_token")
        #expect(recorder.bodies.allSatisfy { $0["password"] == nil })
        #expect(Set(recorder.bodies.last?.keys.map { $0 } ?? []) == ["action", "client_id", "auth_session"])
        await expectNoSession(sut)
    }

    @Test func connectionsWithoutAPasswordKeepWorkingWithBothCallForms() async throws {
        for call in [0, 1] {
            let sut = makeClient()
            let actions = await reachConfirm(sut, offer: .noPassword, confirm: confirmAction(options: nil))
            #expect(actions == [.confirmSignup(password: nil)])

            nonisolated(unsafe) var keys: Set<String> = []
            Mock.requestHandler = { req in
                if isTokenRequest(req) { return (response(200), credentialsBody()) }
                keys = Set(bodyJSON(req).keys)
                return (response(200), authCode())
            }
            if call == 0 {
                _ = try await sut.confirmSignup().start()
            } else {
                _ = try await sut.confirmSignup(password: nil).start()
            }
            #expect(keys == ["action", "client_id", "auth_session"])
        }
    }

    // MARK: Default implementation for other conformances

    @Test func defaultImplementationForwardsNilToConfirmSignup() async throws {
        let sut = PartialEmbeddedAuth(inner: makeClient())
        await reachConfirm(sut.inner, offer: .noPassword, confirm: confirmAction(options: nil))

        nonisolated(unsafe) var body: [String: Any] = [:]
        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody(accessToken: "forwarded_token")) }
            body = bodyJSON(req)
            return (response(200), authCode())
        }
        let credentials = try await sut.confirmSignup(password: nil).start()
        #expect(credentials.accessToken == "forwarded_token")
        #expect(body["action"] as? String == "action:signup:confirm:v1")
        #expect(Set(body.keys) == ["action", "client_id", "auth_session"])
    }

    @Test func defaultImplementationFailsLocallyForAPasswordAndMakesNoRequest() async {
        let sut = PartialEmbeddedAuth(inner: makeClient())
        await reachConfirm(sut.inner, offer: .requiredPassword)

        nonisolated(unsafe) var requestCount = 0
        Mock.requestHandler = { _ in
            requestCount += 1
            return (response(200), authCode())
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: "x").start()
        }
        #expect(error?.code == "a0.sdk.internal_error.not_implemented")
        #expect(error?.statusCode == 0)
        #expect(error?.info["error_description"] as? String == "confirmSignup(password:) is not implemented by this EmbeddedAuth conformance.")
        #expect(requestCount == 0)

        // The session of the wrapped client is untouched, so the password-less step still works.
        Mock.requestHandler = { req in
            if isTokenRequest(req) { return (response(200), credentialsBody()) }
            requestCount += 1
            return (response(200), authCode())
        }
        let credentials = try? await sut.confirmSignup().start()
        #expect(credentials?.accessToken == "test_access_token")
        #expect(requestCount == 1)
    }

    @Test func defaultImplementationSupportsTheCallbackAPI() async {
        let sut = PartialEmbeddedAuth(inner: makeClient())
        nonisolated(unsafe) var requestCount = 0
        Mock.requestHandler = { _ in
            requestCount += 1
            return (response(200), authCode())
        }
        let code = await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            sut.confirmSignup(password: "x").start { result in
                if case .failure(let error) = result {
                    continuation.resume(returning: error.code)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
        #expect(code == "a0.sdk.internal_error.not_implemented")
        #expect(requestCount == 0)
    }
}
