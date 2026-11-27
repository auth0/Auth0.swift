#if PASSKEYS_PLATFORM
import Testing
import Foundation
import AuthenticationServices
@testable import Auth0

// Dedicated mock — never share static state with other test suites.
private final class EmbeddedAuthPasskeyMockProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        // A request nothing expected fails this one test instead of crashing the whole test process.
        guard let handler = EmbeddedAuthPasskeyMockProtocol.requestHandler else {
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

private let passkeyClientId = "TEST_CLIENT_ID"
private let passkeyDomain   = "test.auth0.com"

// MARK: - Test vectors (chosen to exercise "-", "_" and the absence of padding)

private let challengeB64 = "Y2hhbGxlbmdl"          // "challenge"
private let newChallengeB64 = "bmV3LWNoYWxsZW5nZQ"  // "new-challenge"
private let passkeyActionName = "action:verify:passkey:v1"

// MARK: - Helpers

private func makePasskeyClient() -> EmbeddedAuth {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [EmbeddedAuthPasskeyMockProtocol.self]
    return Auth0.embeddedAuth(clientId: passkeyClientId, domain: passkeyDomain, session: URLSession(configuration: config))
}

private func passkeyOffer(challenge: String = challengeB64, extra: [String: Any] = [:]) -> [String: Any] {
    var options: [String: Any] = [
        "challenge": challenge,
        "timeout": 900000,
        "userVerification": "preferred",
        "rpId": "login.example.com"
    ]
    options.merge(extra) { _, new in new }
    return ["action": passkeyActionName, "authn_params_public_key": options]
}

/// Valid offer options with `changes` applied and `key` left out, so that a malformed-offer row breaks one thing only.
private func offerOptions(_ changes: [String: Any] = [:], removing key: String? = nil) -> [String: Any] {
    var options: [String: Any] = [
        "challenge": challengeB64,
        "timeout": 900000,
        "userVerification": "preferred",
        "rpId": "a.com"
    ]
    options.merge(changes) { _, new in new }
    if let key { options.removeValue(forKey: key) }
    return options
}

private func insufficientAuthPasskey(session: String,
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

private func authCodePasskey(code: String = "auth0_ac_test123") -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: ["authorization_code": code])
}

private func credentialsPasskey(accessToken: String = "test_access_token") -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: [
        "access_token": accessToken,
        "token_type": "Bearer",
        "id_token": "test_id_token",
        "expires_in": 86400
    ])
}

private func errorBodyPasskey(_ json: [String: Any]) -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: json)
}

private func responsePasskey(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://\(passkeyDomain)/")!,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: nil)!
}

/// The JSON object of a request body.
private func passkeyJSON(_ request: URLRequest) -> [String: Any]? {
    request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
}

/// The JSON object a `requestJson` string holds.
private func requestJsonObject(_ requestJson: String) -> [String: Any]? {
    try? JSONSerialization.jsonObject(with: Data(requestJson.utf8)) as? [String: Any]
}

/// Records every request that reaches the network layer, so a test can assert that nothing was sent.
private final class RequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [URLRequest] = []

    var requests: [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    var authorizeBodies: [[String: Any]] {
        requests.filter { $0.url?.path == "/e/authorize" }.compactMap(passkeyJSON)
    }

    func record(_ request: URLRequest) {
        lock.lock()
        recorded.append(request)
        lock.unlock()
    }
}

/// Handler for a flow that completes: `/e/authorize` returns a code and `/oauth/token` returns credentials.
private func installSuccessHandler(_ recorder: RequestRecorder, code: String = "auth0_ac_test123") {
    EmbeddedAuthPasskeyMockProtocol.requestHandler = { req in
        recorder.record(req)
        if req.url?.path.hasSuffix("/oauth/token") == true {
            return (responsePasskey(status: 200), credentialsPasskey())
        }
        return (responsePasskey(status: 200), authCodePasskey(code: code))
    }
}

/// Establishes an auth session by running authorize() through the mock, which offers a passkey and an email identify step.
private func establishPasskeySession(_ client: EmbeddedAuth,
                                     session: String = "sess_001",
                                     nextActions: [[String: Any]]? = nil) async {
    EmbeddedAuthPasskeyMockProtocol.requestHandler = { _ in
        (responsePasskey(status: 403),
         insufficientAuthPasskey(session: session,
                                 nextActions: nextActions ?? [passkeyOffer(), ["action": "action:identify:email:v1"]]))
    }
    _ = try? await client.authorize(connection: "test-connection").start()
}

/// The name of a reason's case, since `EmbeddedAuthErrorReason` is not `Equatable`.
private func passkeyReasonName(_ reason: EmbeddedAuthErrorReason) -> String {
    String(describing: reason).prefix { $0 != "(" }.description
}

private func passkeyReason(_ info: [String: Any], statusCode: Int = 403) -> EmbeddedAuthErrorReason {
    EmbeddedAuthError(info: info, statusCode: statusCode).reason
}

