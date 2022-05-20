import Quick
import Nimble

@testable import Auth0

class LoginTransactionSpec: QuickSpec {

    override func spec() {
        var transaction: LoginTransaction!
        var result: WebAuthResult<Credentials>? = nil
        let callback: (WebAuthResult<Credentials>) -> () = { result = $0 }
        let code = "123456"

        beforeEach {
            transaction = LoginTransaction(redirectURL: URL(string: "https://samples.auth0.com/callback")!,
                                           state: "state",
                                           userAgent: MockUserAgent(),
                                           handler: MockGrant(),
                                           logger: nil,
                                           callback: callback)
            result = nil
        }

        describe("code exchange") {
            context("resume") {
                it("should handle url") {
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)&state=state")!
                    expect(transaction.resume(url)) == true
                    expect(result).toEventually(haveCredentials())
                    expect(transaction.userAgent).to(beNil())
                    expect(transaction.userAgentCallback).to(beNil())
                }

                it("should handle url with error") {
                    let url = URL(string: "https://samples.auth0.com/callback?error=error&error_description=description&state=state")!
                    expect(transaction.resume(url)) == true
                    expect(transaction.userAgent).to(beNil())
                    expect(transaction.userAgentCallback).to(beNil())
                }

                it("should fail to handle url without state") {
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)")!
                    expect(transaction.resume(url)) == false
                    expect(transaction.userAgent).to(beNil())
                    expect(transaction.userAgentCallback).to(beNil())
                }

                it("should fail to handle invalid url") {
                    let url = URL(string: "foo")!
                    expect(transaction.resume(url)) == false
                    expect(transaction.userAgent).to(beNil())
                    expect(transaction.userAgentCallback).to(beNil())
                }
            }

            context("cancel") {
                it("should cancel current transaction") {
                    transaction.cancel()
                    expect(transaction.userAgent).to(beNil())
                    expect(transaction.userAgentCallback).to(beNil())
                }
            }
        }
    }

}
