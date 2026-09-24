import Testing
import Foundation
@testable import Auth0

// Dedicated mock protocol so EmbeddedAuthTests never shares static state with Auth0MFAClientTests,
// which also registers MockURLProtocol. The two @Suite(.serialized) structs run concurrently in
// Swift Testing, and a shared static requestHandler causes handler cross-contamination.
private final class EmbeddedAuthMockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = EmbeddedAuthMockURLProtocol.requestHandler else {
            fatalError("EmbeddedAuthMockURLProtocol requires a requestHandler.")
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data { client?.urlProtocol(self, didLoad: data) }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private let clientId = "TEST_CLIENT_ID"
private let domain = "test.auth0.com"

// MARK: - Fixtures

private let authorizationCodeAlt: [String: Any] = [
    "grant_type": "authorization_code",
    "type": "embedded_authorize",
    "connection": "my-db"
]

private let tokenExchangeGoogleAlt: [String: Any] = [
    "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
    "subject_token_type": "http://auth0.com/oauth/token-type/google-id-token"
]

private let tokenExchangeAppleAlt: [String: Any] = [
    "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
    "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code"
]

private let tokenExchangeFacebookAlt: [String: Any] = [
    "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
    "subject_token_type": "http://auth0.com/oauth/token-type/facebook-info-session-access-token"
]

private let passwordAlt: [String: Any] = [
    "grant_type": "password"
]

private let passkeyAlt: [String: Any] = [
    "grant_type": "urn:okta:params:oauth:grant-type:webauthn",
    "connection": "my-db"
]

private let passwordlessOtpLegacyAlt: [String: Any] = [
    "grant_type": "http://auth0.com/oauth/grant-type/passwordless/otp",
    "type": "legacy",
    "connection": "email",
    "identifier_types": ["email"]
]

private let passwordlessOtpAuth0Alt: [String: Any] = [
    "grant_type": "http://auth0.com/oauth/grant-type/passwordless/otp",
    "type": "auth0",
    "connection": "my-db",
    "identifier_types": ["email", "phone_number"]
]

private let passwordRealmAlt: [String: Any] = [
    "grant_type": "http://auth0.com/oauth/grant-type/password-realm",
    "realm": "Username-Password-Authentication"
]

private let unknownAlt: [String: Any] = [
    "grant_type": "urn:custom:grant-type:future",
    "connection": "some-conn"
]

// MARK: - Suite

@Suite(.serialized)
struct EmbeddedAuthTests {

    private func makeClient() -> EmbeddedAuth {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [EmbeddedAuthMockURLProtocol.self]
        return Auth0.embeddedAuth(clientId: clientId, domain: domain, session: URLSession(configuration: config))
    }

    private func successData(alternatives: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: ["alternatives": alternatives])
    }

