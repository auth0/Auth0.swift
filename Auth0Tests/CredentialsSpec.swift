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
                expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
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
                expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
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
                    expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                }

                it("should have valid expiresIn from integer number") {
                    let json = """
                        {
                            "expires_in": \(Int(ExpiresIn))
                        }
                    """.data(using: .utf8)!
                    let credentials = try decoder.decode(Credentials.self, from: json)
                    expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                }

                it("should have valid expiresIn from floating point number") {
                    let json = """
                        {
                            "expires_in": \(ExpiresIn)
                        }
                    """.data(using: .utf8)!
                    let credentials = try decoder.decode(Credentials.self, from: json)
                    expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                }

            }
        }

        describe("secure coding") {

            it("should unarchive as credentials type") {
                let original = Credentials(accessToken: AccessToken,
                                           tokenType: Bearer,
                                           idToken: IdToken,
                                           refreshToken: RefreshToken,
                                           expiresIn: ExpiresInDate,
                                           scope: Scope,
                                           recoveryCode: RecoveryCode)
                let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
                let credentials = try NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data)!
                expect(credentials).toNot(beNil())
            }

            it("should have all properties") {
                let original = Credentials(accessToken: AccessToken,
                                           tokenType: Bearer,
                                           idToken: IdToken,
                                           refreshToken: RefreshToken,
                                           expiresIn: ExpiresInDate,
                                           scope: Scope,
                                           recoveryCode: RecoveryCode)
                let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
                let credentials = try NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data)!
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.idToken) == IdToken
                expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
                expect(credentials.scope) == Scope
                expect(credentials.recoveryCode) == RecoveryCode
            }

            it("should have only the non-optional properties") {
                let original = Credentials(accessToken: AccessToken,
                                           tokenType: Bearer,
                                           idToken: IdToken,
                                           expiresIn: ExpiresInDate)
                let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
                let credentials = try NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data)!
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.idToken) == IdToken
                expect(credentials.refreshToken).to(beNil())
                expect(credentials.expiresIn).to(beCloseTo(ExpiresInDate, within: 5))
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
                expect(credentials.expiresIn).to(beCloseTo(Date(), within: 5))
                expect(credentials.scope).to(beNil())
                expect(credentials.recoveryCode).to(beNil())
            }

        }

        describe("description") {

            it("should have all unredacted properties") {
                let credentials = Credentials(accessToken: AccessToken,
                                              tokenType: Bearer,
                                              idToken: IdToken,
                                              refreshToken: RefreshToken,
                                              expiresIn: ExpiresInDate,
                                              scope: Scope,
                                              recoveryCode: RecoveryCode)
                let description = "Credentials(accessToken: \"<REDACTED>\", tokenType: \"\(Bearer)\", idToken:"
                    + " \"<REDACTED>\", refreshToken: Optional(\"<REDACTED>\"), expiresIn: \(ExpiresInDate), scope:"
                    + " Optional(\"\(Scope)\"), recoveryCode: Optional(\"<REDACTED>\"))"
                expect(credentials.description) == description
                expect(credentials.description).toNot(contain(AccessToken))
                expect(credentials.description).toNot(contain(IdToken))
                expect(credentials.description).toNot(contain(RefreshToken))
                expect(credentials.description).toNot(contain(RecoveryCode))
            }

            it("should have only the non-optional unredacted properties") {
                let credentials = Credentials(accessToken: AccessToken,
                                              tokenType: Bearer,
                                              idToken: IdToken,
                                              expiresIn: ExpiresInDate)
                let description = "Credentials(accessToken: \"<REDACTED>\", tokenType: \"\(Bearer)\", idToken:"
                    + " \"<REDACTED>\", refreshToken: nil, expiresIn: \(ExpiresInDate), scope: nil, recoveryCode: nil)"
                expect(credentials.description) == description
                expect(credentials.description).toNot(contain(AccessToken))
                expect(credentials.description).toNot(contain(IdToken))
            }

        }

    }
}
