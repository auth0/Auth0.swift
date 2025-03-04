import Foundation
import Quick
import Nimble

@testable import Auth0

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let Bearer = "bearer"
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let ExpiresIn: TimeInterval = 3600
private let ExpiresInDate = Date(timeIntervalSinceNow: ExpiresIn)
private let Scope = "openid"

class APICredentialsSpec: QuickSpec {
    override class func spec() {

        describe("decode from json") {

            let decoder = JSONDecoder()

            it("should have all properties") {
                let json = """
                    {
                        "access_token": "\(AccessToken)",
                        "token_type": "\(Bearer)",
                        "expires_in": "\(ExpiresIn)",
                        "scope": "\(Scope)"
                    }
                """.data(using: .utf8)!
                let credentials = try decoder.decode(APICredentials.self, from: json)
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                expect(credentials.scope) == Scope
            }

            it("should have only the non-optional properties") {
                let json = """
                    {
                        "access_token": "\(AccessToken)",
                        "token_type": "\(Bearer)",
                        "expires_in": "\(ExpiresIn)"
                    }
                """.data(using: .utf8)!
                let credentials = try decoder.decode(APICredentials.self, from: json)
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                expect(credentials.scope).to(beNil())
            }

            context("expires_in") {

                it("should have valid expiresIn from string") {
                    let json = """
                        {
                            "access_token": "\(AccessToken)",
                            "token_type": "\(Bearer)",
                            "expires_in": "\(ExpiresIn)"
                        }
                    """.data(using: .utf8)!
                    let credentials = try decoder.decode(APICredentials.self, from: json)
                    expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                }

                it("should have valid expiresIn from integer number") {
                    let json = """
                        {
                            "access_token": "\(AccessToken)",
                            "token_type": "\(Bearer)",
                            "expires_in": \(Int(ExpiresIn))
                        }
                    """.data(using: .utf8)!
                    let credentials = try decoder.decode(APICredentials.self, from: json)
                    expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                }

                it("should have valid expiresIn from floating point number") {
                    let json = """
                        {
                            "access_token": "\(AccessToken)",
                            "token_type": "\(Bearer)",
                            "expires_in": \(ExpiresIn)
                        }
                    """.data(using: .utf8)!
                    let credentials = try decoder.decode(APICredentials.self, from: json)
                    expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                }

                it("should have valid expiresIn from ISO date") {
                    let formatter = ISO8601DateFormatter()
                    let json = """
                            {
                                "access_token": "\(AccessToken)",
                                "token_type": "\(Bearer)",
                                "expires_in": "\(formatter.string(from: ExpiresInDate))"
                            }
                        """.data(using: .utf8)!
                    decoder.dateDecodingStrategy = .iso8601
                    let credentials = try decoder.decode(APICredentials.self, from: json)
                    expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                }

            }

        }

        describe("description") {

            it("should have all unredacted properties") {
                let credentials = APICredentials(accessToken: AccessToken,
                                                 tokenType: Bearer,
                                                 expiresIn: ExpiresInDate,
                                                 scope: Scope)
                let description = "APICredentials(accessToken: \"<REDACTED>\", tokenType: \"\(Bearer)\", expiresIn:"
                    + " \(ExpiresInDate), scope: Optional(\"\(Scope)\"))"
                expect(credentials.description) == description
                expect(credentials.description).toNot(contain(AccessToken))
            }

            it("should have only the non-optional unredacted properties") {
                let credentials = APICredentials(accessToken: AccessToken, tokenType: Bearer, expiresIn: ExpiresInDate)
                let description = "APICredentials(accessToken: \"<REDACTED>\", tokenType: \"\(Bearer)\", expiresIn:"
                    + " \(ExpiresInDate), scope: nil)"
                expect(credentials.description) == description
                expect(credentials.description).toNot(contain(AccessToken))
            }

        }

    }
}
