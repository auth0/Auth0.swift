import Testing
import Foundation
@testable import Auth0

// The claim and signature validators have their own specs (ClaimValidatorsSpec, IDTokenSignatureValidatorSpec,
// IDTokenValidatorSpec). These tests cover how the embedded-auth client wires them: the issuer and audience it
// expects, where it fetches the signing keys from, and what happens to the flow when validation fails.

private let tenantDomain = "test.auth0.com"
private let tenantIssuer = "https://test.auth0.com/"
private let testClientId = "TEST_CLIENT_ID"

/// A token for this tenant and client, signed with `TestKeys.rsaPrivate`; the mock serves the matching public key.
private let validIDToken = generateJWT(iss: tenantIssuer, aud: [testClientId]).string

/// How the mock answers the request for the tenant's signing keys.
private enum JWKSBehavior: Sendable, CustomTestStringConvertible {
    case serving
    case status(Int)
    case unreachable

    var testDescription: String {
        switch self {
        case .serving: return "serving"
        case .status(let code): return "status \(code)"
        case .unreachable: return "unreachable"
        }
    }
}

// Dedicated mock — never share static state with other test suites.
// Unlike the other embedded-auth mocks, the signing-keys endpoint is controllable here.
private final class IDTokenValidationMockProtocol: URLProtocol {
    /// Every step that ends the flow with an authorization code.
    private static let codeActions: Set<String> = ["action:verify:otp:v1",
                                                   "action:verify:oob:v1",
                                                   "action:verify:password:v1",
                                                   "action:confirm:recovery-code:v1"]

    nonisolated(unsafe) static var jwks = JWKSBehavior.serving
    nonisolated(unsafe) static var jwksRequestCount = 0
    nonisolated(unsafe) static var jwksRequestHeaders: [String: String] = [:]
    nonisolated(unsafe) static var jwksRequestURL: URL?
    nonisolated(unsafe) static var tokenRequestCount = 0
    nonisolated(unsafe) static var idToken: String?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        let (status, data): (Int, Data)
        switch url.path {
        case "/e/authorize":
            if request.httpBody == nil && request.httpBodyStream == nil {
                (status, data) = (400, Data())
            } else if let action = Self.sentAction(of: request), Self.codeActions.contains(action) {
                (status, data) = (200, jsonData(["authorization_code": "auth0_ac_test123"]))
            } else {
                (status, data) = (403, jsonData(["error": "insufficient_authorization",
                                                 "auth_session": "sess_001",
                                                 "next": [["action": "action:verify:otp:v1", "channel": "email"]]]))
            }
        case "/oauth/token":
            Self.tokenRequestCount += 1
            var credentials: [String: Any] = ["access_token": "test_access_token", "token_type": "Bearer", "expires_in": 86400]
            if let idToken = Self.idToken { credentials["id_token"] = idToken }
            (status, data) = (200, jsonData(credentials))
        case "/.well-known/jwks.json":
            Self.jwksRequestCount += 1
            Self.jwksRequestHeaders = request.allHTTPHeaderFields ?? [:]
            Self.jwksRequestURL = url
            switch Self.jwks {
            case .serving:
                (status, data) = (200, jwksResponse()(request).0 ?? Data())
            case .status(let code):
                (status, data) = (code, jwksResponse()(request).0 ?? Data())
            case .unreachable:
                client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
                return
            }
        default:
            (status, data) = (404, Data())
        }
        // swiftlint:disable:next force_unwrapping
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset(idToken: String?, jwks: JWKSBehavior = .serving) {
        self.idToken = idToken
        self.jwks = jwks
        jwksRequestCount = 0
        jwksRequestHeaders = [:]
        jwksRequestURL = nil
        tokenRequestCount = 0
    }

    private static func sentAction(of request: URLRequest) -> String? {
        var data = request.httpBody
        if data == nil, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var body = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: buffer.count)
                if read > 0 { body.append(buffer, count: read) } else { break }
            }
            data = body
        }
        guard let data,
              let json = try? JSONDecoder().decode([String: String?].self, from: data) else { return nil }
        return json["action"] ?? nil
    }
}

private func jsonData(_ object: [String: Any]) -> Data {
    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: object)
}

/// The steps that end a flow by exchanging the authorization code, so each one validates the ID token.
private enum FlowStep: CaseIterable, Sendable, CustomTestStringConvertible {
    case otp
    case oob
    case password
    case confirmRecoveryCode

    var testDescription: String {
        switch self {
        case .otp: return "verifyOtp"
        case .oob: return "verifyOob"
        case .password: return "verifyPassword"
        case .confirmRecoveryCode: return "confirmRecoveryCode"
        }
    }

    func request(on sut: EmbeddedAuth) -> Request<Credentials, EmbeddedAuthError> {
        switch self {
        case .otp: return sut.verifyOtp("123456", type: .oob)
        case .oob: return sut.verifyOob()
        case .password: return sut.verifyPassword("P@ssw0rd!")
        case .confirmRecoveryCode: return sut.confirmRecoveryCode()
        }
    }
}