/// The `nextActions` of an `insufficient_authorization` reason, or `nil` for any other reason.
private func passkeyNextActions(_ reason: EmbeddedAuthErrorReason) -> [NextAction]? {
    guard case .insufficientAuthorization(_, let actions) = reason else { return nil }
    return actions
}

private func offerInfo(_ entries: [[String: Any]], description: String? = nil) -> [String: Any] {
    var info: [String: Any] = ["error": "insufficient_authorization", "auth_session": "sess_x", "next": entries]
    if let description { info["error_description"] = description }
    return info
}

@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
private struct MockLoginPasskey: LoginPasskey {
    var userID: Data! = Data([0x01, 0x02])                                   // "AQI"
    var credentialID: Data = Data([0xfb, 0xff, 0xbf])                        // "-_-_"
    var attachment: ASAuthorizationPublicKeyCredentialAttachment = .platform
    var rawClientDataJSON: Data = Data("{\"type\":\"webauthn.get\"}".utf8)   // "eyJ0eXBlIjoid2ViYXV0aG4uZ2V0In0"
    var rawAuthenticatorData: Data! = Data([0x00, 0x01, 0x02, 0x03])         // "AAECAw"
    var signature: Data! = Data([0xff, 0xee])                                // "_-4"
}

private let clientDataB64 = "eyJ0eXBlIjoid2ViYXV0aG4uZ2V0In0"

// MARK: - Suite

@Suite(.serialized)
struct EmbeddedAuthPasskeyClientTests {

    init() {
        EmbeddedAuthPasskeyMockProtocol.requestHandler = nil
    }

    // MARK: Capability

    @Test func verifyPasskeyCapabilityMapsToWireString() {
        #expect(EmbeddedCapability.verifyPasskey.action.rawValue == "action:verify:passkey:v1")
    }

    @Test func capabilitiesAllIncludesVerifyPasskeyOnlyWherePasskeysAreAvailable() {
        var expected = false
        if #available(iOS 16.6, macOS 13.5, visionOS 1.0, *) { expected = true }
        #expect(EmbeddedCapability.all.contains(.verifyPasskey) == expected)
        if expected {
            #expect(EmbeddedCapability.all.last == .verifyPasskey)
        }
    }

    // MARK: Parsing the offer

    @Test func parsesFullOfferAndKeepsMenuOrder() {
        let reason = passkeyReason(offerInfo([passkeyOffer(), ["action": "action:identify:email:v1"]]))
        let expected = PasskeyRequestOptions(relyingPartyId: "login.example.com",
                                             challengeData: Data("challenge".utf8),
                                             timeout: 900000,
                                             userVerification: .preferred,
                                             allowedCredentialIds: [],
                                             hints: [])
        let requestJson = #"{"challenge":"\#(challengeB64)","rpId":"login.example.com","timeout":900000,"userVerification":"preferred"}"#
        #expect(passkeyNextActions(reason) == [.verifyPasskey(options: expected, requestJson: requestJson), .identifyEmail])
    }

    @Test func parsesOfferWithOnlyTheRequiredMembers() {
        let entry: [String: Any] = ["action": passkeyActionName,
                                    "authn_params_public_key": ["challenge": challengeB64,
                                                                "rpId": "login.example.com",
                                                                "timeout": 60000,
                                                                "userVerification": "required"]]
        let actions = passkeyNextActions(passkeyReason(offerInfo([entry])))
        let options = PasskeyRequestOptions(relyingPartyId: "login.example.com",
                                            challengeData: Data("challenge".utf8),
                                            timeout: 60000,
                                            userVerification: .required,
                                            allowedCredentialIds: [],
                                            hints: [])
        let requestJson = #"{"challenge":"\#(challengeB64)","rpId":"login.example.com","timeout":60000,"userVerification":"required"}"#
        #expect(actions == [.verifyPasskey(options: options, requestJson: requestJson)])
    }

    @Test(arguments: [("required", PasskeyUserVerification.required),
                      ("preferred", .preferred),
                      ("discouraged", .discouraged)])
    func parsesEachUserVerificationValue(raw: String, expected: PasskeyUserVerification) {
        let actions = passkeyNextActions(passkeyReason(offerInfo([passkeyOffer(extra: ["userVerification": raw])])))
        guard case .verifyPasskey(let options, _)? = actions?.first else {
            Issue.record("Expected a passkey offer"); return
        }
        #expect(options.userVerification == expected)
    }

    @Test func parsesAllowCredentialsAndHints() {
        let extra: [String: Any] = ["allowCredentials": [["type": "public-key", "id": "AQID"]],
                                    "hints": ["client-device", 7]]
        let actions = passkeyNextActions(passkeyReason(offerInfo([passkeyOffer(extra: extra)])))
        guard case .verifyPasskey(let options, _)? = actions?.first else {
            Issue.record("Expected a passkey offer"); return
        }
        #expect(options.allowedCredentialIds == [Data([1, 2, 3])])
        #expect(options.hints == ["client-device"])
    }

