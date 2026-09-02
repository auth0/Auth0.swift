import Foundation
import Quick
import Nimble

@testable import Auth0

private let ClientId = "TEST_CLIENT_ID"
private let Domain = "test.auth0.com"
private let DomainURL = URL.httpsURL(from: Domain)
private let DiscoveryPath = "/e/discovery"

private func isDiscoveryRequest(_ request: URLRequest) -> Bool {
    return request.url?.path == DiscoveryPath && request.httpMethod == "GET"
}

private func discoverySuccessResponse(alternatives: [[String: Any]]) -> RequestResponse {
    return apiSuccessResponse(json: ["alternatives": alternatives])
}

// MARK: - All known alternative fixture payloads

private let embeddedAuthorizeAlternative: [String: Any] = [
    "grant_type": "authorization_code",
    "type": "embedded_authorize",
    "connection": "my-db"
]

private let tokenExchangeGoogleAlternative: [String: Any] = [
    "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
    "subject_token_type": "http://auth0.com/oauth/token-type/google-id-token"
]

private let tokenExchangeAppleAlternative: [String: Any] = [
    "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
    "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code"
]

private let tokenExchangeFacebookAlternative: [String: Any] = [
    "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
    "subject_token_type": "http://auth0.com/oauth/token-type/facebook-info-session-access-token"
]

private let passwordAlternative: [String: Any] = [
    "grant_type": "password"
]

private let passkeyAlternative: [String: Any] = [
    "grant_type": "urn:okta:params:oauth:grant-type:webauthn",
    "connection": "my-db"
]

private let passwordlessOtpLegacyEmailAlternative: [String: Any] = [
    "grant_type": "http://auth0.com/oauth/grant-type/passwordless/otp",
    "type": "legacy",
    "connection": "email",
    "identifier_types": ["email"]
]

private let passwordlessOtpAuth0BothAlternative: [String: Any] = [
    "grant_type": "http://auth0.com/oauth/grant-type/passwordless/otp",
    "type": "auth0",
    "connection": "my-db",
    "identifier_types": ["email", "phone_number"]
]

private let passwordRealmAlternative: [String: Any] = [
    "grant_type": "http://auth0.com/oauth/grant-type/password-realm",
    "realm": "Username-Password-Authentication"
]

private let unknownAlternative: [String: Any] = [
    "grant_type": "urn:custom:grant-type:future",
    "connection": "some-conn"
]

// MARK: - Spec

class EmbeddedAuthSpec: QuickSpec {

