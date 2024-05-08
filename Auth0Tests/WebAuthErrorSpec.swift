import Foundation
import Quick
import Nimble

@testable import Auth0

class WebAuthErrorSpec: QuickSpec {

    override func spec() {

        describe("init") {

            it("should initialize with code") {
                let error = WebAuthError(code: .other)
                expect(error.code) == WebAuthError.Code.other
                expect(error.cause).to(beNil())
            }

            it("should initialize with code & cause") {
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

            it("should return message for transaction active already") {
                let message = "Failed to start this transaction, as there is an active transaction at the"
                + " moment."
                let error = WebAuthError(code: .transactionActiveAlready)
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
                let message = "Unable to perform authentication with PKCE."
                + " Enable PKCE support in the settings page of the Auth0 application, by setting the"
                + " 'Application Type' to 'Native'."
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
                let message = "The ID token validation performed after authentication failed."
                let error = WebAuthError(code: .idTokenValidationFailed)
                expect(error.localizedDescription) == message
            }

            it("should return message for other") {
                let message = "An unexpected error occurred."
                let error = WebAuthError(code: .other)
                expect(error.localizedDescription) == message
            }

            it("should return message for unknown") {
                let message = "foo"
                let error = WebAuthError(code: .unknown(message))
                expect(error.localizedDescription) == message
            }

            it("should append the cause error message") {
                let cause =  MockError()
                let message = "An unexpected error occurred. CAUSE: \(cause.localizedDescription)"
                let error = WebAuthError(code: .other, cause: cause)
                expect(error.localizedDescription) == message
            }

            it("should append the cause error message with a separator") {
                let description = "foo"
                let cause =  MockError()
                let message = "\(description). CAUSE: \(cause.localizedDescription)"
                let error = WebAuthError(code: .unknown(description), cause: cause)
                expect(error.localizedDescription) == message
            }

        }

    }

}