private struct DidNotFail: Error {}

private func makeClient(tracking: Bool = true) -> EmbeddedAuth {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [IDTokenValidationMockProtocol.self]
    var client = Auth0.embeddedAuth(clientId: testClientId, domain: tenantDomain, session: URLSession(configuration: config))
    client.tracking(enabled: tracking)
    return client
}

/// Runs the first leg so that the client holds a session ready for any of the final steps.
private func makeClientWithSession(tracking: Bool = true) async -> EmbeddedAuth {
    let sut = makeClient(tracking: tracking)
    _ = try? await sut.authorize(connection: "test-connection").start()
    return sut
}

/// Completes the flow with a token the mock serves and returns the credentials.
private func credentials(idToken: String?,
                         step: FlowStep = .otp,
                         jwks: JWKSBehavior = .serving,
                         tracking: Bool = true) async throws -> Credentials {
    IDTokenValidationMockProtocol.reset(idToken: idToken, jwks: jwks)
    let sut = await makeClientWithSession(tracking: tracking)
    return try await step.request(on: sut).start()
}

/// Completes the flow with a token the mock serves and returns the error it ends with.
private func failure(idToken: String?,
                     step: FlowStep = .otp,
                     jwks: JWKSBehavior = .serving) async throws -> EmbeddedAuthError {
    do {
        _ = try await credentials(idToken: idToken, step: step, jwks: jwks)
    } catch let error as EmbeddedAuthError {
        return error
    }
    throw DidNotFail()
}

@Suite(.serialized)
struct EmbeddedAuthIDTokenValidationTests {

    // MARK: - Valid tokens

    @Test(arguments: FlowStep.allCases)
    private func returnsCredentialsWhenTheIDTokenIsValid(step: FlowStep) async throws {
        let credentials = try await credentials(idToken: validIDToken, step: step)

        #expect(credentials.idToken == validIDToken)
        #expect(credentials.accessToken == "test_access_token")
        #expect(IDTokenValidationMockProtocol.tokenRequestCount == 1)
        #expect(IDTokenValidationMockProtocol.jwksRequestCount == 1)
    }

    // The keys decide whether the token is trusted, so they must come from the tenant that issued it.
    @Test func fetchesTheSigningKeysFromTheTenantDomain() async throws {
        _ = try await credentials(idToken: validIDToken)

        #expect(IDTokenValidationMockProtocol.jwksRequestURL?.absoluteString == "https://\(tenantDomain)/.well-known/jwks.json")
    }

    @Test func requestsTheSigningKeysWithTheClientTelemetryHeader() async throws {
        _ = try await credentials(idToken: validIDToken)

        #expect(IDTokenValidationMockProtocol.jwksRequestHeaders["Auth0-Client"] != nil)
    }

    @Test func requestsTheSigningKeysWithoutTheClientTelemetryHeaderWhenTrackingIsDisabled() async throws {
        _ = try await credentials(idToken: validIDToken, tracking: false)

        #expect(IDTokenValidationMockProtocol.jwksRequestCount == 1)
        #expect(IDTokenValidationMockProtocol.jwksRequestHeaders["Auth0-Client"] == nil)
    }

    // A token is still accepted for a minute after it expired, to allow for clock skew.
    @Test func acceptsAnExpirationTimeThatPassedWithinTheLeeway() async throws {
        let idToken = generateJWT(iss: tenantIssuer, aud: [testClientId], exp: Date().addingTimeInterval(-30)).string

        let credentials = try await credentials(idToken: idToken)

        #expect(credentials.idToken == idToken)
    }

    @Test func doesNotCheckNonceOrOrganizationBecauseTheFlowNeverSendsThem() async throws {
        let idToken = generateJWT(iss: tenantIssuer, aud: [testClientId],
                                  nonce: "unexpected-nonce", orgID: "org_123", orgName: "acme").string

        let credentials = try await credentials(idToken: idToken)

        #expect(credentials.idToken == idToken)
    }

    // MARK: - Invalid tokens

    @Test(arguments: FlowStep.allCases)
    private func failsWhenTheIssuerDoesNotMatchTheDomain(step: FlowStep) async throws {
        let idToken = generateJWT(iss: "https://evil.example.com/", aud: [testClientId]).string

        let error = try await failure(idToken: idToken, step: step)

        let cause = try #require(error.cause as? IDTokenIssValidator.ValidationError)
        guard case .mismatchedIss(let actual, let expected) = cause else {
            Issue.record("Expected a mismatched issuer error, got \(cause)")
            return
        }
        #expect(actual == "https://evil.example.com/")
        #expect(expected == tenantIssuer)
        guard case .unknown = error.reason else {
            Issue.record("Expected the .unknown reason, got \(error.reason)")
            return
        }
    }

