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
                let message = "Unable to retrieve the bundle identifier from Bundle.main.bundleIdentifier,"
                + " or it could not be used to build a valid URL."
                let error = WebAuthError(code: .noBundleIdentifier)
                expect(error.localizedDescription) == message
            }

            it("should return message for invalid invitation URL") {
                let url = "https://samples.auth0.com"
                let message = "The invitation URL (\(url)) is missing the 'invitation' and/or"
                + " the 'organization' query parameters."
                let error = WebAuthError(code: .invalidInvitationURL(url))
                expect(error.localizedDescription) == message
            }

            it("should return message for user cancelled") {
                let message = "The user cancelled the Web Auth operation."
                let error = WebAuthError(code: .userCancelled)
                expect(error.localizedDescription) == message
            }

            it("should return message for PKCE not allowed") {
                let message = "Unable to complete authentication with PKCE."
                + " The correct method for Token Endpoint Authentication Method is not set (it should be 'None')."
                + " PKCE support needs to be enabled in the settings page of the Auth0 application, by setting the"
                + " 'ApplicationType' to 'Native' and the 'Token Endpoint Authentication Method' to 'None'."
                let error = WebAuthError(code: .pkceNotAllowed)
                expect(error.localizedDescription) == message
            }

            it("should return message for no authorization code") {
                let values: [String: String] = ["foo": "bar"]
                let message = "The callback URL is missing the authorization code in its"
                + " query parameters (\(values))."
                let error = WebAuthError(code: .noAuthorizationCode(values))
                expect(error.localizedDescription) == message
            }

            it("should return message for id token validation failed") {
                let message = "The ID Token validation performed after Web Auth login failed."
                + " The underlying error can be accessed via the 'cause' property."
                let error = WebAuthError(code: .idTokenValidationFailed)
                expect(error.localizedDescription) == message
            }

            it("should return message for other") {
                let message = "An error occurred. The 'Error' value can be accessed via the 'cause' property."
                let error = WebAuthError(code: .other)
                expect(error.localizedDescription) == message
            }

            it("should return message for unknown") {
                let message = "foo"
                let error = WebAuthError(code: .unknown(message))
                expect(error.localizedDescription) == message
            }

        }

    }

}
