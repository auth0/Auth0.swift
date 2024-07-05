import Foundation
import Quick
import Nimble

@testable import Auth0

class WebAuthenticationSpec: QuickSpec {

    override class func spec() {

        let storage = TransactionStore.shared
        var transaction: SpyTransaction!

        beforeEach {
            transaction = SpyTransaction()
            storage.clear()
            storage.store(transaction)
        }

        describe("current transaction") {

            let url = URL(string: "https://auth0.com")!

            it("should resume current transaction") {
                transaction.isResumed = true
                expect(WebAuthentication.resume(with: url)) == true
            }

            it("should cancel current transaction") {
                WebAuthentication.cancel()
                expect(transaction.isCancelled) == true
            }

        }

    }

}
