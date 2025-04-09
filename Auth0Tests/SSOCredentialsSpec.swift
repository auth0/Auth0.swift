import Foundation
import Quick
import Nimble

@testable import Auth0

private let SessionTransferToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let IssuedTokenType = "urn:auth0:params:oauth:token-type:session_transfer_token"
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let ExpiresIn: TimeInterval = 3600
private let ExpiresInDate = Date(timeIntervalSinceNow: ExpiresIn)

class SSOCredentialsSpec: QuickSpec {
    override class func spec() {

        describe("decode from json") {

            var decoder: JSONDecoder!

            beforeEach {
                decoder = JSONDecoder()
            }

            it("should have all properties") {
                let json = """
                    {
                        "access_token": "\(SessionTransferToken)",
                        "issued_token_type": "\(IssuedTokenType)",
                        "expires_in": "\(ExpiresIn)",
                        "id_token": "\(IdToken)",
                        "refresh_token": "\(RefreshToken)"
                    }
                """.data(using: .utf8)!
                let ssoCredentials = try decoder.decode(SSOCredentials.self, from: json)

                expect(ssoCredentials.sessionTransferToken) == SessionTransferToken
                expect(ssoCredentials.issuedTokenType) == IssuedTokenType
                expect(ssoCredentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                expect(ssoCredentials.refreshToken) == RefreshToken
            }

            it("should have only the non-optional properties") {
                let json = """
                    {
                        "access_token": "\(SessionTransferToken)",
                        "issued_token_type": "\(IssuedTokenType)",
                        "expires_in": "\(ExpiresIn)",
                        "id_token": "\(IdToken)"
                    }
                """.data(using: .utf8)!
                let ssoCredentials = try decoder.decode(SSOCredentials.self, from: json)

                expect(ssoCredentials.sessionTransferToken) == SessionTransferToken
                expect(ssoCredentials.issuedTokenType) == IssuedTokenType
                expect(ssoCredentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                expect(ssoCredentials.refreshToken).to(beNil())
            }

            context("expires_in") {

                it("should have valid expiresIn from string") {
                    let json = """
                        {
                            "access_token": "\(SessionTransferToken)",
                            "issued_token_type": "\(IssuedTokenType)",
                            "expires_in": "\(ExpiresIn)",
                            "id_token": "\(IdToken)"
                        }
                    """.data(using: .utf8)!
                    let ssoCredentials = try decoder.decode(SSOCredentials.self, from: json)

                    expect(ssoCredentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                }

                it("should have valid expiresIn from integer number") {
                    let json = """
                        {
                            "access_token": "\(SessionTransferToken)",
                            "issued_token_type": "\(IssuedTokenType)",
                            "expires_in": \(Int(ExpiresIn)),
                            "id_token": "\(IdToken)"
                        }
                    """.data(using: .utf8)!
                    let ssoCredentials = try decoder.decode(SSOCredentials.self, from: json)

                    expect(ssoCredentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                }

                it("should have valid expiresIn from floating point number") {
                    let json = """
                        {
                            "access_token": "\(SessionTransferToken)",
                            "issued_token_type": "\(IssuedTokenType)",
                            "expires_in": \(ExpiresIn),
                            "id_token": "\(IdToken)"
                        }
                    """.data(using: .utf8)!
                    let ssoCredentials = try decoder.decode(SSOCredentials.self, from: json)

                    expect(ssoCredentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                }

                it("should have valid expiresIn from ISO date") {
                    let formatter = ISO8601DateFormatter()
                    let json = """
                        {
                            "access_token": "\(SessionTransferToken)",
                            "issued_token_type": "\(IssuedTokenType)",
                            "expires_in": "\(formatter.string(from: ExpiresInDate))",
                            "id_token": "\(IdToken)"
                        }
                    """.data(using: .utf8)!
                    decoder.dateDecodingStrategy = .iso8601
                    let ssoCredentials = try decoder.decode(SSOCredentials.self, from: json)

                    expect(ssoCredentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                }

                it("should fail when expiresIn is invalid") {
                    let json = """
                        {
                            "access_token": "\(SessionTransferToken)",
                            "issued_token_type": "\(IssuedTokenType)",
                            "expires_in": "INVALID",
                            "id_token": "\(IdToken)"
                        }
                    """.data(using: .utf8)!
                    let context = DecodingError.Context(codingPath: [SSOCredentials.CodingKeys.expiresIn],
                                                        debugDescription: "Format of expires_in is not recognized.")
                    let expectedError = DecodingError.dataCorrupted(context)

                    expect({ try decoder.decode(SSOCredentials.self, from: json) }).to(throwError(expectedError))
                }

            }

        }

        describe("description") {

            it("should have all unredacted properties") {
                let ssoCredentials = SSOCredentials(sessionTransferToken: SessionTransferToken,
                                                    issuedTokenType: IssuedTokenType,
                                                    expiresIn: ExpiresInDate,
                                                    idToken: IdToken,
                                                    refreshToken: RefreshToken)
                let description = "SSOCredentials(sessionTransferToken: \"<REDACTED>\", issuedTokenType:"
                + " \"\(IssuedTokenType)\", expiresIn: \(ExpiresInDate), idToken: \"<REDACTED>\", refreshToken:"
                + " Optional(\"<REDACTED>\"))"

                expect(ssoCredentials.description) == description
                expect(ssoCredentials.description).toNot(contain(SessionTransferToken))
                expect(ssoCredentials.description).toNot(contain(RefreshToken))
            }

            it("should have only the non-optional unredacted properties") {
                let ssoCredentials = SSOCredentials(sessionTransferToken: SessionTransferToken,
                                                    issuedTokenType: IssuedTokenType,
                                                    expiresIn: ExpiresInDate,
                                                    idToken: IdToken)
                let description = "SSOCredentials(sessionTransferToken: \"<REDACTED>\", issuedTokenType:"
                + " \"\(IssuedTokenType)\", expiresIn: \(ExpiresInDate), idToken: \"<REDACTED>\", refreshToken: nil)"

                expect(ssoCredentials.description) == description
                expect(ssoCredentials.description).toNot(contain(SessionTransferToken))
            }

        }

    }
}
