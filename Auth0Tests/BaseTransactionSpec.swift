import Quick
import Nimble
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif

@testable import Auth0

private let ClientId = "CLIENT_ID"
private let Domain = URL(string: "https://samples.auth0.com")!
private let Issuer = "\(Domain.absoluteString)/"
private let Leeway = 60 * 1000
private let RedirectURL = URL(string: "https://samples.auth0.com/callback")!

class BaseTransactionSpec: QuickSpec {

    override func spec() {
        var transaction: BaseTransaction!
        var result: WebAuthResult<Credentials>? = nil
        let callback: (WebAuthResult<Credentials>) -> () = { result = $0 }
        let authentication = Auth0Authentication(clientId: ClientId, url: Domain)
        let generator = ChallengeGenerator()
        let handler = PKCE(authentication: authentication,
                           generator: generator,
                           redirectURL: RedirectURL,
                           issuer: Issuer,
                           leeway: Leeway,
                           nonce: nil)
        let idToken = generateJWT(iss: Issuer, aud: [ClientId]).string
        let code = "123456"

        beforeEach {
            transaction = BaseTransaction(redirectURL: RedirectURL,
                                          state: "state",
                                          handler: handler,
                                          logger: nil,
                                          callback: callback)
            result = nil
            stub(condition: isHost(Domain.host!)) { _ in catchAllResponse() }.name = "YOU SHALL NOT PASS!"
            stub(condition: isToken(Domain.host!) && hasAtLeast(["code": code,
                                                                 "code_verifier": generator.verifier,
                                                                 "grant_type": "authorization_code",
                                                                 "redirect_uri": RedirectURL.absoluteString])) {
                _ in return authResponse(accessToken: "AT", idToken: idToken)
            }
            stub(condition: isJWKSPath(Domain.host!)) { _ in jwksResponse() }
        }

        afterEach {
            HTTPStubs.removeAllStubs()
        }

        describe("code exchange") {
            context("handle url") {
                it("should handle url") {
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)&state=state")!
                    expect(transaction.resume(url)) == true
                    expect(result).toEventually(haveCredentials())
                }

                it("should handle url with error") {
                    let url = URL(string: "https://samples.auth0.com/callback?error=error&error_description=description&state=state")!
                    expect(transaction.resume(url)) == true
                    expect(result).toEventually(haveAuthenticationError(code: "error", description: "description"))
                }

                it("should fail to handle url without state") {
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)")!
                    expect(transaction.resume(url)) == false
                }

                it("should fail to handle invalid url") {
                    let url = URL(string: "foo")!
                    expect(transaction.resume(url)) == false
                }
            }
            
            context("cancel") {
                it("should cancel current session") {
                    transaction.cancel()
                    expect(result).to(beFailure())
                }
            }
        }
    }

}
