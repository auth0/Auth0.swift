import Foundation
import Quick
import Nimble

@testable import Auth0

class SenderConstrainingSpec: QuickSpec {
    override class func spec() {

        var senderConstrainer: SenderConstraining!

        beforeEach {
            senderConstrainer = MockSenderConstrainer()
        }

        describe("useDPoP") {

            it("should set dpop with the default keychain identifier") {
                senderConstrainer = senderConstrainer.useDPoP()

                expect(senderConstrainer.dpop).toNot(beNil())
            }

            it("should set dpop with a custom keychain identifier") {
                senderConstrainer = senderConstrainer.useDPoP(keychainIdentifier: "custom-keychain-identifier")

                expect(senderConstrainer.dpop).toNot(beNil())
            }

        }

        describe("baseHeaders") {

            it("should generate Authorization header") {
                let headers = senderConstrainer.baseHeaders(accessToken: "test-token", tokenType: "Bearer")

                expect(headers.count) == 1
                expect(headers["Authorization"]).to(equal("Bearer test-token"))
            }

        }

    }
}

struct MockSenderConstrainer: SenderConstraining {
    var dpop: DPoP?
}
