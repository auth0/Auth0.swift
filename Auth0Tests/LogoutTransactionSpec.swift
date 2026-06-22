import Foundation
import Quick
import Nimble

@testable import Auth0

class LogoutTransactionSpec: QuickSpec {

    override class func spec() {
        var transaction: LogoutTransaction!

        beforeEach {
            transaction = LogoutTransaction(userAgent: SpyUserAgent())
        }

        describe("code exchange") {
            it("should resume current transaction") {
                let url = URL(string: "https://samples.auth0.com/callback")!
                expect(transaction.resume(url)) == true
                expect(transaction.userAgent).to(beNil())
            }

            it("should cancel current transaction") {
                transaction.cancel()
                expect(transaction.userAgent).to(beNil())
            }
        }
    }

}
