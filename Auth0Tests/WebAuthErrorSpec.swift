import Foundation
import Quick
import Nimble

@testable import Auth0

class WebAuthErrorSpec: QuickSpec {

    override class func spec() {

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

            it("should return message for transaction active already") {
                let message = "Failed to start this transaction, as there is an active transaction at the"
                + " moment."
                let error = WebAuthError(code: .transactionActiveAlready)
                expect(error.localizedDescription) == message
            }

            it("should return message for user cancelled") {
                let message = "The user cancelled the Web Auth operation."
                let error = WebAuthError(code: .userCancelled)
                expect(error.localizedDescription) == message
            }

            it("should return message for authentication failed") {
                let message = "The authentication request failed."
                let authError = AuthenticationError(info: ["error": "access_denied"], statusCode: 302)
                let error = WebAuthError(code: .authenticationFailed, cause: authError)
                expect(error.message) == message
                expect(error.cause).toNot(beNil())
            }

            it("should return message for code exchange failed") {
                let message = "The authorization code exchange failed."
                let authError = AuthenticationError(info: ["error": "invalid_grant"], statusCode: 400)
                let error = WebAuthError(code: .codeExchangeFailed, cause: authError)
                expect(error.message) == message
                expect(error.cause).toNot(beNil())
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
                let description = "foo."
                let cause = MockError(message: "foo bar.")
                let message = "\(description) CAUSE: \(cause.localizedDescription)"
                let error = WebAuthError(code: .unknown(description), cause: cause)
                expect(error.localizedDescription) == message
            }

            it("should append the cause error message adding periods") {
                let description = "foo"
                let cause = MockError(message: "foo bar")
                let message = "\(description). CAUSE: \(cause.localizedDescription)."
                let error = WebAuthError(code: .unknown(description), cause: cause)
                expect(error.localizedDescription) == message
            }

        }

    }

}
