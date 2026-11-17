import Testing
import Foundation
@testable import Auth0

// Dedicated mock — never share static state with other test suites.
private final class EmbeddedAuthPKCEMockProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = EmbeddedAuthPKCEMockProtocol.requestHandler else {
            fatalError("EmbeddedAuthPKCEMockProtocol requires a requestHandler")
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
    config.protocolClasses = [EmbeddedAuthPKCEMockProtocol.self]
    return Auth0.embeddedAuth(clientId: clientId, domain: domain, session: URLSession(configuration: config))
}

private func response(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://\(domain)/")!, statusCode: status, httpVersion: nil, headerFields: nil)!
}

private func json(_ object: [String: Any]) -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: object)
}

private func insufficientAuth(session: String, action: String = "action:verify:otp:v1") -> Data {
    json(["error": "insufficient_authorization", "auth_session": session, "next": [["action": action]]])
}

private func credentials() -> Data {
    json(["access_token": "at", "token_type": "Bearer", "id_token": "it", "expires_in": 86400])
}

private func body(of request: URLRequest) -> [String: Any] {
    guard let data = request.httpBody,
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
    return object
}

private func isTokenRequest(_ request: URLRequest) -> Bool {
    request.url?.path.hasSuffix("/oauth/token") == true
}

private func isValidChallenge(_ value: String) -> Bool {
    value.range(of: "^[A-Za-z0-9\\-._~]{43,128}$", options: .regularExpression) != nil
}

/// Records every request the SDK makes and replies with a canned authorize/token response.
private final class Recorder: @unchecked Sendable {
    var authorizeBodies: [[String: Any]] = []
    var tokenBodies: [[String: Any]] = []
    var requests: [URLRequest] = []
}

// MARK: - Suite

@Suite(.serialized)
struct EmbeddedAuthPKCETests {

    /// Starts a flow and leaves the client holding `session`, then returns the recorder.
    private func startFlow(_ sut: EmbeddedAuth, session: String = "sess_001") async -> Recorder {
        let recorder = Recorder()
        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            recorder.requests.append(req)
            recorder.authorizeBodies.append(body(of: req))
            return (response(status: 403), insufficientAuth(session: session))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()
        return recorder
    }

    // MARK: authorize() — Initiate request

    @Test func authorizeSendsS256ChallengeAndMethod() async throws {
        let recorder = await startFlow(makeClient())
        let initiate = try #require(recorder.authorizeBodies.first)
        #expect(initiate["code_challenge_method"] as? String == "S256")
        let challenge = try #require(initiate["code_challenge"] as? String)
        #expect(isValidChallenge(challenge))
    }

    @Test func authorizeSendsDifferentChallengePerFlow() async throws {
        let sut = makeClient()
        let first = try #require(await startFlow(sut).authorizeBodies.first?["code_challenge"] as? String)
        let second = try #require(await startFlow(sut).authorizeBodies.first?["code_challenge"] as? String)
        #expect(first != second)
    }

