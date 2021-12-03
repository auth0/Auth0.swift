import Foundation
import Quick
import Nimble

@testable import Auth0

class WebAuthErrorSpec: QuickSpec {

    override func spec() {

        describe("error message") {

            it("should return message for no bundle identifier") {
                let message = "Unable to retrieve the bundle identifier."
                let error = WebAuthError(code: .noBundleIdentifier)
                expect(error.localizedDescription) == message
            }

            it("should return message for malformed invitation URL") {
                let url = "https://samples.auth0.com"
                let message = "The invitation URL (\(url)) is missing the required query parameters 'invitation' and 'organization'."
                let error = WebAuthError(code: .malformedInvitationURL(url))
                expect(error.localizedDescription) == message
            }

            it("should return message for user cancelled") {
                let message = "User cancelled Web Authentication."
                let error = WebAuthError(code: .userCancelled)
                expect(error.localizedDescription) == message
            }

            it("should return message for no authorization code") {
                let values: [String: String] = ["foo": "bar"]
                let message = "No authorization code found in \(values)."
                let error = WebAuthError(code: .noAuthorizationCode(values))
                expect(error.localizedDescription) == message
            }

            it("should return message for PKCE not allowed") {
                let message = "Unable to complete authentication with PKCE. PKCE support can be enabled by setting Application Type to 'Native' and Token Endpoint Authentication Method to 'None' for this app in the Auth0 Dashboard."
                let error = WebAuthError(code: .pkceNotAllowed)
                expect(error.localizedDescription) == message
            }

            it("should return the default message") {
                let message = "Failed to perform Web Auth operation."
                let error = WebAuthError(code: .other)
                expect(error.localizedDescription) == message
            }

        }

    }
}