    private func successResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://\(domain)/")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private func errorResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://\(domain)/")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    private func errorData(_ json: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: json)
    }

    // MARK: - Factory

    @Test func factoryCreatesClientWithExplicitParams() {
        let client = Auth0.embeddedAuth(clientId: clientId, domain: domain) as! Auth0EmbeddedAuth
        #expect(client.clientId == clientId)
        #expect(client.url.absoluteString == "https://\(domain)/")
    }

    @Test func factoryUsesSharedSessionByDefault() {
        let client = Auth0.embeddedAuth(clientId: clientId, domain: domain) as! Auth0EmbeddedAuth
        #expect(client.session === URLSession.shared)
    }

    @Test func factoryAcceptsCustomSession() {
        let custom = URLSession(configuration: .ephemeral)
        let client = Auth0.embeddedAuth(clientId: clientId, domain: domain, session: custom) as! Auth0EmbeddedAuth
        #expect(client.session === custom)
    }

    // MARK: - Empty alternatives

    @Test func discoverReturnsEmptyOptionsAndTypes() async {
        let sut = makeClient()
        let data = successData(alternatives: [])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                #expect(result.options.isEmpty)
                #expect(result.types.isEmpty)
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - authorization_code

    @Test func discoverDecodesEmbeddedAuthorize() async {
        let sut = makeClient()
        let data = successData(alternatives: [authorizationCodeAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                guard case .authorizationCode(let conn) = result.options.first else {
                    Issue.record("Expected .authorizationCode"); return
                }
                #expect(conn == "my-db")
                #expect(result.supports(.authorizationCode))
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - token-exchange (nativeSocial)

    @Test func discoverDecodesGoogleNativeSocial() async {
        let sut = makeClient()
        let data = successData(alternatives: [tokenExchangeGoogleAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                guard case .nativeSocial(let stt) = result.options.first else {
                    Issue.record("Expected .nativeSocial"); return
                }
                #expect(stt == "http://auth0.com/oauth/token-type/google-id-token")
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test func discoverDecodesAppleNativeSocial() async {
        let sut = makeClient()
        let data = successData(alternatives: [tokenExchangeAppleAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                guard case .nativeSocial(let stt) = result.options.first else {
                    Issue.record("Expected .nativeSocial"); return
                }
                #expect(stt == "http://auth0.com/oauth/token-type/apple-authz-code")
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test func discoverPopulatesSocialProviders() async {
        let sut = makeClient()
        let data = successData(alternatives: [tokenExchangeGoogleAlt, tokenExchangeAppleAlt, tokenExchangeFacebookAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                #expect(result.socialProviders.count == 3)
                #expect(result.socialProviders.contains("http://auth0.com/oauth/token-type/google-id-token"))
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - password

    @Test func discoverDecodesPasswordOption() async {
        let sut = makeClient()
        let data = successData(alternatives: [passwordAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                guard case .password = result.options.first else {
                    Issue.record("Expected .password"); return
                }
                #expect(result.supports(.password))
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - passkey

    @Test func discoverDecodesPasskeyWithConnection() async {
        let sut = makeClient()
        let data = successData(alternatives: [passkeyAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                guard case .passkey(let conn) = result.options.first else {
                    Issue.record("Expected .passkey"); return
                }
                #expect(conn == "my-db")
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test func discoverPopulatesPasskeyConnections() async {
        let sut = makeClient()
        let data = successData(alternatives: [passkeyAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                #expect(result.passkeyConnections == ["my-db"])
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - passwordless OTP

    @Test func discoverDecodesLegacyOtpWithEmailIdentifier() async {
        let sut = makeClient()
        let data = successData(alternatives: [passwordlessOtpLegacyAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                guard case .passwordlessOtp(let conn, let ids, let flowType) = result.options.first else {
                    Issue.record("Expected .passwordlessOtp"); return
                }
                #expect(conn == "email")
                #expect(ids == [.email])
                #expect(flowType == .legacy)
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test func discoverDecodesAuth0OtpWithBothIdentifiers() async {
        let sut = makeClient()
        let data = successData(alternatives: [passwordlessOtpAuth0Alt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                guard case .passwordlessOtp(let conn, let ids, let flowType) = result.options.first else {
                    Issue.record("Expected .passwordlessOtp"); return
                }
                #expect(conn == "my-db")
                #expect(ids.contains(.email))
                #expect(ids.contains(.phoneNumber))
                #expect(flowType == .auth0)
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test func discoverPopulatesOtpOptions() async {
        let sut = makeClient()
        let data = successData(alternatives: [passwordlessOtpLegacyAlt, passwordlessOtpAuth0Alt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                #expect(result.passwordlessOTPOptions.count == 2)
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - password-realm

    @Test func discoverDecodesPasswordRealmWithRealm() async {
        let sut = makeClient()
        let data = successData(alternatives: [passwordRealmAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                guard case .passwordRealm(let realm) = result.options.first else {
                    Issue.record("Expected .passwordRealm"); return
                }
                #expect(realm == "Username-Password-Authentication")
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test func discoverPopulatesPasswordRealms() async {
        let sut = makeClient()
        let data = successData(alternatives: [passwordRealmAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                #expect(result.passwordRealms == ["Username-Password-Authentication"])
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - Unknown grant type

    @Test func discoverDecodesUnknownGrantTypeWithoutThrowing() async {
        let sut = makeClient()
        let data = successData(alternatives: [unknownAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                guard case .unknown(let raw, let conn) = result.options.first else {
                    Issue.record("Expected .unknown"); return
                }
                #expect(raw == "urn:custom:grant-type:future")
                #expect(conn == "some-conn")
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test func discoverReportsUnknownGrantType() async {
        let sut = makeClient()
        let data = successData(alternatives: [unknownAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                #expect(result.supports(.unknown))
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - All alternatives

    @Test func discoverDecodesAllSevenAlternatives() async {
        let sut = makeClient()
        let data = successData(alternatives: [
            authorizationCodeAlt,
            tokenExchangeGoogleAlt,
            passwordAlt,
            passkeyAlt,
            passwordlessOtpLegacyAlt,
            passwordlessOtpAuth0Alt,
            passwordRealmAlt
        ])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                #expect(result.options.count == 7)
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test func discoverPreservesAlternativeOrder() async {
        let sut = makeClient()
        let data = successData(alternatives: [passwordAlt, passkeyAlt, passwordRealmAlt])
        do {
            try await confirmation(expectedCount: 1) { confirm in
                EmbeddedAuthMockURLProtocol.requestHandler = { _ in confirm(); return (self.successResponse(), data) }
                let result = try await sut.discover().start()
                guard case .password = result.options[0] else { Issue.record("Expected .password at index 0"); return }
                guard case .passkey = result.options[1] else { Issue.record("Expected .passkey at index 1"); return }
                guard case .passwordRealm = result.options[2] else { Issue.record("Expected .passwordRealm at index 2"); return }
            }
        } catch {
            Issue.record(error)
        }
    }

    // MARK: - Query parameters

    @Test func discoverSendsClientIdQueryParam() async {
        let sut = makeClient()
        var capturedURL: URL?
        EmbeddedAuthMockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            return (self.successResponse(), self.successData(alternatives: []))
        }
        do {
            _ = try await sut.discover().start()
        } catch {
            Issue.record(error)
        }
        let items = URLComponents(url: capturedURL!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "client_id", value: clientId)))
    }

    @Test func discoverSendsConnectionQueryParamWhenProvided() async {
        let sut = makeClient()
        var capturedURL: URL?
        EmbeddedAuthMockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            return (self.successResponse(), self.successData(alternatives: []))
        }
        do {
            _ = try await sut.discover(connection: "my-db").start()
        } catch {
            Issue.record(error)
        }
        let items = URLComponents(url: capturedURL!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "connection", value: "my-db")))
    }

    @Test func discoverOmitsConnectionQueryParamWhenNil() async {
        let sut = makeClient()
        var capturedURL: URL?
        EmbeddedAuthMockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            return (self.successResponse(), self.successData(alternatives: []))
        }
        do {
            _ = try await sut.discover(connection: nil).start()
        } catch {
            Issue.record(error)
        }
        let items = URLComponents(url: capturedURL!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(!items.contains(where: { $0.name == "connection" }))
    }

    // MARK: - Error paths

    @Test func discoverReturnsInvalidRequestOn400() async {
        let sut = makeClient()
        EmbeddedAuthMockURLProtocol.requestHandler = { _ in
            return (self.errorResponse(statusCode: 400),
                    self.errorData(["error": "invalid_request", "error_description": "embedded_discovery is disabled"]))
        }
        do {
            _ = try await sut.discover().start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.isInvalidRequest)
            #expect(error.statusCode == 400)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test func discoverReturnsInvalidClientOn401() async {
        let sut = makeClient()
        EmbeddedAuthMockURLProtocol.requestHandler = { _ in
            return (self.errorResponse(statusCode: 401),
                    self.errorData(["error": "invalid_client", "error_description": "Unknown client_id"]))
        }
        do {
            _ = try await sut.discover().start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.isInvalidClient)
            #expect(error.statusCode == 401)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test func discoverReturnsServerErrorOn500() async {
        let sut = makeClient()
        EmbeddedAuthMockURLProtocol.requestHandler = { _ in
            return (self.errorResponse(statusCode: 500),
                    self.errorData(["error": "server_error", "error_description": "Unexpected error"]))
        }
        do {
            _ = try await sut.discover().start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "server_error")
            #expect(error.statusCode == 500)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test func discoverReturnsFeatureDisabledOnBare404() async {
        let sut = makeClient()
        EmbeddedAuthMockURLProtocol.requestHandler = { _ in
            return (self.errorResponse(statusCode: 404), nil)
        }
        do {
            _ = try await sut.discover().start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.isFeatureDisabled)
            #expect(error.statusCode == 404)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