    @Test func failsWhenTheAudienceDoesNotMatchTheClientId() async throws {
        let idToken = generateJWT(iss: tenantIssuer, aud: ["SOME_OTHER_CLIENT"]).string

        let error = try await failure(idToken: idToken)

        let cause = try #require(error.cause as? IDTokenAudValidator.ValidationError)
        guard case .mismatchedAudString(let actual, let expected) = cause else {
            Issue.record("Expected a mismatched audience error, got \(cause)")
            return
        }
        #expect(actual == "SOME_OTHER_CLIENT")
        #expect(expected == testClientId)
    }

    // Just outside the 60 seconds of leeway, and well outside it.
    @Test(arguments: [-90.0, -3600.0])
    func failsWhenTheIDTokenHasExpired(secondsFromNow: Double) async throws {
        let idToken = generateJWT(iss: tenantIssuer, aud: [testClientId], exp: Date().addingTimeInterval(secondsFromNow)).string

        let error = try await failure(idToken: idToken)

        guard case .pastExp? = error.cause as? IDTokenExpValidator.ValidationError else {
            Issue.record("Expected a past expiration error, got \(String(describing: error.cause))")
            return
        }
    }

    @Test func failsWhenTheSignatureIsInvalid() async throws {
        let idToken = generateJWT(iss: tenantIssuer, aud: [testClientId], signature: "foo").string

        let error = try await failure(idToken: idToken)

        guard case .invalidSignature? = error.cause as? IDTokenSignatureValidator.ValidationError else {
            Issue.record("Expected an invalid signature error, got \(String(describing: error.cause))")
            return
        }
        #expect(!String(describing: error).contains(idToken), "The error must not expose the ID token")
    }

    // The token is never trusted without the keys to check it, whether the endpoint errors or cannot be reached.
    @Test(arguments: [JWKSBehavior.status(500), .status(404), .unreachable])
    private func failsWhenTheSigningKeysCannotBeFetched(jwks: JWKSBehavior) async throws {
        let error = try await failure(idToken: validIDToken, jwks: jwks)

        guard case .missingPublicKey? = error.cause as? IDTokenSignatureValidator.ValidationError else {
            Issue.record("Expected a missing public key error, got \(String(describing: error.cause))")
            return
        }
        #expect(IDTokenValidationMockProtocol.jwksRequestCount == 1)
    }

    @Test func failsWhenTheIDTokenCannotBeDecoded() async throws {
        let error = try await failure(idToken: "not-a-jwt")

        guard case .cannotDecode? = error.cause as? IDTokenDecodingError else {
            Issue.record("Expected a decoding error, got \(String(describing: error.cause))")
            return
        }
        #expect(IDTokenValidationMockProtocol.jwksRequestCount == 0)
    }

    // The default scope asks for `openid`; a response without an ID token cannot be validated, so it is rejected.
    @Test(arguments: [nil, ""] as [String?])
    func failsWhenTheResponseHasNoIDToken(idToken: String?) async throws {
        let error = try await failure(idToken: idToken)

        guard case .missingIDToken? = error.cause as? IDTokenDecodingError else {
            Issue.record("Expected a missing ID token error, got \(String(describing: error.cause))")
            return
        }
        #expect(IDTokenValidationMockProtocol.jwksRequestCount == 0)
    }

    // MARK: - Session

    @Test(arguments: FlowStep.allCases)
    private func clearsTheSessionWhenValidationFails(step: FlowStep) async throws {
        IDTokenValidationMockProtocol.reset(idToken: generateJWT(iss: "https://evil.example.com/", aud: [testClientId]).string)
        let sut = await makeClientWithSession()
        await #expect(throws: EmbeddedAuthError.self) {
            _ = try await step.request(on: sut).start()
        }

        // The authorization code is single-use, so the flow is over and a further step is rejected locally.
        let error = await #expect(throws: EmbeddedAuthError.self) {
            _ = try await step.request(on: sut).start()
        }

        #expect(error?.code == "no_active_session")
        #expect(IDTokenValidationMockProtocol.tokenRequestCount == 1)
    }

    // MARK: - APIs

    @Test func reportsTheValidationFailureToTheCallback() async throws {
        IDTokenValidationMockProtocol.reset(idToken: generateJWT(iss: "https://evil.example.com/", aud: [testClientId]).string)
        let sut = await makeClientWithSession()

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<Result<Credentials, EmbeddedAuthError>, Never>) in
            sut.verifyOtp("123456", type: .oob).start { continuation.resume(returning: $0) }
        }

        guard case .failure(let error) = result else {
            Issue.record("Expected a failure, got \(result)")
            return
        }
        #expect(error.cause is IDTokenIssValidator.ValidationError)
    }

    @Test func returnsCredentialsToTheCallbackWhenTheIDTokenIsValid() async throws {
        IDTokenValidationMockProtocol.reset(idToken: validIDToken)
        let sut = await makeClientWithSession()

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<Result<Credentials, EmbeddedAuthError>, Never>) in
            sut.verifyOtp("123456", type: .oob).start { continuation.resume(returning: $0) }
        }

        guard case .success(let credentials) = result else {
            Issue.record("Expected credentials, got \(result)")
            return
        }
        #expect(credentials.accessToken == "test_access_token")
    }
}