    @Test func emptyAllowCredentialsMeansAnyPasskey() {
        let actions = passkeyNextActions(passkeyReason(offerInfo([passkeyOffer(extra: ["allowCredentials": [[String: Any]]()])])))
        guard case .verifyPasskey(let options, _)? = actions?.first else {
            Issue.record("Expected a passkey offer"); return
        }
        #expect(options.allowedCredentialIds.isEmpty)
    }

    @Test func ignoresUnknownKeys() {
        let extra: [String: Any] = ["extensions": ["x": 1], "attestation": "none"]
        let actions = passkeyNextActions(passkeyReason(offerInfo([passkeyOffer(extra: extra)])))
        guard case .verifyPasskey(let options, _)? = actions?.first else {
            Issue.record("Expected a passkey offer"); return
        }
        #expect(options.timeout == 900000)
        #expect(options.userVerification == .preferred)
    }

    // MARK: requestJson

    @Test func requestJsonIsTheOptionsObjectTheServerSent() throws {
        // It includes members this SDK version doesn't model, so an app with its own WebAuthn code gets everything.
        let extra: [String: Any] = ["allowCredentials": [["type": "public-key", "id": "AQID", "transports": ["internal"]]],
                                    "hints": ["client-device"],
                                    "extensions": ["credProps": true, "values": [1, "two", NSNull()]],
                                    "attestation": "none"]
        let offer = passkeyOffer(extra: extra)
        let actions = passkeyNextActions(passkeyReason(offerInfo([offer])))
        guard case .verifyPasskey(_, let requestJson)? = actions?.first else {
            Issue.record("Expected a passkey offer"); return
        }
        let sent = try #require(offer["authn_params_public_key"] as? [String: Any])
        let parsed = try #require(requestJsonObject(requestJson))
        #expect(NSDictionary(dictionary: parsed).isEqual(to: sent))
    }

    @Test func requestJsonKeepsTheChallengeAsSent() throws {
        let actions = passkeyNextActions(passkeyReason(offerInfo([passkeyOffer(challenge: newChallengeB64)])))
        guard case .verifyPasskey(let options, let requestJson)? = actions?.first else {
            Issue.record("Expected a passkey offer"); return
        }
        // The options hold the decoded challenge, and `requestJson` the base64url text the server sent.
        #expect(options.challengeData == Data("new-challenge".utf8))
        let parsed = try #require(requestJsonObject(requestJson))
        #expect(parsed["challenge"] as? String == newChallengeB64)
    }

