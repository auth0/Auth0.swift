import Foundation
import Quick
import Nimble

@testable import Auth0

class WebAuthErrorSpec: QuickSpec {

    override func spec() {

        describe("error messages") {

            it("should return message for user cancelled") {
                let message = "User cancelled Web Authentication"
                let error = WebAuthError.userCancelled
                expect(error.localizedDescription) == message
            }

            it("should return message for PKCE not allowed") {
                let message = "Unable to complete authentication with PKCE. PKCE support can be enabled by setting Application Type to 'Native' and Token Endpoint Authentication Method to 'None' for this app in the Auth0 Dashboard."
                let error = WebAuthError.pkceNotAllowed
                expect(error.localizedDescription) == message
            }

            it("should return message for missing access token") {
                let message = "Could not validate the token"
                let error = WebAuthError.missingAccessToken
                expect(error.localizedDescription) == message
            }

        }
    }
}
