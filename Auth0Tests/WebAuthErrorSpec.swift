import Foundation
import Quick
import Nimble

@testable import Auth0

class WebAuthErrorSpec: QuickSpec {

    override func spec() {

        describe("foundation error") {

            it("should build generic NSError") {
                let error = WebAuthError.noBundleIdentifierFound as NSError
                expect(error.domain) == "com.auth0.webauth"
                expect(error.code) == 1
            }

            it("should build error for PKCE not allowed") {
                let message = "Not Allowed"
                let error = WebAuthError.pkceNotAllowed(message) as NSError
                expect(error.domain) == "com.auth0.webauth"
                expect(error.code) == 1
                expect(error.localizedDescription) == message
            }

            it("should build error for user cancelled") {
                let error = WebAuthError.userCancelled as NSError
                expect(error.domain) == "com.auth0.webauth"
                expect(error.code) == 0
            }

            it("should build error for no nonce supplied") {
                let error = WebAuthError.noNonceProvided as NSError
                expect(error.domain) == "com.auth0.webauth"
                expect(error.code) == 1
            }

            it("should build error for no idToken nonce match") {
                let error = WebAuthError.invalidIdTokenNonce as NSError
                expect(error.domain) == "com.auth0.webauth"
                expect(error.code) == 1
            }

            it("should build error for missing access_token") {
                let error = WebAuthError.missingAccessToken as NSError
                expect(error.domain) == "com.auth0.webauth"
                expect(error.code) == 1
            }
        }
    }
}
