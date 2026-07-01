import Foundation
import Quick
import Nimble

@testable import Auth0

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let TokenType = "bearer"
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let ExpiresIn: TimeInterval = 3600
private let ExpiresInDate = Date(timeIntervalSinceNow: ExpiresIn)
private let Scope = "openid"

class CredentialsSpec: QuickSpec {
    override class func spec() {

        describe("decode from json") {

            var decoder: JSONDecoder!

            beforeEach {
                decoder = JSONDecoder()
            }

            it("should have all properties") {
                let json = """
                    {
                        "access_token": "\(AccessToken)",
                        "token_type": "\(TokenType)",
                        "id_token": "\(IdToken)",
                        "refresh_token": "\(RefreshToken)",
                        "expires_in": "\(ExpiresIn)",
                        "scope": "\(Scope)",
                        "recovery_code": "\(RecoveryCode)"
                    }
                """.data(using: .utf8)!
                let credentials = try decoder.decode(Credentials.self, from: json)
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == TokenType
                expect(credentials.idToken) == IdToken
                expect(credentials.refreshToken) == RefreshToken
                expect(credentials.expiresAt).to(beCloseTo(ExpiresInDate, within: 5))
                expect(credentials.scope) == Scope
                expect(credentials.recoveryCode) == RecoveryCode
            }

            it("should have only the non-optional properties") {
                let json = """
                    {
                        "access_token": "\(AccessToken)",
                        "token_type": "\(TokenType)",
                        "id_token": "\(IdToken)",
                        "expires_in": "\(ExpiresIn)"
                    }
                """.data(using: .utf8)!
                let credentials = try decoder.decode(Credentials.self, from: json)
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == TokenType
                expect(credentials.idToken) == IdToken
                expect(credentials.refreshToken).to(beNil())
                expect(credentials.expiresAt).to(beCloseTo(ExpiresInDate, within: 5))
                expect(credentials.scope).to(beNil())
                expect(credentials.recoveryCode).to(beNil())
            }

            it("should have only the default values") {
                let json = "{}".data(using: .utf8)!
                let credentials = try decoder.decode(Credentials.self, from: json)
                expect(credentials.accessToken) == ""
                expect(credentials.tokenType) == ""
                expect(credentials.idToken) == ""
                expect(credentials.refreshToken).to(beNil())
                expect(credentials.expiresAt).to(beCloseTo(Date(), within: 5))
                expect(credentials.scope).to(beNil())
                expect(credentials.recoveryCode).to(beNil())
            }

            context("expires_in") {

                it("should have valid expiresAt from string") {
                    let json = """
                        {
                            "expires_in": "\(ExpiresIn)"
                        }
                    """.data(using: .utf8)!
                    let credentials = try decoder.decode(Credentials.self, from: json)
                    expect(credentials.expiresAt).to(beCloseTo(ExpiresInDate, within: 5))
                }

                it("should have valid expiresAt from integer number") {
                    let json = """
                        {
                            "expires_in": \(Int(ExpiresIn))
                        }
                    """.data(using: .utf8)!
                    let credentials = try decoder.decode(Credentials.self, from: json)
                    expect(credentials.expiresAt).to(beCloseTo(ExpiresInDate, within: 5))
                }

                it("should have valid expiresAt from floating point number") {
                    let json = """
                        {
                            "expires_in": \(ExpiresIn)
                        }
                    """.data(using: .utf8)!
                    let credentials = try decoder.decode(Credentials.self, from: json)
                    expect(credentials.expiresAt).to(beCloseTo(ExpiresInDate, within: 5))
                }

                it("should have valid expiresAt from ISO date") {
                    let formatter = ISO8601DateFormatter()
                    let json = """
                            {
                                "expires_in": "\(formatter.string(from: ExpiresInDate))"
                            }
                        """.data(using: .utf8)!
                    decoder.dateDecodingStrategy = .iso8601
                    let credentials = try decoder.decode(Credentials.self, from: json)
                    expect(credentials.expiresAt).to(beCloseTo(ExpiresInDate, within: 5))
                }

            }

        }

        describe("secure coding") {

            it("should unarchive as credentials type") {
                let original = Credentials(accessToken: AccessToken,
                                           tokenType: TokenType,
                                           idToken: IdToken,
                                           refreshToken: RefreshToken,
                                           expiresAt: ExpiresInDate,
                                           scope: Scope,
                                           recoveryCode: RecoveryCode)
                let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
                let credentials = try NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data)!
                expect(credentials).toNot(beNil())
            }

            it("should have all properties") {
                let original = Credentials(accessToken: AccessToken,
                                           tokenType: TokenType,
                                           idToken: IdToken,
                                           refreshToken: RefreshToken,
                                           expiresAt: ExpiresInDate,
                                           scope: Scope,
                                           recoveryCode: RecoveryCode)
                let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
                let credentials = try NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data)!
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == TokenType
                expect(credentials.idToken) == IdToken
                expect(credentials.expiresAt).to(beCloseTo(ExpiresInDate, within: 5))
                expect(credentials.scope) == Scope
                expect(credentials.recoveryCode) == RecoveryCode
            }

