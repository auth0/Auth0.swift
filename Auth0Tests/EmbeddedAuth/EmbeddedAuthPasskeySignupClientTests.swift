#if PASSKEYS_PLATFORM
import Testing
import Foundation
import AuthenticationServices
@testable import Auth0

// Dedicated mock — never share static state with other test suites.
private final class EmbeddedAuthPasskeySignupMockProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        // A request nothing expected fails this one test instead of crashing the whole test process.
        guard let handler = EmbeddedAuthPasskeySignupMockProtocol.requestHandler else {
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

// MARK: - Test vectors (chosen to exercise "-", "_" and the absence of padding)

private let challengeB64 = "Y2hhbGxlbmdl"                          // "challenge"
private let userHandleB64 = "Pj_-"                                 // [0x3e, 0x3f, 0xfe]
private let clientDataB64 = "eyJ0eXBlIjoid2ViYXV0aG4uY3JlYXRlIn0"  // {"type":"webauthn.create"}
private let attestationB64 = "o2NmbXT7_w"                          // [0xa3, 0x63, 0x66, 0x6d, 0x74, 0xfb, 0xff]
private let confirmActionName = "action:signup:confirm:v1"

private let passwordOptions: [String: Any] = ["min_length": 8, "character_types": ["lowercase", "number"]]

/// What the options of `creationOptions()` parse to.
private let expectedOptions = PasskeyCreationOptions(relyingPartyId: "login.example.com",
                                                     relyingPartyName: "Example",
                                                     challengeData: Data("challenge".utf8),
                                                     userId: Data([0x3e, 0x3f, 0xfe]),
                                                     userName: "user@example.com",
                                                     userDisplayName: "User",
                                                     userVerification: .preferred,
                                                     timeout: 900000)

/// The complete options object of `creationOptions()` as the SDK hands it out: sorted keys, no escaped slashes.
private let expectedCreationJson = #"{"authenticatorSelection":{"residentKey":"required","userVerification":"preferred"},"#
    + #""challenge":"Y2hhbGxlbmdl","pubKeyCredParams":[{"alg":-7,"type":"public-key"},{"alg":-257,"type":"public-key"}],"#
    + #""rp":{"id":"login.example.com","name":"Example"},"timeout":900000,"#
    + #""user":{"displayName":"User","id":"Pj_-","name":"user@example.com"}}"#

// MARK: - Helpers

private func makeClient() -> EmbeddedAuth {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [EmbeddedAuthPasskeySignupMockProtocol.self]
    return Auth0.embeddedAuth(clientId: signupClientId, domain: signupDomain, session: URLSession(configuration: config))
}

/// Valid creation options with `changes` applied and `key` left out, so that a malformed-offer row breaks one thing only.
private func creationOptions(_ changes: [String: Any] = [:], removing key: String? = nil) -> [String: Any] {
    var options: [String: Any] = [
        "challenge": challengeB64,
        "rp": ["id": "login.example.com", "name": "Example"],
        "user": ["id": userHandleB64, "name": "user@example.com", "displayName": "User"],
        "pubKeyCredParams": [["type": "public-key", "alg": -7], ["type": "public-key", "alg": -257]],
        "authenticatorSelection": ["residentKey": "required", "userVerification": "preferred"],
        "timeout": 900000
    ]
    options.merge(changes) { _, new in new }
    if let key { options.removeValue(forKey: key) }
    return options
}

/// A confirm-sign-up entry of `next`, with the password hints and the passkey options unless they are left out.
private func confirmEntry(password: [String: Any]? = passwordOptions,
                          passkey: [String: Any]? = creationOptions()) -> [String: Any] {
    var entry: [String: Any] = ["action": confirmActionName]
    if let password { entry["password_complexity_options"] = password }
    if let passkey { entry["authn_params_public_key"] = passkey }
    return entry
}

private func insufficientAuth(session: String, description: String? = nil, nextActions: [[String: Any]]) -> Data {
    var json: [String: Any] = ["error": "insufficient_authorization", "auth_session": session, "next": nextActions]
    if let description { json["error_description"] = description }
    return data(json)
}

private func data(_ json: [String: Any]) -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: json)
}

