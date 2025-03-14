import Foundation
import Quick
import Nimble

@testable import Auth0

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let Bearer = "bearer"
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let ExpiresIn: TimeInterval = Date(timeIntervalSinceNow: 3500).timeIntervalSince1970
private let ExpiresInDate = Date(timeIntervalSince1970: ExpiresIn)
private let Scope = "openid"

class APICredentialsSpec: QuickSpec {
    override class func spec() {

        describe("decode from json") {

            it("should have all properties") {
                let json = """
                    {
                        "access_token": "\(AccessToken)",
                        "token_type": "\(Bearer)",
                        "expires_in": \(ExpiresIn),
                        "scope": "\(Scope)"
                    }
                """.data(using: .utf8)!
                let credentials = try APICredentials(from: json)
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.expiresIn) == ExpiresInDate
                expect(credentials.scope) == Scope
            }

            it("should have only the non-optional properties") {
                let json = """
                    {
                        "access_token": "\(AccessToken)",
                        "token_type": "\(Bearer)",
                        "expires_in": \(ExpiresIn)
                    }
                """.data(using: .utf8)!
                let credentials = try APICredentials(from: json)
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.expiresIn) == ExpiresInDate
                expect(credentials.scope).to(beNil())
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