            it("should have only the non-optional properties") {
                let original = Credentials(accessToken: AccessToken,
                                           tokenType: TokenType,
                                           idToken: IdToken,
                                           expiresAt: ExpiresInDate)
                let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
                let credentials = try NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data)!
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == TokenType
                expect(credentials.idToken) == IdToken
                expect(credentials.refreshToken).to(beNil())
                expect(credentials.expiresAt).to(beCloseTo(ExpiresInDate, within: 5))
                expect(credentials.scope).to(beNil())
                expect(credentials.recoveryCode).to(beNil())
            }

            it("should have only the default values") {
                let original = Credentials()
                let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
                let credentials = try NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data)!
                expect(credentials.accessToken) == ""
                expect(credentials.tokenType) == ""
                expect(credentials.idToken) == ""
                expect(credentials.refreshToken).to(beNil())
                expect(credentials.expiresAt).to(beCloseTo(Date(), within: 5))
                expect(credentials.scope).to(beNil())
                expect(credentials.recoveryCode).to(beNil())
            }

        }

        describe("description") {

            it("should have all unredacted properties") {
                let credentials = Credentials(accessToken: AccessToken,
                                              tokenType: TokenType,
                                              idToken: IdToken,
                                              refreshToken: RefreshToken,
                                              expiresAt: ExpiresInDate,
                                              scope: Scope,
                                              recoveryCode: RecoveryCode)
                let description = "Credentials(accessToken: \"<REDACTED>\", tokenType: \"\(TokenType)\", idToken:"
                    + " \"<REDACTED>\", refreshToken: Optional(\"<REDACTED>\"), expiresAt: \(ExpiresInDate), scope:"
                    + " Optional(\"\(Scope)\"), recoveryCode: Optional(\"<REDACTED>\"))"
                expect(credentials.description) == description
                expect(credentials.description).toNot(contain(AccessToken))
                expect(credentials.description).toNot(contain(IdToken))
                expect(credentials.description).toNot(contain(RefreshToken))
                expect(credentials.description).toNot(contain(RecoveryCode))
            }

            it("should have only the non-optional unredacted properties") {
                let credentials = Credentials(accessToken: AccessToken,
                                              tokenType: TokenType,
                                              idToken: IdToken,
                                              expiresAt: ExpiresInDate)
                let description = "Credentials(accessToken: \"<REDACTED>\", tokenType: \"\(TokenType)\", idToken:"
                    + " \"<REDACTED>\", refreshToken: nil, expiresAt: \(ExpiresInDate), scope: nil, recoveryCode: nil)"
                expect(credentials.description) == description
                expect(credentials.description).toNot(contain(AccessToken))
                expect(credentials.description).toNot(contain(IdToken))
            }

        }

        describe("session expiry") {

            it("should read session_expiry from the id token") {
                let sessionExpiry = 1_700_000_000
                let credentials = Credentials(idToken: idTokenWithSessionExpiry(sessionExpiry))
                expect(credentials.sessionExpiresAt) == Date(timeIntervalSince1970: TimeInterval(sessionExpiry))
            }

            it("should be nil when the claim is absent") {
                let credentials = Credentials(idToken: idTokenWithSessionExpiry(nil))
                expect(credentials.sessionExpiresAt).to(beNil())
            }

            it("should be nil when the id token is not a valid jwt") {
                let credentials = Credentials(idToken: "not-a-jwt")
                expect(credentials.sessionExpiresAt).to(beNil())
            }

            it("should be nil when the value is implausibly large (milliseconds)") {
                let credentials = Credentials(idToken: idTokenWithSessionExpiry(1_700_000_000_000))
                expect(credentials.sessionExpiresAt).to(beNil())
            }

        }

    }
}

/// Builds an unsigned JWT containing (or omitting) a `session_expiry` claim. JWTDecode does not
/// validate signatures, so the signature can be arbitrary for unit tests.
private func idTokenWithSessionExpiry(_ sessionExpiry: Int?) -> String {
    var payload: [String: Any] = ["iss": "test", "sub": "sub|123", "aud": "audience"]
    if let sessionExpiry = sessionExpiry {
        payload["session_expiry"] = sessionExpiry
    }
    let headerJSON = try! JSONSerialization.data(withJSONObject: ["typ": "JWT", "alg": "HS256"])
    let payloadJSON = try! JSONSerialization.data(withJSONObject: payload)
    func encode(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    return "\(encode(headerJSON)).\(encode(payloadJSON)).fakesig"
}