private func authCode(_ code: String = "auth0_ac_test123") -> Data {
    data(["authorization_code": code])
}

private func credentials() -> Data {
    data(["access_token": "test_access_token", "token_type": "Bearer", "id_token": "test_id_token", "expires_in": 86400])
}

private func response(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://\(signupDomain)/")!, statusCode: status, httpVersion: nil, headerFields: nil)!
}

/// The JSON object of a request body.
private func requestJSON(_ request: URLRequest) -> [String: Any]? {
    request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
}

private func isTokenRequest(_ request: URLRequest) -> Bool {
    request.url?.path.hasSuffix("/oauth/token") == true
}

/// Records every request that reaches the network layer, so a test can assert on it or that nothing was sent.
private final class RequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [URLRequest] = []

    var requests: [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    var authorizeBodies: [[String: Any]] {
        requests.filter { $0.url?.path == "/e/authorize" }.compactMap(requestJSON)
    }

    var tokenBodies: [[String: Any]] {
        requests.filter(isTokenRequest).compactMap(requestJSON)
    }

    func record(_ request: URLRequest) {
        lock.lock()
        recorded.append(request)
        lock.unlock()
    }
}

/// Handler for a flow that completes: `/e/authorize` returns a code and `/oauth/token` returns credentials.
private func installSuccessHandler(_ recorder: RequestRecorder) {
    EmbeddedAuthPasskeySignupMockProtocol.requestHandler = { req in
        recorder.record(req)
        return isTokenRequest(req) ? (response(status: 200), credentials()) : (response(status: 200), authCode())
    }
}

/// Opens a flow whose session is `session` and whose first `next` is `nextActions`, by running authorize() through the mock.
private func establishSession(_ client: EmbeddedAuth,
                              session: String = "sess_001",
                              nextActions: [[String: Any]] = [confirmEntry()],
                              recorder: RequestRecorder = RequestRecorder()) async {
    EmbeddedAuthPasskeySignupMockProtocol.requestHandler = { req in
        recorder.record(req)
        return (response(status: 403), insufficientAuth(session: session, nextActions: nextActions))
    }
    _ = try? await client.authorize(connection: "test-connection").start()
}

/// The `nextActions` of an `insufficient_authorization` reason, or `nil` for any other reason.
private func nextActions(of reason: EmbeddedAuthErrorReason) -> [NextAction]? {
    guard case .insufficientAuthorization(_, let actions) = reason else { return nil }
    return actions
}

/// The `nextActions` a server answer with `entries` as its `next` gives.
private func actions(from entries: [[String: Any]], description: String? = nil) -> [NextAction]? {
    var info: [String: Any] = ["error": "insufficient_authorization", "auth_session": "sess_x", "next": entries]
    if let description { info["error_description"] = description }
    return nextActions(of: EmbeddedAuthError(info: info, statusCode: 403).reason)
}

@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
private struct MockSignupPasskey: SignupPasskey {
    var credentialID = Data([0xfb, 0xff, 0xbf])                                         // "-_-_"
    var attachment: ASAuthorizationPublicKeyCredentialAttachment = .platform
    var rawClientDataJSON = Data(#"{"type":"webauthn.create"}"#.utf8)                    // clientDataB64
    var rawAttestationObject: Data? = Data([0xa3, 0x63, 0x66, 0x6d, 0x74, 0xfb, 0xff])  // attestationB64
}

// MARK: - Suite

@Suite(.serialized)
struct EmbeddedAuthPasskeySignupClientTests {

    init() {
        EmbeddedAuthPasskeySignupMockProtocol.requestHandler = nil
    }

    // MARK: Parsing the offer