    override class func spec() {

        let embeddedAuth: EmbeddedAuth = Auth0EmbeddedAuth(clientId: ClientId, url: DomainURL)

        beforeEach {
            URLProtocol.registerClass(StubURLProtocol.self)
        }

        afterEach {
            NetworkStub.clearStubs()
            URLProtocol.unregisterClass(StubURLProtocol.self)
        }

        // MARK: - Factory

        describe("factory functions") {

            it("should create client with explicit clientId and domain") {
                let client = Auth0.embeddedAuth(clientId: ClientId, domain: Domain) as! Auth0EmbeddedAuth
                expect(client.clientId) == ClientId
                expect(client.url.absoluteString) == "https://\(Domain)/"
            }

            it("should use shared URLSession by default") {
                let client = Auth0.embeddedAuth(clientId: ClientId, domain: Domain) as! Auth0EmbeddedAuth
                expect(client.session).to(be(URLSession.shared))
            }

            it("should accept a custom URLSession") {
                let custom = URLSession(configuration: .ephemeral)
                let client = Auth0.embeddedAuth(clientId: ClientId, domain: Domain, session: custom) as! Auth0EmbeddedAuth
                expect(client.session).to(be(custom))
            }
        }

        // MARK: - discover() happy paths

        describe("discover()") {

            context("empty alternatives") {

                it("returns a DiscoveryResult with no options") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: []))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let discovery) = result else { return fail("Expected success") }
                            expect(discovery.options).to(beEmpty())
                            done()
                        }
                    }
                }

                it("reports no grant types") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: []))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let discovery) = result else { return fail("Expected success") }
                            expect(discovery.types).to(beEmpty())
                            done()
                        }
                    }
                }
            }

            context("authorization_code (embeddedAuthorize) alternative") {

                it("decodes an embeddedAuthorize option") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [embeddedAuthorizeAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let discovery) = result else { return fail("Expected success") }
                            guard case .embeddedAuthorize(let conn) = discovery.options.first else {
                                return fail("Expected embeddedAuthorize")
                            }
                            expect(conn) == "my-db"
                            done()
                        }
                    }
                }

                it("reports authorizationCode grant type") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [embeddedAuthorizeAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            expect(d.supports(.authorizationCode)).to(beTrue())
                            done()
                        }
                    }
                }
            }

            context("token-exchange (nativeSocial) alternatives") {

                it("decodes google nativeSocial") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [tokenExchangeGoogleAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            guard case .nativeSocial(let stt) = d.options.first else { return fail("Expected nativeSocial") }
                            expect(stt) == "http://auth0.com/oauth/token-type/google-id-token"
                            done()
                        }
                    }
                }

                it("decodes apple nativeSocial") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [tokenExchangeAppleAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            guard case .nativeSocial(let stt) = d.options.first else { return fail("Expected nativeSocial") }
                            expect(stt) == "http://auth0.com/oauth/token-type/apple-authz-code"
                            done()
                        }
                    }
                }

                it("populates socialProviders") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [
                                            tokenExchangeGoogleAlternative,
                                            tokenExchangeAppleAlternative,
                                            tokenExchangeFacebookAlternative
                                        ]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            expect(d.socialProviders).to(haveCount(3))
                            expect(d.socialProviders).to(contain("http://auth0.com/oauth/token-type/google-id-token"))
                            done()
                        }
                    }
                }
            }

            context("password alternative") {

                it("decodes password option") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [passwordAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            guard case .password = d.options.first else { return fail("Expected .password") }
                            expect(d.supports(.password)).to(beTrue())
                            done()
                        }
                    }
                }
            }

            context("passkey alternative") {

                it("decodes passkey option with connection") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [passkeyAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            guard case .passkey(let conn) = d.options.first else { return fail("Expected .passkey") }
                            expect(conn) == "my-db"
                            done()
                        }
                    }
                }

                it("populates passkeyConnections") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [passkeyAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            expect(d.passkeyConnections) == ["my-db"]
                            done()
                        }
                    }
                }
            }

            context("passwordless OTP alternatives") {

                it("decodes legacy OTP with email identifier") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [passwordlessOtpLegacyEmailAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            guard case .passwordlessOtp(let conn, let ids, let flowType) = d.options.first else {
                                return fail("Expected .passwordlessOtp")
                            }
                            expect(conn) == "email"
                            expect(ids) == [.email]
                            expect(flowType) == .legacy
                            done()
                        }
                    }
                }

                it("decodes auth0 OTP with email+phone identifiers") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [passwordlessOtpAuth0BothAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            guard case .passwordlessOtp(let conn, let ids, let flowType) = d.options.first else {
                                return fail("Expected .passwordlessOtp")
                            }
                            expect(conn) == "my-db"
                            expect(ids).to(contain(.email))
                            expect(ids).to(contain(.phoneNumber))
                            expect(flowType) == .auth0
                            done()
                        }
                    }
                }

                it("populates otpOptions") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [
                                            passwordlessOtpLegacyEmailAlternative,
                                            passwordlessOtpAuth0BothAlternative
                                        ]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            expect(d.otpOptions).to(haveCount(2))
                            done()
                        }
                    }
                }
            }

            context("password-realm alternative") {

                it("decodes passwordRealm option with realm") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [passwordRealmAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            guard case .passwordRealm(let realm) = d.options.first else { return fail("Expected .passwordRealm") }
                            expect(realm) == "Username-Password-Authentication"
                            done()
                        }
                    }
                }

                it("populates passwordRealms") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [passwordRealmAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            expect(d.passwordRealms) == ["Username-Password-Authentication"]
                            done()
                        }
                    }
                }
            }

            context("unknown grant type") {

                it("decodes an unknown grant type without throwing") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [unknownAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success, not throw") }
                            guard case .unknown(let raw, let conn) = d.options.first else { return fail("Expected .unknown") }
                            expect(raw) == "urn:custom:grant-type:future"
                            expect(conn) == "some-conn"
                            done()
                        }
                    }
                }

                it("reports .unknown grant type") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [unknownAlternative]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            expect(d.supports(.unknown)).to(beTrue())
                            done()
                        }
                    }
                }
            }

            context("all known alternatives at once") {

                it("decodes all 7 alternatives from full mock JSON") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [
                                            embeddedAuthorizeAlternative,
                                            tokenExchangeGoogleAlternative,
                                            passwordAlternative,
                                            passkeyAlternative,
                                            passwordlessOtpLegacyEmailAlternative,
                                            passwordlessOtpAuth0BothAlternative,
                                            passwordRealmAlternative
                                        ]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            expect(d.options).to(haveCount(7))
                            done()
                        }
                    }
                }

                it("preserves order of alternatives") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [
                                            passwordAlternative,
                                            passkeyAlternative,
                                            passwordRealmAlternative
                                        ]))
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success(let d) = result else { return fail("Expected success") }
                            if case .password = d.options[0] { } else { fail("Expected .password first") }
                            if case .passkey = d.options[1] { } else { fail("Expected .passkey second") }
                            if case .passwordRealm = d.options[2] { } else { fail("Expected .passwordRealm third") }
                            done()
                        }
                    }
                }
            }

            // MARK: - connection filter

            context("connection filter parameter") {

                it("sends the connection query parameter when provided") {
                    NetworkStub.addStub(
                        condition: { req in
                            guard req.url?.path == DiscoveryPath else { return false }
                            let items = URLComponents(url: req.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
                            return items.contains(URLQueryItem(name: "connection", value: "my-db"))
                        },
                        response: discoverySuccessResponse(alternatives: [passkeyAlternative])
                    )
                    waitUntil { done in
                        embeddedAuth.discover(connection: "my-db").start { result in
                            guard case .success = result else { return fail("Expected success") }
                            done()
                        }
                    }
                }

                it("sends client_id as a query parameter") {
                    NetworkStub.addStub(
                        condition: { req in
                            guard req.url?.path == DiscoveryPath else { return false }
                            let items = URLComponents(url: req.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
                            return items.contains(URLQueryItem(name: "client_id", value: ClientId))
                        },
                        response: discoverySuccessResponse(alternatives: [])
                    )
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .success = result else { return fail("Expected success") }
                            done()
                        }
                    }
                }

                it("does not send connection when nil") {
                    NetworkStub.addStub(
                        condition: { req in
                            guard req.url?.path == DiscoveryPath else { return false }
                            let items = URLComponents(url: req.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
                            return !items.contains(where: { $0.name == "connection" })
                        },
                        response: discoverySuccessResponse(alternatives: [])
                    )
                    waitUntil { done in
                        embeddedAuth.discover(connection: nil).start { result in
                            guard case .success = result else { return fail("Expected success") }
                            done()
                        }
                    }
                }
            }

            // MARK: - async

            context("async/await") {

                it("works via async start()") {
                    NetworkStub.addStub(condition: isDiscoveryRequest,
                                        response: discoverySuccessResponse(alternatives: [passwordAlternative]))
                    waitUntil { done in
                        Task { @MainActor in
                            do {
                                let d = try await embeddedAuth.discover().start()
                                expect(d.supports(.password)).to(beTrue())
                            } catch {
                                fail("Expected success, got \(error)")
                            }
                            done()
                        }
                    }
                }
            }

            // MARK: - Error paths

            context("error responses") {

                it("returns isInvalidRequest on 400") {
                    NetworkStub.addStub(
                        condition: isDiscoveryRequest,
                        response: apiFailureResponse(
                            json: ["error": "invalid_request", "error_description": "embedded_discovery is disabled"],
                            statusCode: 400
                        )
                    )
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.isInvalidRequest).to(beTrue())
                            expect(error.statusCode) == 400
                            done()
                        }
                    }
                }

                it("returns isInvalidClient on 401") {
                    NetworkStub.addStub(
                        condition: isDiscoveryRequest,
                        response: apiFailureResponse(
                            json: ["error": "invalid_client", "error_description": "Unknown client_id"],
                            statusCode: 401
                        )
                    )
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.isInvalidClient).to(beTrue())
                            expect(error.statusCode) == 401
                            done()
                        }
                    }
                }

                it("surfaces server_error on 500") {
                    NetworkStub.addStub(
                        condition: isDiscoveryRequest,
                        response: apiFailureResponse(
                            json: ["error": "server_error", "error_description": "Unexpected error"],
                            statusCode: 500
                        )
                    )
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.code) == "server_error"
                            expect(error.statusCode) == 500
                            done()
                        }
                    }
                }

                it("returns isFeatureDisabled on bare 404") {
                    NetworkStub.addStub(
                        condition: isDiscoveryRequest,
                        response: { req in
                            let response = HTTPURLResponse(url: req.url!,
                                                           statusCode: 404,
                                                           httpVersion: nil,
                                                           headerFields: [:])!
                            return (nil, response, nil)
                        }
                    )
                    waitUntil { done in
                        embeddedAuth.discover().start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.isFeatureDisabled).to(beTrue())
                            expect(error.statusCode) == 404
                            done()
                        }
                    }
                }
            }
        }
    }
}
