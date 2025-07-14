import Foundation
import Quick
import Nimble

@testable import Auth0

class DPoPErrorSpec: QuickSpec {

    override class func spec() {

        describe("init") {

            it("should initialize with code") {
                let error = DPoPError(code: .other)
                expect(error.code) == DPoPError.Code.other
                expect(error.cause).to(beNil())
            }

            it("should initialize with code & cause") {
                let cause = NSError(domain: "example", code: 123)
                let error = DPoPError(code: .other, cause: cause)
                expect(error.cause).to(matchError(cause))
            }

        }

        describe("operators") {

            it("should be equal by code") {
                let error = DPoPError(code: .other)
                expect(error) == DPoPError.other
            }

            it("should not be equal to an error with a different code") {
                let error = DPoPError(code: .other)
                expect(error) != DPoPError.unknown
            }

            it("should not be equal to an error with a different description") {
                let error = DPoPError(code: .unknown("foo"))
                expect(error) != DPoPError(code: .unknown("bar"))
            }

            it("should pattern match by code") {
                let error = DPoPError(code: .other)
                expect(error ~= DPoPError.other) == true
            }

            it("should not pattern match by code with a different error") {
                let error = DPoPError(code: .other)
                expect(error ~= DPoPError.unknown) == false
            }

            it("should pattern match by code with a generic error") {
                let error = DPoPError(code: .other)
                expect(error ~= (DPoPError.other) as Error) == true
            }

            it("should not pattern match by code with a different generic error") {
                let error = DPoPError(code: .other)
                expect(error ~= (DPoPError.unknown) as Error) == false
            }

        }

        describe("debug description") {

            it("should match the localized message") {
                let error = DPoPError(code: .other)
                expect(error.debugDescription) == DPoPError.other.debugDescription
            }

            it("should match the error description") {
                let error = DPoPError(code: .other)
                expect(error.debugDescription) == DPoPError.other.errorDescription
            }

        }

        describe("error message") {

            it("should return message for secure enclave operation failed") {
                let message = "foo"
                let error = DPoPError(code: .secureEnclaveOperationFailed(message))
                expect(error.localizedDescription) == message
            }

            it("should return message for keychain operation failed") {
                let message = "foo"
                let error = DPoPError(code: .keychainOperationFailed(message))
                expect(error.localizedDescription) == message
            }

            it("should return message for cryptokit operation failed") {
                let message = "foo"
                let error = DPoPError(code: .cryptoKitOperationFailed(message))
                expect(error.localizedDescription) == message
            }

            it("should return message for seckey operation failed") {
                let message = "foo"
                let error = DPoPError(code: .secKeyOperationFailed(message))
                expect(error.localizedDescription) == message
            }

            it("should return message for other") {
                let message = "An unexpected error occurred."
                let error = DPoPError(code: .other)
                expect(error.localizedDescription) == message
            }

            it("should return message for unknown") {
                let message = "foo"
                let error = DPoPError(code: .unknown(message))
                expect(error.localizedDescription) == message
            }

            it("should append the cause error message") {
                let description = "foo."
                let cause = MockError(message: "foo bar.")
                let message = "\(description) CAUSE: \(cause.localizedDescription)"
                let error = DPoPError(code: .unknown(description), cause: cause)
                expect(error.localizedDescription) == message
            }

            it("should append the cause error message adding periods") {
                let description = "foo"
                let cause = MockError(message: "foo bar")
                let message = "\(description). CAUSE: \(cause.localizedDescription)."
                let error = DPoPError(code: .unknown(description), cause: cause)
                expect(error.localizedDescription) == message
            }

        }

    }

}
