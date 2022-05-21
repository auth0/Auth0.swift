import Foundation
import Quick
import Nimble

@testable import Auth0

class ClearSessionTransactionSpec: QuickSpec {

    override func spec() {
        var transaction: ClearSessionTransaction!

        beforeEach {
            transaction = ClearSessionTransaction(userAgent: SpyUserAgent())
        }

        describe("code exchange") {
            it("should resume current transaction") {
                let url = URL(string: "https://samples.auth0.com/callback")!
                expect(transaction.resume(url)) == true
                expect(transaction).to(haveClearedUserAgent())
            }

            it("should cancel current transaction") {
                transaction.cancel()
                expect(transaction).to(haveClearedUserAgent())
            }
        }
    }

}
