import Quick
import Nimble

@testable import Auth0

class ClearSessionTransactionSpec: QuickSpec {

    override func spec() {
        var transaction: ClearSessionTransaction!

        beforeEach {
            transaction = ClearSessionTransaction(userAgent: MockUserAgent())
        }

        describe("code exchange") {
            context("resume") {
                it("should resume current transaction") {
                    let url = URL(string: "https://samples.auth0.com/callback")!
                    expect(transaction.resume(url)) == true
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