    @Test func theConfirmEntryYieldsConfirmSignupAndThePasskeyOffer() {
        let password = SignupPassword(isRequired: false,
                                      complexity: SignupPasswordComplexity(minLength: 8, characterTypes: [.lowercase, .number]))
        #expect(actions(from: [confirmEntry()]) == [.confirmSignup(password: password),
                                                    .registerPasskey(options: expectedOptions, creationJson: expectedCreationJson)])
    }

    @Test func aConnectionWithoutAPasswordStillOffersThePasskey() {
        #expect(actions(from: [confirmEntry(password: nil)]) == [.confirmSignup(password: nil),
                                                                 .registerPasskey(options: expectedOptions,
                                                                                  creationJson: expectedCreationJson)])
    }

    @Test func aConfirmEntryWithoutPasskeyOptionsOffersNone() {
        #expect(actions(from: [confirmEntry(password: nil, passkey: nil)]) == [.confirmSignup(password: nil)])
    }

    @Test func otherEntriesNeverOfferAPasskey() {
        let entries: [[String: Any]] = [["action": "action:identify:email:v1", "authn_params_public_key": creationOptions()],
                                        ["action": "action:signup:v1",
                                         "identifiers": ["email": ["required": true]],
                                         "authentication_methods": ["password": ["required": false], "passkey": ["required": false]]]]
        let offered = actions(from: entries)
        #expect(offered == [.identifyEmail, .signup(identifiers: [SignupIdentifier(type: .email, isRequired: true)],
                                                    passwordRequirement: .optional)])
    }

    @Test func creationJsonIsTheCompleteOptionsObjectIncludingUnknownKeys() throws {
        let sent = creationOptions(["attestation": "none", "extensions": ["credProps": true]])
        let offered = try #require(actions(from: [confirmEntry(passkey: sent)]))
        guard case .registerPasskey(_, let creationJson)? = offered.last else {
            Issue.record("Expected a passkey offer"); return
        }
        let object = try #require(JSONSerialization.jsonObject(with: Data(creationJson.utf8)) as? [String: Any])
        #expect(NSDictionary(dictionary: object) == NSDictionary(dictionary: sent))
    }

    @Test func creationJsonDoesNotDependOnTheOrderOfTheKeys() throws {
        let first = #"{"challenge":"Y2hhbGxlbmdl","rp":{"id":"a.com","name":"A"},"timeout":1,"user":{"id":"Pj_-","name":"n","displayName":"d"}}"#
        let second = #"{"user":{"displayName":"d","name":"n","id":"Pj_-"},"timeout":1,"rp":{"name":"A","id":"a.com"},"challenge":"Y2hhbGxlbmdl"}"#
        func creationJson(of body: String) throws -> String? {
            let options = try #require(JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])
            guard case .registerPasskey(_, let json)? = actions(from: [confirmEntry(passkey: options)])?.last else { return nil }
            return json
        }
        let one = try creationJson(of: first)
        let other = try creationJson(of: second)
        #expect(one != nil)
        #expect(one == other)
    }

    @Test(arguments: ["required", "preferred", "discouraged"])
    func parsesEachUserVerificationValue(raw: String) {
        let options = creationOptions(["authenticatorSelection": ["userVerification": raw]])
        guard case .registerPasskey(let parsed, _)? = actions(from: [confirmEntry(passkey: options)])?.last else {
            Issue.record("Expected a passkey offer"); return
        }
        #expect(parsed.userVerification.rawValue == raw)
    }

    @Test(arguments: [
        ("authenticatorSelection is missing", creationOptions(removing: "authenticatorSelection")),
        ("authenticatorSelection is empty", creationOptions(["authenticatorSelection": [String: Any]()])),
        ("only residentKey is sent", creationOptions(["authenticatorSelection": ["residentKey": "required"]]))
    ])
    func userVerificationDefaultsToPreferred(_ scenario: String, _ options: [String: Any]) {
        guard case .registerPasskey(let parsed, _)? = actions(from: [confirmEntry(passkey: options)])?.last else {
            Issue.record("Expected a passkey offer"); return
        }
        #expect(parsed.userVerification == .preferred, Comment(rawValue: scenario))
    }

    @Test func theTimeoutAndTheDisplayNameAreTakenAsSent() {
        let options = creationOptions(["timeout": 0, "user": ["id": userHandleB64, "name": "n", "displayName": ""]])
        guard case .registerPasskey(let parsed, _)? = actions(from: [confirmEntry(passkey: options)])?.last else {
            Issue.record("Expected a passkey offer"); return
        }
        #expect(parsed.timeout == 0)
        #expect(parsed.userDisplayName == "")
    }

    @Test(arguments: [
        ("challenge is missing", creationOptions(removing: "challenge")),
        ("challenge is empty", creationOptions(["challenge": ""])),
        ("challenge is not base64url", creationOptions(["challenge": "***"])),
        ("challenge is not a string", creationOptions(["challenge": 5])),
        ("rp is missing", creationOptions(removing: "rp")),
        ("rp is not an object", creationOptions(["rp": "login.example.com"])),
        ("rp id is missing", creationOptions(["rp": ["name": "Example"]])),
        ("rp id is empty", creationOptions(["rp": ["id": "", "name": "Example"]])),
        ("rp name is missing", creationOptions(["rp": ["id": "login.example.com"]])),
        ("user is missing", creationOptions(removing: "user")),
        ("user id is missing", creationOptions(["user": ["name": "n", "displayName": "d"]])),
        ("user id is empty", creationOptions(["user": ["id": "", "name": "n", "displayName": "d"]])),
        ("user id is not base64url", creationOptions(["user": ["id": "***", "name": "n", "displayName": "d"]])),
        ("user name is missing", creationOptions(["user": ["id": userHandleB64, "displayName": "d"]])),
        ("user name is empty", creationOptions(["user": ["id": userHandleB64, "name": "", "displayName": "d"]])),
        ("user displayName is missing", creationOptions(["user": ["id": userHandleB64, "name": "n"]])),
        ("timeout is missing", creationOptions(removing: "timeout")),
        ("timeout is not an integer", creationOptions(["timeout": "soon"])),
        ("timeout has a fraction", creationOptions(["timeout": 1.5])),
        ("timeout is a boolean", creationOptions(["timeout": true])),
        ("authenticatorSelection is not an object", creationOptions(["authenticatorSelection": "required"])),
        ("userVerification is not a string", creationOptions(["authenticatorSelection": ["userVerification": 1]])),
        ("userVerification is not a known value", creationOptions(["authenticatorSelection": ["userVerification": "sometimes"]]))
    ])
    func dropsMalformedPasskeyOffersButKeepsTheConfirmStep(_ scenario: String, _ options: [String: Any]) {
        #expect(actions(from: [confirmEntry(password: nil, passkey: options)]) == [.confirmSignup(password: nil)],
                Comment(rawValue: scenario))
    }

    @Test func aConfirmEntryTheSDKCannotReadOffersNoPasskeyEither() {
        let unreadable = confirmEntry(password: ["min_length": "eight"])
        #expect(actions(from: [unreadable]) == [])
    }

    // MARK: confirmSignup(passkey:) — request

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func sendsExactlyTheFieldsTheServerAccepts() async throws {
        let sut = makeClient()
        await establishSession(sut, session: "sess_001")
        let recorder = RequestRecorder()
        installSuccessHandler(recorder)

        _ = try await sut.confirmSignup(passkey: MockSignupPasskey()).start()

        let authorize = try #require(recorder.requests.first { $0.url?.path == "/e/authorize" })
        #expect(authorize.httpMethod == "POST")
        #expect(authorize.value(forHTTPHeaderField: "Auth0-Client") != nil)
        let body = try #require(requestJSON(authorize))
        #expect(Set(body.keys) == ["client_id", "action", "auth_session", "passkey"])
        #expect(body["client_id"] as? String == signupClientId)
        #expect(body["action"] as? String == confirmActionName)
        #expect(body["auth_session"] as? String == "sess_001")

        let registration = try #require(body["passkey"] as? [String: Any])
        #expect(Set(registration.keys) == ["id", "rawId", "type", "authenticatorAttachment", "clientExtensionResults", "response"])
        #expect(registration["id"] as? String == "-_-_")
        #expect(registration["rawId"] as? String == "-_-_")
        #expect(registration["type"] as? String == "public-key")
        #expect(registration["authenticatorAttachment"] as? String == "platform")
        // No extension was requested, so the results are the empty object a browser would send.
        let extensionResults = try #require(registration["clientExtensionResults"] as? [String: Any])
        #expect(extensionResults.isEmpty)

        let response = try #require(registration["response"] as? [String: Any])
        #expect(Set(response.keys) == ["clientDataJSON", "attestationObject"])
        #expect(response["clientDataJSON"] as? String == clientDataB64)
        #expect(response["attestationObject"] as? String == attestationB64)

        let encoded = [registration["id"], registration["rawId"]] + response.values.map { Optional($0) }
        for value in encoded.compactMap({ $0 as? String }) {
            #expect(!value.contains("="))
            #expect(!value.contains("+"))
            #expect(!value.contains("/"))
        }
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func sendsTheCrossPlatformAttachment() async throws {
        let sut = makeClient()
        await establishSession(sut)
        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        var passkey = MockSignupPasskey()
        passkey.attachment = .crossPlatform

        _ = try await sut.confirmSignup(passkey: passkey).start()

        let registration = recorder.authorizeBodies.first?["passkey"] as? [String: Any]
        #expect(registration?["authenticatorAttachment"] as? String == "cross-platform")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func anUnknownAttachmentIsLeftOut() async throws {
        let sut = makeClient()
        await establishSession(sut)
        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        var passkey = MockSignupPasskey()
        passkey.attachment = try #require(ASAuthorizationPublicKeyCredentialAttachment(rawValue: 99))

        _ = try await sut.confirmSignup(passkey: passkey).start()

        let registration = try #require(recorder.authorizeBodies.first?["passkey"] as? [String: Any])
        #expect(Set(registration.keys) == ["id", "rawId", "type", "clientExtensionResults", "response"])
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func confirmingWithoutAPasskeySendsNone() async throws {
        let sut = makeClient()
        await establishSession(sut) // the offer carries passkey options
        let recorder = RequestRecorder()
        installSuccessHandler(recorder)

        _ = try await sut.confirmSignup(password: nil).start()

        let body = try #require(recorder.authorizeBodies.first)
        #expect(Set(body.keys) == ["client_id", "action", "auth_session"])
    }

    // MARK: confirmSignup(passkey:) — success

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func returnsCredentialsAfterExchangingTheCodeWithThePKCEVerifier() async throws {
        let sut = makeClient()
        let recorder = RequestRecorder()
        await establishSession(sut, recorder: recorder)
        let challenge = try #require(recorder.authorizeBodies.first?["code_challenge"] as? String)
        installSuccessHandler(recorder)

        let credentials = try await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        #expect(credentials.accessToken == "test_access_token")

        let token = try #require(recorder.tokenBodies.first)
        #expect(token["grant_type"] as? String == "authorization_code")
        #expect(token["code"] as? String == "auth0_ac_test123")
        let verifier = try #require(token["code_verifier"] as? String)
        #expect(ChallengeGenerator(verifier: verifier).challenge == challenge)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func clearsTheSessionOnSuccess() async throws {
        let sut = makeClient()
        await establishSession(sut)
        installSuccessHandler(RequestRecorder())

        _ = try await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        }
        #expect(error?.code == "no_active_session")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func supportsTheCallbackAPI() async {
        let sut = makeClient()
        await establishSession(sut)
        installSuccessHandler(RequestRecorder())

        let credentials = await withCheckedContinuation { continuation in
            sut.confirmSignup(passkey: MockSignupPasskey()).start { result in
                continuation.resume(returning: try? result.get())
            }
        }
        #expect(credentials?.accessToken == "test_access_token")
    }

    // MARK: confirmSignup(passkey:) — local failures

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func failsLocallyWithNoSessionAndSendsNothing() async {
        let sut = makeClient()
        let recorder = RequestRecorder()
        installSuccessHandler(recorder)

        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        }
        #expect(error?.code == "no_active_session")
        #expect(error?.statusCode == 0)
        #expect(recorder.requests.isEmpty)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func checksTheSessionBeforeThePasskey() async {
        let sut = makeClient()
        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        var passkey = MockSignupPasskey()
        passkey.rawAttestationObject = nil // Would be .invalidInput if there were a session.

        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(passkey: passkey).start()
        }
        #expect(error?.code == "no_active_session")
        #expect(recorder.requests.isEmpty)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test(arguments: [
        ("credential ID is empty", "This passkey has no credential ID."),
        ("client data is empty", "This passkey has no client data."),
        ("attestation object is nil", "This passkey has no attestation object."),
        ("attestation object is empty", "This passkey has no attestation object.")
    ])
    func invalidInputSendsNothingAndKeepsTheSession(scenario: String, message: String) async {
        let sut = makeClient()
        await establishSession(sut, session: "sess_001")

        var passkey = MockSignupPasskey()
        switch scenario {
        case "credential ID is empty": passkey.credentialID = Data()
        case "client data is empty": passkey.rawClientDataJSON = Data()
        case "attestation object is nil": passkey.rawAttestationObject = nil
        default: passkey.rawAttestationObject = Data()
        }

        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(passkey: passkey).start()
        }
        guard case .invalidInput(let reported)? = error?.reason else {
            Issue.record("Expected .invalidInput, got \(String(describing: error?.reason))"); return
        }
        #expect(reported == message)
        #expect(error?.statusCode == 0)
        #expect(recorder.requests.isEmpty)

        // The session is still there: a valid passkey goes through with the original session.
        _ = try? await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        #expect(recorder.authorizeBodies.first?["auth_session"] as? String == "sess_001")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func theInvalidInputMessageNeverContainsPasskeyData() async {
        let sut = makeClient()
        await establishSession(sut)
        var passkey = MockSignupPasskey()
        passkey.rawAttestationObject = nil

        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(passkey: passkey).start()
        }
        let text = error?.debugDescription ?? ""
        for fragment in ["-_-_", clientDataB64, attestationB64] {
            #expect(!text.contains(fragment))
        }
    }

    // MARK: confirmSignup(passkey:) — continuations

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func aRejectedRegistrationOffersTheSamePasskeyAgainAndKeepsTheFlowOpen() async throws {
        let sut = makeClient()
        await establishSession(sut, session: "sess_001")

        EmbeddedAuthPasskeySignupMockProtocol.requestHandler = { _ in
            (response(status: 403),
             insufficientAuth(session: "sess_002", description: "passkey_registration_failed", nextActions: [confirmEntry()]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        }
        guard case .insufficientAuthorization(.passkeyRegistrationFailed, let actions)? = error?.reason else {
            Issue.record("Expected .passkeyRegistrationFailed, got \(String(describing: error?.reason))"); return
        }
        #expect(actions.contains(.registerPasskey(options: expectedOptions, creationJson: expectedCreationJson)))

        // The credential already exists on the device, so the same registration is sent again, on the rotated session.
        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        _ = try await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        #expect(recorder.authorizeBodies.first?["auth_session"] as? String == "sess_002")
        #expect(recorder.authorizeBodies.first?["passkey"] != nil)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func aRejectedRegistrationCanBeLeftOutToSignUpWithoutAPasskey() async throws {
        let sut = makeClient()
        await establishSession(sut, session: "sess_001")

        EmbeddedAuthPasskeySignupMockProtocol.requestHandler = { _ in
            (response(status: 403),
             insufficientAuth(session: "sess_002", description: "passkey_registration_failed", nextActions: [confirmEntry()]))
        }
        _ = try? await sut.confirmSignup(passkey: MockSignupPasskey()).start()

        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        _ = try await sut.confirmSignup(password: nil).start()
        let body = try #require(recorder.authorizeBodies.first)
        #expect(body["auth_session"] as? String == "sess_002")
        #expect(body["passkey"] == nil)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func aPasswordAnswerKeepsTheCorrectedPasswordFlagAndTheUntouchedPasskeyOffer() async throws {
        let sut = makeClient()
        let signupOffer: [String: Any] = ["action": "action:signup:v1",
                                          "identifiers": ["email": ["required": true]],
                                          "authentication_methods": ["password": ["required": true], "passkey": ["required": false]]]
        await establishSession(sut, nextActions: [signupOffer])

        EmbeddedAuthPasskeySignupMockProtocol.requestHandler = { _ in
            (response(status: 403),
             insufficientAuth(session: "sess_002", description: "password_required", nextActions: [confirmEntry()]))
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(password: nil).start()
        }
        guard case .insufficientAuthorization(.passwordRequired, let actions)? = error?.reason else {
            Issue.record("Expected .passwordRequired, got \(String(describing: error?.reason))"); return
        }
        let password = SignupPassword(isRequired: true,
                                      complexity: SignupPasswordComplexity(minLength: 8, characterTypes: [.lowercase, .number]))
        #expect(actions == [.confirmSignup(password: password),
                            .registerPasskey(options: expectedOptions, creationJson: expectedCreationJson)])
    }

    // MARK: confirmSignup(passkey:) — failures

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func aTerminalFailureClearsTheSession() async {
        let sut = makeClient()
        await establishSession(sut)

        EmbeddedAuthPasskeySignupMockProtocol.requestHandler = { _ in
            (response(status: 403), data(["error": "access_denied", "error_description": "denied"]))
        }
        let first = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        }
        guard case .accessDenied? = first?.reason else {
            Issue.record("Expected .accessDenied, got \(String(describing: first?.reason))"); return
        }

        let next = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        }
        #expect(next?.code == "no_active_session")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func aNetworkFailureKeepsTheSession() async {
        let sut = makeClient()
        await establishSession(sut, session: "sess_001")

        EmbeddedAuthPasskeySignupMockProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        }
        guard case .network? = error?.reason else {
            Issue.record("Expected .network, got \(String(describing: error?.reason))"); return
        }

        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        _ = try? await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        #expect(recorder.authorizeBodies.first?["auth_session"] as? String == "sess_001")
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func aNetworkFailureOnTheTokenExchangeKeepsTheSession() async {
        let sut = makeClient()
        await establishSession(sut, session: "sess_001")

        EmbeddedAuthPasskeySignupMockProtocol.requestHandler = { req in
            if isTokenRequest(req) { throw URLError(.networkConnectionLost) }
            return (response(status: 200), authCode())
        }
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        }
        guard case .network? = error?.reason else {
            Issue.record("Expected .network, got \(String(describing: error?.reason))"); return
        }

        let recorder = RequestRecorder()
        installSuccessHandler(recorder)
        _ = try? await sut.confirmSignup(passkey: MockSignupPasskey()).start()
        #expect(recorder.authorizeBodies.first?["auth_session"] as? String == "sess_001")
    }

    // MARK: Logging

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    @Test func theLogNeverContainsTheRegistrationOrTheChallenge() async {
        let output = CapturingOutput()
        let sut = makeClient().using(logger: DefaultLogger(output: output))
        await establishSession(sut)
        installSuccessHandler(RequestRecorder())

        _ = try? await sut.confirmSignup(passkey: MockSignupPasskey()).start()

        // The logger writes asynchronously, in order: once the token request is logged, the confirm request is too.
        await output.waitUntilLogged("/oauth/token")
        #expect(output.text.contains("/oauth/token"))
        #expect(output.text.contains(confirmActionName))
        #expect(output.text.contains("login.example.com"))
        #expect(output.text.contains("<REDACTED>"))
        for fragment in [challengeB64, "-_-_", clientDataB64, attestationB64] {
            #expect(!output.text.contains(fragment))
        }
    }
}

#endif

#if !PASSKEYS_PLATFORM
import Testing
import Foundation
@testable import Auth0

/// The server sends the passkey options to every client, so a platform without passkeys must ignore them.
struct EmbeddedAuthPasskeySignupUnsupportedPlatformTests {

    @Test func aConfirmEntryWithPasskeyOptionsGivesOnlyTheConfirmStep() {
        // Complete options: a platform with passkeys would offer them.
        let options: [String: Any] = ["challenge": "Y2hhbGxlbmdl",
                                      "rp": ["id": "login.example.com", "name": "Example"],
                                      "user": ["id": "Pj_-", "name": "user@example.com", "displayName": "User"],
                                      "pubKeyCredParams": [["type": "public-key", "alg": -7]],
                                      "authenticatorSelection": ["residentKey": "required", "userVerification": "preferred"],
                                      "timeout": 900000]
        let entry: [String: Any] = ["action": "action:signup:confirm:v1", "authn_params_public_key": options]
        let info: [String: Any] = ["error": "insufficient_authorization", "auth_session": "sess_x", "next": [entry]]
        guard case .insufficientAuthorization(_, let actions) = EmbeddedAuthError(info: info, statusCode: 403).reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions == [.confirmSignup(password: nil)])
    }

}
#endif