    @Test func requestJsonDoesNotDependOnTheOrderOfTheKeys() throws {
        func requestJson(of body: String) throws -> String? {
            let options = try #require(JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])
            let entry: [String: Any] = ["action": passkeyActionName, "authn_params_public_key": options]
            guard case .verifyPasskey(_, let requestJson)? = passkeyNextActions(passkeyReason(offerInfo([entry])))?.first else {
                return nil
            }
            return requestJson
        }
        let first = try requestJson(of: #"{"challenge":"\#(challengeB64)","rpId":"a.com","timeout":1,"userVerification":"preferred"}"#)
        let second = try requestJson(of: #"{"userVerification":"preferred","timeout":1,"rpId":"a.com","challenge":"\#(challengeB64)"}"#)
        #expect(first != nil)
        #expect(first == second)
    }

    @Test(arguments: [
        ("challenge is missing", offerOptions(removing: "challenge")),
        ("challenge is empty", offerOptions(["challenge": ""])),
        ("challenge is not base64url", offerOptions(["challenge": "***"])),
        ("challenge is not a string", offerOptions(["challenge": 5])),
        ("rpId is missing", offerOptions(removing: "rpId")),
        ("rpId is empty", offerOptions(["rpId": ""])),
        ("timeout is missing", offerOptions(removing: "timeout")),
        ("timeout is not an integer", offerOptions(["timeout": "soon"])),
        ("timeout has a fraction", offerOptions(["timeout": 1.5])),
        ("timeout is a boolean", offerOptions(["timeout": true])),
        ("userVerification is missing", offerOptions(removing: "userVerification")),
        ("userVerification is not a string", offerOptions(["userVerification": 1])),
        ("userVerification is not a known value", offerOptions(["userVerification": "sometimes"])),
        ("allowCredentials is not an array", offerOptions(["allowCredentials": "AQID"])),
        ("allowCredentials is null", offerOptions(["allowCredentials": NSNull()])),
        ("an allowCredentials item has no id", offerOptions(["allowCredentials": [["type": "public-key"]]])),
        ("an allowCredentials id is not base64url", offerOptions(["allowCredentials": [["id": "***"]]])),
        ("one allowCredentials item is bad", offerOptions(["allowCredentials": [["id": "AQID"], ["id": ""]]]))
    ])
    func dropsMalformedOffers(_ scenario: String, _ options: [String: Any]) {
        let entry: [String: Any] = ["action": passkeyActionName, "authn_params_public_key": options]
        #expect(passkeyNextActions(passkeyReason(offerInfo([entry]))) == [], Comment(rawValue: scenario))
    }

    @Test func malformedOfferRowsStartFromAValidOffer() {
        let entry: [String: Any] = ["action": passkeyActionName, "authn_params_public_key": offerOptions()]
        #expect(passkeyNextActions(passkeyReason(offerInfo([entry])))?.count == 1)
    }

    @Test func timeoutIsAWholeNumberAndNotABoolean() throws {
        // JSONSerialization reads `true` as an NSNumber that converts to the integer 1, so `as? Int` alone accepts it.
        func options(timeout: String) throws -> [String: Any] {
            let body = #"{"challenge":"\#(challengeB64)","rpId":"a.com","timeout":\#(timeout),"userVerification":"preferred"}"#
            return try #require(JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])
        }
        #expect(PasskeyRequestOptions(json: try options(timeout: "900000"))?.timeout == 900000)
        // The timeout is informational only, so any whole number is accepted.
        #expect(PasskeyRequestOptions(json: try options(timeout: "0"))?.timeout == 0)
        #expect(PasskeyRequestOptions(json: try options(timeout: "-1"))?.timeout == -1)
        #expect(PasskeyRequestOptions(json: try options(timeout: "true")) == nil)
        #expect(PasskeyRequestOptions(json: try options(timeout: "1.5")) == nil)
    }

    @Test func keepsTheOfferWhenHintsAreNotAnArray() {
        let actions = passkeyNextActions(passkeyReason(offerInfo([passkeyOffer(extra: ["hints": "client-device"])])))
        guard case .verifyPasskey(let options, _)? = actions?.first else {
            Issue.record("Expected a passkey offer"); return
        }
        #expect(options.hints.isEmpty)
    }

    @Test func aDroppedMalformedOfferStillAdoptsTheSession() async {
        let sut = makePasskeyClient()
        let malformed: [String: Any] = ["action": passkeyActionName, "authn_params_public_key": ["rpId": "a.com"]]
        EmbeddedAuthPasskeyMockProtocol.requestHandler = { _ in
            (responsePasskey(status: 403), insufficientAuthPasskey(session: "sess_001", nextActions: [malformed]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.authorize(connection: "c").start()
        }
        // There is nothing to present, but the flow is alive: the next step goes out with the session.
        #expect(passkeyNextActions(error?.reason ?? .unknown) == [])
        let recorder = RequestRecorder()
        EmbeddedAuthPasskeyMockProtocol.requestHandler = { req in
            recorder.record(req)
            return (responsePasskey(status: 403),
                    insufficientAuthPasskey(session: "sess_002", nextActions: [["action": "action:verify:password:v1"]]))
        }
        _ = try? await sut.identify("user@example.com", type: .email).start()
        #expect(recorder.authorizeBodies.first?["auth_session"] as? String == "sess_001")
    }

    @Test func dropsOfferWithoutOptionsObject() {
        let entry: [String: Any] = ["action": passkeyActionName]
        #expect(passkeyNextActions(passkeyReason(offerInfo([entry, ["action": "action:identify:email:v1"]]))) == [.identifyEmail])
    }

    @Test func invalidPasskeyDescriptionCarriesTheNewOptions() {
        let info = offerInfo([passkeyOffer(challenge: newChallengeB64)], description: "invalid_passkey")
        guard case .insufficientAuthorization(.invalidPasskey, let actions) = passkeyReason(info) else {
            Issue.record("Expected .invalidPasskey"); return
        }
        guard case .verifyPasskey(let options, _)? = actions.first else {
            Issue.record("Expected a passkey offer"); return
        }
        #expect(options.challengeData == Data("new-challenge".utf8))
    }

    // MARK: Local error classification

    @Test func invalidInputIsOnlyRecognisedForLocalErrors() {
        let info: [String: Any] = ["error": "invalid_input", "error_description": "msg"]
        guard case .invalidInput(let message) = passkeyReason(info, statusCode: 0) else {
            Issue.record("Expected .invalidInput"); return
        }
        #expect(message == "msg")
        #expect(passkeyReasonName(passkeyReason(info, statusCode: 400)) == "unknown")
    }

    // MARK: PasskeyRequestOptions

    @Test func requestOptionsExposeTheValuesAsGiven() {
        let options = PasskeyRequestOptions(relyingPartyId: "login.example.com",
                                            challengeData: Data("challenge".utf8),
                                            timeout: 1000,
                                            userVerification: .required,
                                            allowedCredentialIds: [Data([1, 2, 3]), Data([4])],
                                            hints: ["client-device"])
        #expect(options.relyingPartyId == "login.example.com")
        #expect(options.challengeData == Data("challenge".utf8))
        #expect(options.timeout == 1000)
        #expect(options.userVerification == .required)
        #expect(options.allowedCredentialIds == [Data([1, 2, 3]), Data([4])])
        #expect(options.hints == ["client-device"])
    }

    // MARK: Authorize

    @Test func authorizeWithExplicitCapabilitiesOmitsVerifyPasskey() async {
        let sut = makePasskeyClient()
        let recorder = RequestRecorder()
        EmbeddedAuthPasskeyMockProtocol.requestHandler = { req in
            recorder.record(req)
            return (responsePasskey(status: 403),
                    insufficientAuthPasskey(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        let capabilities = EmbeddedCapability.all.filter { $0 != .verifyPasskey }
        _ = try? await sut.authorize(connection: "c", capabilities: capabilities,
                                     scope: "openid", audience: nil).start()
        let sent = recorder.authorizeBodies.first?["capabilities"] as? [String]
        #expect(sent?.contains(passkeyActionName) == false)
    }
}

// MARK: - Passkey platform tests

extension EmbeddedAuthPasskeyClientTests {

    // MARK: authorize

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func authorizeAdvertisesVerifyPasskeyByDefault() async {
        let sut = makePasskeyClient()
        let recorder = RequestRecorder()
        EmbeddedAuthPasskeyMockProtocol.requestHandler = { req in
            recorder.record(req)
            return (responsePasskey(status: 403),
                    insufficientAuthPasskey(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()
        let sent = recorder.authorizeBodies.first?["capabilities"] as? [String]
        #expect(sent?.contains(passkeyActionName) == true)
    }

    // MARK: verifyPasskey — local failures

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyFailsLocallyWithNoSessionAndSendsNothing() async {
        let sut = makePasskeyClient()
        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        }
        #expect(error?.code == "no_active_session")
        #expect(error?.statusCode == 0)
        #expect(recorder.requests.isEmpty)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyChecksTheSessionBeforeTheInput() async {
        let sut = makePasskeyClient()
        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        var passkey = MockLoginPasskey()
        passkey.userID = nil // Would be .invalidInput if there were a session.
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(passkey).start()
        }
        #expect(error?.code == "no_active_session")
        #expect(recorder.requests.isEmpty)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test(arguments: [
        ("user handle is nil", "This passkey has no user handle. Only discoverable passkeys are supported."),
        ("user handle is empty", "This passkey has no user handle. Only discoverable passkeys are supported."),
        ("credential ID is empty", "This passkey has no credential ID."),
        ("client data is empty", "This passkey has no client data."),
        ("authenticator data is nil", "This passkey has no authenticator data."),
        ("authenticator data is empty", "This passkey has no authenticator data."),
        ("signature is nil", "This passkey has no signature."),
        ("signature is empty", "This passkey has no signature.")
    ])
    func verifyPasskeyInvalidInputSendsNothingAndKeepsSession(scenario: String, message: String) async {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut)

        var passkey = MockLoginPasskey()
        switch scenario {
        case "user handle is nil": passkey.userID = nil
        case "user handle is empty": passkey.userID = Data()
        case "credential ID is empty": passkey.credentialID = Data()
        case "client data is empty": passkey.rawClientDataJSON = Data()
        case "authenticator data is nil": passkey.rawAuthenticatorData = nil
        case "authenticator data is empty": passkey.rawAuthenticatorData = Data()
        case "signature is nil": passkey.signature = nil
        default: passkey.signature = Data()
        }

        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(passkey).start()
        }
        guard case .invalidInput(let reported)? = error?.reason else {
            Issue.record("Expected .invalidInput, got \(String(describing: error?.reason))"); return
        }
        #expect(reported == message)
        #expect(error?.statusCode == 0)
        #expect(recorder.requests.isEmpty)

        // The session is still there: a valid passkey goes through with the original session.
        _ = try? await sut.verifyPasskey(MockLoginPasskey()).start()
        #expect(recorder.authorizeBodies.first?["auth_session"] as? String == "sess_001")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func invalidInputMessageNeverContainsPasskeyData() async {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut)
        var passkey = MockLoginPasskey()
        passkey.userID = nil
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(passkey).start()
        }
        let text = error?.debugDescription ?? ""
        for fragment in ["-_-_", "AAECAw", "_-4", clientDataB64] {
            #expect(!text.contains(fragment))
        }
    }

    // MARK: verifyPasskey — request

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeySendsExactlyTheAllowedFields() async throws {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut, session: "sess_001")

        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        _ = try await sut.verifyPasskey(MockLoginPasskey()).start()

        let authorize = try #require(recorder.requests.first { $0.url?.path == "/e/authorize" })
        #expect(authorize.httpMethod == "POST")
        #expect(authorize.value(forHTTPHeaderField: "Auth0-Client") != nil)
        let body = try #require(passkeyJSON(authorize))
        #expect(Set(body.keys) == ["client_id", "action", "auth_session", "authn_response"])
        #expect(body["client_id"] as? String == passkeyClientId)
        #expect(body["action"] as? String == passkeyActionName)
        #expect(body["auth_session"] as? String == "sess_001")

        let assertion = try #require(body["authn_response"] as? [String: Any])
        #expect(Set(assertion.keys) == ["id", "rawId", "type", "authenticatorAttachment", "clientExtensionResults", "response"])
        #expect(assertion["id"] as? String == "-_-_")
        #expect(assertion["rawId"] as? String == "-_-_")
        #expect(assertion["type"] as? String == "public-key")
        #expect(assertion["authenticatorAttachment"] as? String == "platform")
        // No extension was requested, so the results are the empty object a browser would send.
        let extensionResults = try #require(assertion["clientExtensionResults"] as? [String: Any])
        #expect(extensionResults.isEmpty)

        let response = try #require(assertion["response"] as? [String: Any])
        #expect(Set(response.keys) == ["clientDataJSON", "authenticatorData", "signature", "userHandle"])
        #expect(response["clientDataJSON"] as? String == clientDataB64)
        #expect(response["authenticatorData"] as? String == "AAECAw")
        #expect(response["signature"] as? String == "_-4")
        #expect(response["userHandle"] as? String == "AQI")

        let values = [assertion["id"], assertion["rawId"]] + response.values.map { Optional($0) }
        for value in values.compactMap({ $0 as? String }) {
            #expect(!value.contains("="))
            #expect(!value.contains("+"))
            #expect(!value.contains("/"))
        }
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeySendsCrossPlatformAttachment() async throws {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut)
        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        var passkey = MockLoginPasskey()
        passkey.attachment = .crossPlatform
        _ = try await sut.verifyPasskey(passkey).start()
        let assertion = recorder.authorizeBodies.first?["authn_response"] as? [String: Any]
        #expect(assertion?["authenticatorAttachment"] as? String == "cross-platform")
    }

    // MARK: verifyPasskey — success

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyReturnsCredentialsAfterCodeExchange() async throws {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut)
        let recorder = RequestRecorder()
        installSuccessHandler(recorder, code: "auth0_ac_theCode")

        let credentials = try await sut.verifyPasskey(MockLoginPasskey()).start()
        #expect(credentials.accessToken == "test_access_token")

        let token = try #require(recorder.requests.first { $0.url?.path == "/oauth/token" })
        let body = try #require(passkeyJSON(token))
        #expect(body["grant_type"] as? String == "authorization_code")
        #expect(body["code"] as? String == "auth0_ac_theCode")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyExchangesTheCodeWithTheVerifierOfTheFlow() async throws {
        let sut = makePasskeyClient()
        let recorder = RequestRecorder()
        EmbeddedAuthPasskeyMockProtocol.requestHandler = { req in
            recorder.record(req)
            return (responsePasskey(status: 403), insufficientAuthPasskey(session: "sess_001", nextActions: [passkeyOffer()]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()
        let challenge = try #require(recorder.authorizeBodies.first?["code_challenge"] as? String)

        installSuccessHandler(recorder)
        _ = try await sut.verifyPasskey(MockLoginPasskey()).start()

        // The step that returns the code is a continuation, so it carries no PKCE field.
        let completing = try #require(recorder.authorizeBodies.last)
        #expect(completing["code_challenge"] == nil)
        #expect(completing["code_challenge_method"] == nil)
        #expect(completing["code_verifier"] == nil)

        let token = try #require(recorder.requests.first { $0.url?.path == "/oauth/token" })
        let body = try #require(passkeyJSON(token))
        let verifier = try #require(body["code_verifier"] as? String)
        #expect(ChallengeGenerator(verifier: verifier).challenge == challenge)
        #expect(Set(body.keys) == ["client_id", "grant_type", "code", "code_verifier"])
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyKeepsTheVerifierOfTheFlowItWasBuiltIn() async throws {
        let sut = makePasskeyClient()
        let recorder = RequestRecorder()
        EmbeddedAuthPasskeyMockProtocol.requestHandler = { req in
            recorder.record(req)
            return (responsePasskey(status: 403), insufficientAuthPasskey(session: "sess_001", nextActions: [passkeyOffer()]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()
        let firstChallenge = try #require(recorder.authorizeBodies.first?["code_challenge"] as? String)
        let request = sut.verifyPasskey(MockLoginPasskey()) // built while the first flow is running

        _ = try? await sut.authorize(connection: "test-connection").start() // a second flow, with its own challenge
        let secondChallenge = try #require(recorder.authorizeBodies.last?["code_challenge"] as? String)
        #expect(firstChallenge != secondChallenge)

        installSuccessHandler(recorder)
        _ = try await request.start()

        let token = try #require(recorder.requests.first { $0.url?.path == "/oauth/token" })
        let verifier = try #require(passkeyJSON(token)?["code_verifier"] as? String)
        #expect(ChallengeGenerator(verifier: verifier).challenge == firstChallenge)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyClearsSessionOnSuccess() async throws {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut)
        installSuccessHandler(RequestRecorder())

        _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        }
        #expect(error?.code == "no_active_session")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeySupportsCallbackAPI() async {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut)
        installSuccessHandler(RequestRecorder())

        let credentials = await withCheckedContinuation { continuation in
            sut.verifyPasskey(MockLoginPasskey()).start { result in
                continuation.resume(returning: try? result.get())
            }
        }
        #expect(credentials?.accessToken == "test_access_token")
    }

    // MARK: verifyPasskey — continuations

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyInvalidPasskeyRotatesSessionAndOffersNewOptions() async throws {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut, session: "sess_001")

        EmbeddedAuthPasskeyMockProtocol.requestHandler = { _ in
            (responsePasskey(status: 403),
             insufficientAuthPasskey(session: "sess_002",
                                     description: "invalid_passkey",
                                     nextActions: [passkeyOffer(challenge: newChallengeB64),
                                                   ["action": "action:identify:email:v1"]]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        }
        guard case .insufficientAuthorization(.invalidPasskey, let actions)? = error?.reason else {
            Issue.record("Expected .invalidPasskey, got \(String(describing: error?.reason))"); return
        }
        guard case .verifyPasskey(let options, _)? = actions.first else {
            Issue.record("Expected the new passkey offer"); return
        }
        #expect(options.challengeData == Data("new-challenge".utf8))

        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        #expect(recorder.authorizeBodies.first?["auth_session"] as? String == "sess_002")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyInvalidPasskeyWithoutANewOfferStillRotatesTheSession() async {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut, session: "sess_001")

        EmbeddedAuthPasskeyMockProtocol.requestHandler = { _ in
            (responsePasskey(status: 403),
             insufficientAuthPasskey(session: "sess_002",
                                     description: "invalid_passkey",
                                     nextActions: [["action": "action:identify:email:v1"]]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        }
        guard case .insufficientAuthorization(.invalidPasskey, let actions)? = error?.reason else {
            Issue.record("Expected .invalidPasskey, got \(String(describing: error?.reason))"); return
        }
        #expect(actions == [.identifyEmail]) // The server may not offer the passkey again.

        let recorder = RequestRecorder()
        EmbeddedAuthPasskeyMockProtocol.requestHandler = { req in
            recorder.record(req)
            return (responsePasskey(status: 403),
                    insufficientAuthPasskey(session: "sess_003", nextActions: [["action": "action:verify:password:v1"]]))
        }
        _ = try? await sut.identify("user@example.com", type: .email).start()
        #expect(recorder.authorizeBodies.first?["auth_session"] as? String == "sess_002")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyMfaRequiredRotatesSessionAndExposesNextActions() async throws {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut, session: "sess_001")

        EmbeddedAuthPasskeyMockProtocol.requestHandler = { _ in
            (responsePasskey(status: 403),
             insufficientAuthPasskey(session: "sess_002",
                                     nextActions: [["action": "action:challenge:email:v1",
                                                    "index": 0,
                                                    "identifier": "al**@example.com"],
                                                   ["action": "action:verify:otp:v1", "channel": "email"]]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        }
        guard case .insufficientAuthorization(.none, let actions)? = error?.reason else {
            Issue.record("Expected a plain continuation, got \(String(describing: error?.reason))"); return
        }
        #expect(actions == [.challengeEmail(index: 0, identifier: "al**@example.com"),
                            .verifyOTP(channel: .email, identifier: nil)])

        let recorder = RequestRecorder()
        EmbeddedAuthPasskeyMockProtocol.requestHandler = { req in
            recorder.record(req)
            return (responsePasskey(status: 403),
                    insufficientAuthPasskey(session: "sess_003", nextActions: [["action": "action:verify:otp:v1", "channel": "email"]]))
        }
        _ = try? await sut.challengeEmail(index: 0).start()
        #expect(recorder.authorizeBodies.first?["auth_session"] as? String == "sess_002")
    }

    // MARK: verifyPasskey — failures

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test(arguments: [
        (403, "access_denied", "accessDenied"),
        (400, "invalid_request", "invalidRequest"),
        (429, "too_many_requests", "tooManyAttempts"),
        (401, "invalid_client", "unknown"),
        (500, "server_error", "unknown")
    ])
    func verifyPasskeyTerminalFailuresClearSession(status: Int, code: String, expectedReason: String) async {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut)

        EmbeddedAuthPasskeyMockProtocol.requestHandler = { _ in
            var json: [String: Any] = ["error": code]
            if status == 429 { json["error_description"] = "too_many_attempts" }
            return (responsePasskey(status: status), errorBodyPasskey(json))
        }
        let first = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        }
        #expect(first.map { passkeyReasonName($0.reason) } == expectedReason)

        let next = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        }
        #expect(next?.code == "no_active_session")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyNetworkFailureKeepsSession() async {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut, session: "sess_001")

        EmbeddedAuthPasskeyMockProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        }
        guard case .network? = error?.reason else {
            Issue.record("Expected .network, got \(String(describing: error?.reason))"); return
        }

        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        _ = try? await sut.verifyPasskey(MockLoginPasskey()).start()
        #expect(recorder.authorizeBodies.first?["auth_session"] as? String == "sess_001")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyNetworkFailureOnTheTokenExchangeKeepsSession() async {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut, session: "sess_001")

        EmbeddedAuthPasskeyMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true { throw URLError(.networkConnectionLost) }
            return (responsePasskey(status: 200), authCodePasskey())
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        }
        guard case .network? = error?.reason else {
            Issue.record("Expected .network, got \(String(describing: error?.reason))"); return
        }

        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        _ = try? await sut.verifyPasskey(MockLoginPasskey()).start()
        #expect(recorder.authorizeBodies.first?["auth_session"] as? String == "sess_001")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyExchangeFailureClearsSession() async {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut)

        EmbeddedAuthPasskeyMockProtocol.requestHandler = { req in
            if req.url?.path.hasSuffix("/oauth/token") == true {
                return (responsePasskey(status: 403), errorBodyPasskey(["error": "unauthorized_client"]))
            }
            return (responsePasskey(status: 200), authCodePasskey())
        }
        let first = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        }
        #expect(first?.code == "unauthorized_client")

        let next = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        }
        #expect(next?.code == "no_active_session")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyMalformedSuccessClearsSession() async {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut)

        EmbeddedAuthPasskeyMockProtocol.requestHandler = { _ in (responsePasskey(status: 200), errorBodyPasskey([:])) }
        _ = try? await sut.verifyPasskey(MockLoginPasskey()).start()

        let next = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyPasskey(MockLoginPasskey()).start()
        }
        #expect(next?.code == "no_active_session")
    }

    // MARK: Logging

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func verifyPasskeyNeverLogsTheAssertion() async {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut)

        // Attach the logger only now, so everything it records belongs to the verifyPasskey call.
        let output = CapturingOutput()
        let logged = sut.using(logger: DefaultLogger(output: output))
        installSuccessHandler(RequestRecorder())
        _ = try? await logged.verifyPasskey(MockLoginPasskey()).start()

        // The logger writes asynchronously, in order. Once the token request is logged, the /e/authorize
        // request body before it has been logged too.
        for _ in 0..<100 where !output.text.contains("/oauth/token") {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        #expect(output.text.contains("/oauth/token"))
        #expect(output.text.contains(passkeyActionName))
        #expect(output.text.contains("<REDACTED>"))
        for fragment in ["-_-_", "AQI", "AAECAw", "_-4", clientDataB64] {
            #expect(!output.text.contains(fragment))
        }
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func authorizeResponseLogNeverContainsTheChallenge() async {
        let sut = makePasskeyClient()
        let output = CapturingOutput()
        let logged = sut.using(logger: DefaultLogger(output: output))
        EmbeddedAuthPasskeyMockProtocol.requestHandler = { _ in
            (responsePasskey(status: 403),
             insufficientAuthPasskey(session: "sess_001", nextActions: [passkeyOffer(), ["action": "action:identify:email:v1"]]))
        }
        _ = try? await logged.authorize(connection: "test-connection").start()

        for _ in 0..<100 where !output.text.contains("authn_params_public_key") {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        #expect(output.text.contains("authn_params_public_key"))
        #expect(output.text.contains("login.example.com"))
        #expect(!output.text.contains(challengeB64))
    }

    // MARK: Full flows

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func offerPickedByTypeThenVerifyReturnsCredentials() async throws {
        let sut = makePasskeyClient()
        EmbeddedAuthPasskeyMockProtocol.requestHandler = { _ in
            (responsePasskey(status: 403),
             insufficientAuthPasskey(session: "sess_001",
                                     nextActions: [passkeyOffer(), ["action": "action:identify:email:v1"]]))
        }
        let offered = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.authorize(connection: "test-connection").start()
        }
        var picked: PasskeyRequestOptions?
        if case .insufficientAuthorization(_, let actions)? = offered?.reason {
            for case .verifyPasskey(let options, _) in actions { picked = options }
        }
        let options = try #require(picked)
        #expect(options.relyingPartyId == "login.example.com")

        installSuccessHandler(RequestRecorder())
        let credentials = try await sut.verifyPasskey(MockLoginPasskey()).start()
        #expect(credentials.accessToken == "test_access_token")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func cancellingThePasskeyFallsBackToIdentifyWithTheSameSession() async {
        let sut = makePasskeyClient()
        await establishPasskeySession(sut, session: "sess_001")

        let recorder = RequestRecorder()
        EmbeddedAuthPasskeyMockProtocol.requestHandler = { req in
            recorder.record(req)
            return (responsePasskey(status: 403),
                    insufficientAuthPasskey(session: "sess_002", nextActions: [["action": "action:verify:password:v1"]]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.identify("user@example.com", type: .email).start()
        }
        #expect(recorder.authorizeBodies.first?["auth_session"] as? String == "sess_001")
        #expect(passkeyNextActions(error?.reason ?? .unknown) == [.verifyPassword])
    }
}

#endif
