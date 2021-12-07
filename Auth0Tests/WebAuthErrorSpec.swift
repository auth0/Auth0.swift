import Foundation
import Quick
import Nimble

@testable import Auth0

class WebAuthErrorSpec: QuickSpec {

    override func spec() {

        describe("init") {

            it("should initialize with type") {
                let error = WebAuthError(code: .other)
                expect(error.code) == WebAuthError.Code.other
                expect(error.cause).to(beNil())
            }

            it("should initialize with type & cause") {
                let cause = AuthenticationError(description: "")
                let error = WebAuthError(code: .other, cause: cause)
                expect(error.cause).to(matchError(cause))
            }

        }

        describe("operators") {

            it("should be equal by code") {
                let error = WebAuthError(code: .other)
                expect(error) == WebAuthError.other
            }

            it("should not be equal to an error with a different code") {
                let error = WebAuthError(code: .other)
                expect(error) != WebAuthError.unknown
            }

            it("should not be equal to an error with a different description") {
                let error = WebAuthError(code: .unknown("foo"))
                expect(error) != WebAuthError(code: .unknown("bar"))
            }

            it("should pattern match by code") {
                let error = WebAuthError(code: .other)
                expect(error ~= WebAuthError.other) == true
            }

            it("should not pattern match by code with a different error") {
                let error = WebAuthError(code: .other)
                expect(error ~= WebAuthError.unknown) == false
            }

            it("should pattern match by code with a generic error") {
                let error = WebAuthError(code: .other)
                expect(error ~= (WebAuthError.other) as Error) == true
            }

            it("should not pattern match by code with a different generic error") {
                let error = WebAuthError(code: .other)
                expect(error ~= (WebAuthError.unknown) as Error) == false
            }

        }

        describe("debug description") {

            it("should match the localized message") {
                let error = WebAuthError(code: .other)
                expect(error.debugDescription) == WebAuthError.other.debugDescription
            }

            it("should match the error description") {
                let error = WebAuthError(code: .other)
                expect(error.debugDescription) == WebAuthError.other.errorDescription
            }

        }

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

            it("should return message for unknown") {
                let message = "foo"
                let error = WebAuthError(code: .unknown(message))
                expect(error.localizedDescription) == message
            }

            it("should return the default message for id token validation failed") {
                let message = "Failed to perform Web Auth operation."
                let error = WebAuthError(code: .idTokenValidationFailed)
                expect(error.localizedDescription) == message
            }

            it("should return the default message for other") {
                let message = "Failed to perform Web Auth operation."
                let error = WebAuthError(code: .other)
                expect(error.localizedDescription) == message
            }

        }

    }

}
