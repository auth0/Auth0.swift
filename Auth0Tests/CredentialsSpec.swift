import Foundation
import Quick
import Nimble

@testable import Auth0

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let Bearer = "bearer"
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let ExpiresIn: TimeInterval = 3600
private let Scope = "openid"

class CredentialsSpec: QuickSpec {
    override func spec() {

        describe("decode from json") {
            let decoder = JSONDecoder()

            it("should have all properties") {
                let json = """
                    {
                        "access_token": "\(AccessToken)",
                        "token_type": "\(Bearer)",
                        "id_token": "\(IdToken)",
                        "refresh_token": "\(RefreshToken)",
                        "expires_in": "\(ExpiresIn)",
                        "scope": "\(Scope)",
                        "recovery_code": "\(RecoveryCode)"
                    }
                """.data(using: .utf8)!
                let credentials = try decoder.decode(Credentials.self, from: json)
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.idToken) == IdToken
                expect(credentials.refreshToken) == RefreshToken
                expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: ExpiresIn), within: 5))
                expect(credentials.scope) == Scope
                expect(credentials.recoveryCode) == RecoveryCode
            }

            it("should have only the non-optional properties") {
                let json = """
                    {
                        "access_token": "\(AccessToken)",
                        "token_type": "\(Bearer)",
                        "id_token": "\(IdToken)",
                        "expires_in": "\(ExpiresIn)"
                    }
                """.data(using: .utf8)!
                let credentials = try decoder.decode(Credentials.self, from: json)
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.idToken) == IdToken
                expect(credentials.refreshToken).to(beNil())
                expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: ExpiresIn), within: 5))
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
                expect(credentials.expiresIn).to(beCloseTo(Date(), within: 5))
                expect(credentials.scope).to(beNil())
                expect(credentials.recoveryCode).to(beNil())
            }

            context("expires_in") {

                it("should have valid expiresIn from string") {
                    let json = """
                        {
                            "expires_in": "\(ExpiresIn)"
                        }
                    """.data(using: .utf8)!
                    let credentials = try decoder.decode(Credentials.self, from: json)
                    expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: ExpiresIn), within: 5))
                }

                it("should have valid expiresIn from integer number") {
                    let json = """
                        {
                            "expires_in": \(Int(ExpiresIn))
                        }
                    """.data(using: .utf8)!
                    let credentials = try decoder.decode(Credentials.self, from: json)
                    expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: ExpiresIn), within: 5))
                }

                it("should have valid expiresIn from floating point number") {
                    let json = """
                        {
                            "expires_in": \(Int(ExpiresIn)).0
                        }
                    """.data(using: .utf8)!
                    let credentials = try decoder.decode(Credentials.self, from: json)
                    expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: ExpiresIn), within: 5))
                }

            }
        }

        describe("archival") {

            it("should have all properties") {
                let original = Credentials(accessToken: AccessToken,
                                           tokenType: Bearer,
                                           idToken: IdToken,
                                           refreshToken: RefreshToken,
                                           expiresIn: Date(timeIntervalSinceNow: ExpiresIn),
                                           scope: Scope,
                                           recoveryCode: RecoveryCode)
                let data = try original.archive()
                let credentials = try Credentials.unarchive(from: data)
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.idToken) == IdToken
                expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: ExpiresIn), within: 5))
                expect(credentials.scope) == Scope
                expect(credentials.recoveryCode) == RecoveryCode
            }

            it("should have only the non-optional properties") {
                let original = Credentials(accessToken: AccessToken,
                                           tokenType: Bearer,
                                           idToken: IdToken,
                                           expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                let data = try original.archive()
                let credentials = try Credentials.unarchive(from: data)
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.idToken) == IdToken
                expect(credentials.refreshToken).to(beNil())
                expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: ExpiresIn), within: 5))
                expect(credentials.scope).to(beNil())
                expect(credentials.recoveryCode).to(beNil())
            }

            it("should have only the default values") {
                let original = Credentials()
                let data = try original.archive()
                let credentials = try Credentials.unarchive(from: data)
                expect(credentials.accessToken) == ""
                expect(credentials.tokenType) == ""
                expect(credentials.idToken) == ""
                expect(credentials.refreshToken).to(beNil())
                expect(credentials.expiresIn).to(beCloseTo(Date(), within: 5))
                expect(credentials.scope).to(beNil())
                expect(credentials.recoveryCode).to(beNil())
            }

        }
    }
}