    @Test func authorizeStoresVerifierMatchingChallenge() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        let recorder = await startFlow(sut)
        let challenge = try #require(recorder.authorizeBodies.first?["code_challenge"] as? String)
        let verifier = try #require(sut.currentVerifier)
        #expect(ChallengeGenerator(verifier: verifier).challenge == challenge)
    }

    @Test func authorizeNeverSendsTheVerifier() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        let recorder = await startFlow(sut)
        let initiate = try #require(recorder.authorizeBodies.first)
        #expect(initiate["code_verifier"] == nil)
        #expect(initiate["redirect_uri"] == nil)
    }

    // MARK: Continuation requests

    @Test func continuationsNeverSendPKCEFields() async throws {
        let sut = makeClient()
        _ = await startFlow(sut, session: "sess_001")
        let recorder = Recorder()
        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            recorder.authorizeBodies.append(body(of: req))
            return (response(status: 403), insufficientAuth(session: "sess_next"))
        }
        _ = try? await sut.identify("user@example.com", type: .email).start()
        _ = try? await sut.identify("+15551234567", type: .phone).start()
        _ = try? await sut.identify("user", type: .username).start()
        _ = try? await sut.challengeEmail(index: 0).start()
        _ = try? await sut.challengePhone(index: 0, deliveryMethod: .text).start()
        _ = try? await sut.challengePush(index: 0).start()
        _ = try? await sut.verifyRecoveryCode("recovery-code").start()
        _ = try? await sut.signup().start()

        #expect(recorder.authorizeBodies.count == 8)
        for continuation in recorder.authorizeBodies {
            #expect(continuation["code_challenge"] == nil)
            #expect(continuation["code_challenge_method"] == nil)
            #expect(continuation["code_verifier"] == nil)
        }
    }

    // MARK: /oauth/token exchange

    private func completingStep(_ name: String, _ sut: EmbeddedAuth) async throws -> Credentials {
        switch name {
        case "verifyOtp": return try await sut.verifyOtp("123456", type: .oob).start()
        case "verifyPassword": return try await sut.verifyPassword("secret").start()
        case "verifyOob": return try await sut.verifyOob().start()
        case "confirmRecoveryCode": return try await sut.confirmRecoveryCode().start()
        case "confirmSignupWithPassword": return try await sut.confirmSignup(password: "Passw0rd!").start()
        default: return try await sut.confirmSignup().start()
        }
    }

    @Test(arguments: ["verifyOtp", "verifyPassword", "verifyOob", "confirmRecoveryCode", "confirmSignup", "confirmSignupWithPassword"])
    func exchangeSendsVerifierMatchingTheChallenge(step: String) async throws {
        let sut = makeClient()
        let initiate = try #require(await startFlow(sut).authorizeBodies.first)
        let challenge = try #require(initiate["code_challenge"] as? String)

        let recorder = Recorder()
        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            if isTokenRequest(req) {
                recorder.tokenBodies.append(body(of: req))
                return (response(status: 200), credentials())
            }
            recorder.authorizeBodies.append(body(of: req))
            return (response(status: 200), json(["authorization_code": "auth0_ac_code"]))
        }
        _ = try await completingStep(step, sut)

        // The step that returns the code is a continuation, so it must not carry PKCE fields.
        let completing = try #require(recorder.authorizeBodies.first)
        #expect(completing["code_challenge"] == nil)
        #expect(completing["code_challenge_method"] == nil)
        #expect(completing["code_verifier"] == nil)

        let token = try #require(recorder.tokenBodies.first)
        let verifier = try #require(token["code_verifier"] as? String)
        #expect(ChallengeGenerator(verifier: verifier).challenge == challenge)
        #expect(token["grant_type"] as? String == "authorization_code")
        #expect(token["code"] as? String == "auth0_ac_code")
        #expect(token["client_id"] as? String == clientId)
        #expect(token["redirect_uri"] == nil)
    }

    @Test func verifierSurvivesSessionRotationAcrossSteps() async throws {
        let sut = makeClient()
        let initiate = try #require(await startFlow(sut, session: "sess_1").authorizeBodies.first)
        let challenge = try #require(initiate["code_challenge"] as? String)

        var step = 1
        let recorder = Recorder()
        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            if isTokenRequest(req) {
                recorder.tokenBodies.append(body(of: req))
                return (response(status: 200), credentials())
            }
            let action = body(of: req)["action"] as? String
            if action == "action:verify:otp:v1" {
                return (response(status: 200), json(["authorization_code": "auth0_ac_code"]))
            }
            step += 1
            return (response(status: 403), insufficientAuth(session: "sess_\(step)"))
        }
        _ = try? await sut.identify("user@example.com", type: .email).start()
        _ = try? await sut.challengeEmail(index: 0).start()
        _ = try await sut.verifyOtp("123456", type: .oob).start()

        let verifier = try #require(recorder.tokenBodies.first?["code_verifier"] as? String)
        #expect(ChallengeGenerator(verifier: verifier).challenge == challenge)
    }

    @Test func networkFailureOnInitiateStartsNoFlow() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        EmbeddedAuthPKCEMockProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        _ = try? await sut.authorize(connection: "test-connection").start()
        #expect(sut.currentVerifier == nil)
        #expect(sut.currentSession == nil)
    }

    /// Completes the in-progress flow through `/oauth/token`, appending the token request body to the recorder.
    private func completeFlow(_ sut: EmbeddedAuth, recorder: Recorder) async throws {
        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            if isTokenRequest(req) {
                recorder.tokenBodies.append(body(of: req))
                return (response(status: 200), credentials())
            }
            return (response(status: 200), json(["authorization_code": "auth0_ac_code"]))
        }
        _ = try await sut.verifyOtp("123456", type: .oob).start()
    }

    @Test func restartingAStoredAuthorizeRequestPairsWithItsOwnChallenge() async throws {
        let sut = makeClient()
        let stored = sut.authorize(connection: "test-connection")
        let recorder = Recorder()
        let initiateHandler: (URLRequest) throws -> (HTTPURLResponse, Data?) = { req in
            recorder.authorizeBodies.append(body(of: req))
            return (response(status: 403), insufficientAuth(session: "sess_001"))
        }
        EmbeddedAuthPKCEMockProtocol.requestHandler = initiateHandler
        _ = try? await stored.start()
        try await completeFlow(sut, recorder: recorder)

        // The flow ended. Restarting the same request resends its challenge, so the exchange must pair with its verifier.
        EmbeddedAuthPKCEMockProtocol.requestHandler = initiateHandler
        _ = try? await stored.start()
        try await completeFlow(sut, recorder: recorder)

        let challenges = recorder.authorizeBodies.compactMap { $0["code_challenge"] as? String }
        #expect(challenges.count == 2)
        #expect(recorder.tokenBodies.count == 2)
        for token in recorder.tokenBodies {
            let verifier = try #require(token["code_verifier"] as? String)
            #expect(ChallengeGenerator(verifier: verifier).challenge == challenges[0])
        }
    }

    @Test func startingAnOlderAuthorizeRequestPairsWithItsOwnChallenge() async throws {
        let sut = makeClient()
        let older = sut.authorize(connection: "test-connection")
        _ = sut.authorize(connection: "test-connection") // built second, never started
        let recorder = Recorder()
        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            recorder.authorizeBodies.append(body(of: req))
            return (response(status: 403), insufficientAuth(session: "sess_001"))
        }
        _ = try? await older.start()
        try await completeFlow(sut, recorder: recorder)

        let challenge = try #require(recorder.authorizeBodies.first?["code_challenge"] as? String)
        let verifier = try #require(recorder.tokenBodies.first?["code_verifier"] as? String)
        #expect(ChallengeGenerator(verifier: verifier).challenge == challenge)
    }

    @Test func aContinuationWithoutASessionDoesNotAdoptTheVerifier() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        EmbeddedAuthPKCEMockProtocol.requestHandler = { _ in
            (response(status: 403), json(["error": "insufficient_authorization", "next": [["action": "action:identify:email:v1"]]]))
        }
        _ = try? await sut.authorize(connection: "test-connection").start()
        #expect(sut.currentSession == nil)
        #expect(sut.currentVerifier == nil)
    }

    @Test func aLateContinuationLeavesASessionWithoutAVerifierAndTheExchangeFailsLocally() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        _ = await startFlow(sut)
        // An identify request built during the first flow, then a second flow begins before the first one answers.
        let late = sut.identify("user@example.com", type: .email)
        _ = sut.authorize(connection: "test-connection")

        let recorder = Recorder()
        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            recorder.requests.append(req)
            return (response(status: 403), insufficientAuth(session: "sess_late"))
        }
        _ = try? await late.start()
        // The late answer opens a session, but only an authorize response can supply a verifier.
        #expect(sut.currentSession == "sess_late")
        #expect(sut.currentVerifier == nil)

        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            recorder.requests.append(req)
            return (response(status: 200), json(["authorization_code": "auth0_ac_code"]))
        }
        let failure = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.verifyOtp("123456", type: .oob).start()
        }
        #expect(failure?.info["error"] as? String == "no_active_session")
        #expect(recorder.requests.allSatisfy { !isTokenRequest($0) }) // the code is never sent without PKCE
        #expect(sut.currentSession == nil)
        #expect(sut.currentVerifier == nil)
    }

    @Test func aTerminalAuthorizeFailureLeavesNoFlow() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        EmbeddedAuthPKCEMockProtocol.requestHandler = { _ in
            (response(status: 400), json(["error": "invalid_request", "error_description": "code_challenge is not supported"]))
        }
        let failure = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await sut.authorize(connection: "test-connection").start()
        }
        #expect(failure?.info["error"] as? String == "invalid_request")
        #expect(sut.currentVerifier == nil)
        #expect(sut.currentSession == nil)
    }

    @Test func networkFailureOnIntermediateStepKeepsTheVerifier() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        _ = await startFlow(sut)
        let verifier = try #require(sut.currentVerifier)
        EmbeddedAuthPKCEMockProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        _ = try? await sut.identify("user@example.com", type: .email).start()
        #expect(sut.currentVerifier == verifier)
        #expect(sut.currentSession == "sess_001")
    }

    @Test func networkFailureOnExchangeKeepsVerifierForRetry() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        _ = await startFlow(sut)
        let originalVerifier = try #require(sut.currentVerifier)

        let recorder = Recorder()
        nonisolated(unsafe) var failTokenRequest = true
        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            if isTokenRequest(req) {
                recorder.tokenBodies.append(body(of: req))
                if failTokenRequest { throw URLError(.notConnectedToInternet) }
                return (response(status: 200), credentials())
            }
            return (response(status: 200), json(["authorization_code": "auth0_ac_code"]))
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()
        #expect(sut.currentVerifier == originalVerifier)

        failTokenRequest = false
        _ = try await sut.verifyOtp("123456", type: .oob).start()
        #expect(recorder.tokenBodies.count == 2)
        #expect(recorder.tokenBodies.allSatisfy { $0["code_verifier"] as? String == originalVerifier })
    }

    // MARK: Verifier lifecycle

    @Test func verifierIsClearedAfterSuccessfulFlow() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        _ = await startFlow(sut)
        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            isTokenRequest(req)
                ? (response(status: 200), credentials())
                : (response(status: 200), json(["authorization_code": "auth0_ac_code"]))
        }
        _ = try await sut.verifyOtp("123456", type: .oob).start()
        #expect(sut.currentVerifier == nil)
        #expect(sut.currentSession == nil)
    }

    @Test func nextFlowUsesAFreshVerifier() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        _ = await startFlow(sut)
        let first = try #require(sut.currentVerifier)
        let recorder = await startFlow(sut)
        let second = try #require(sut.currentVerifier)
        #expect(first != second)
        let challenge = try #require(recorder.authorizeBodies.first?["code_challenge"] as? String)
        #expect(ChallengeGenerator(verifier: second).challenge == challenge)
    }

    @Test func verifierIsClearedOnTerminalFailure() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        _ = await startFlow(sut)
        EmbeddedAuthPKCEMockProtocol.requestHandler = { _ in
            (response(status: 403), json(["error": "access_denied", "error_description": "denied"]))
        }
        _ = try? await sut.verifyPassword("secret").start()
        #expect(sut.currentVerifier == nil)
        #expect(sut.currentSession == nil)
    }

    @Test func verifierIsKeptAcrossInsufficientAuthorization() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        _ = await startFlow(sut)
        let verifier = try #require(sut.currentVerifier)
        EmbeddedAuthPKCEMockProtocol.requestHandler = { _ in
            (response(status: 403), insufficientAuth(session: "sess_002"))
        }
        _ = try? await sut.identify("user@example.com", type: .email).start()
        #expect(sut.currentVerifier == verifier)
        #expect(sut.currentSession == "sess_002")
    }

    @Test func rejectedVerifierEndsTheFlowAsSessionExpired() async throws {
        let sut = try #require(makeClient() as? Auth0EmbeddedAuth)
        _ = await startFlow(sut)
        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            isTokenRequest(req)
                ? (response(status: 403), json(["error": "invalid_grant", "error_description": "bad verifier"]))
                : (response(status: 200), json(["authorization_code": "auth0_ac_code"]))
        }
        do {
            _ = try await sut.verifyOtp("123456", type: .oob).start()
            Issue.record("Expected the exchange to fail")
        } catch let error as EmbeddedAuthError {
            guard case .sessionExpired = error.reason else {
                Issue.record("Expected sessionExpired, got \(error.reason)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
        #expect(sut.currentVerifier == nil)
        #expect(sut.currentSession == nil)
    }

    // MARK: Logging

    @Test func loggingRedactsTheVerifier() async throws {
        let output = CapturingOutput()
        let sut = makeClient().using(logger: DefaultLogger(output: output))
        let recorder = Recorder()
        EmbeddedAuthPKCEMockProtocol.requestHandler = { _ in (response(status: 403), insufficientAuth(session: "sess_001")) }
        _ = try? await sut.authorize(connection: "test-connection").start()
        try await completeFlow(sut, recorder: recorder)

        let verifier = try #require(recorder.tokenBodies.first?["code_verifier"] as? String)
        await output.waitUntilLogged("code_verifier")
        #expect(output.text.contains("code_verifier"))
        #expect(output.text.contains("<REDACTED>"))
        #expect(!output.text.contains(verifier))
    }

    // MARK: Telemetry

    @Test func authorizeAndExchangeCarryTheAuth0ClientHeader() async throws {
        let sut = makeClient()
        let recorder = await startFlow(sut)
        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            recorder.requests.append(req)
            return isTokenRequest(req)
                ? (response(status: 200), credentials())
                : (response(status: 200), json(["authorization_code": "auth0_ac_code"]))
        }
        _ = try await sut.verifyOtp("123456", type: .oob).start()
        #expect(recorder.requests.count == 3)
        #expect(recorder.requests.allSatisfy { $0.value(forHTTPHeaderField: "Auth0-Client") != nil })
    }

    @Test func trackingOptOutRemovesTheAuth0ClientHeader() async throws {
        var sut = makeClient()
        sut.tracking(enabled: false)
        let recorder = await startFlow(sut)
        EmbeddedAuthPKCEMockProtocol.requestHandler = { req in
            recorder.requests.append(req)
            return isTokenRequest(req)
                ? (response(status: 200), credentials())
                : (response(status: 200), json(["authorization_code": "auth0_ac_code"]))
        }
        _ = try await sut.verifyOtp("123456", type: .oob).start()
        #expect(recorder.requests.allSatisfy { $0.value(forHTTPHeaderField: "Auth0-Client") == nil })
    }
}
