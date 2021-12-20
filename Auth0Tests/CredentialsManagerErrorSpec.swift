import Foundation
import Quick
import Nimble

@testable import Auth0

class CredentialsManagerErrorSpec: QuickSpec {

    override func spec() {

        describe("init") {

            it("should initialize with type") {
                let error = CredentialsManagerError(code: .noCredentials)
                expect(error.code) == CredentialsManagerError.Code.noCredentials
                expect(error.cause).to(beNil())
            }

            it("should initialize with type & cause") {
                let cause = AuthenticationError(description: "")
                let error = CredentialsManagerError(code: .noCredentials, cause: cause)
                expect(error.cause).to(matchError(cause))
            }

        }

        describe("operators") {

            it("should be equal by code") {
                let error = CredentialsManagerError(code: .noCredentials)
                expect(error) == CredentialsManagerError.noCredentials
            }

            it("should not be equal to an error with a different code") {
                let error = CredentialsManagerError(code: .noCredentials)
                expect(error) != CredentialsManagerError.noRefreshToken
            }

            it("should not be equal to an error with a different description") {
                let error = CredentialsManagerError(code: .largeMinTTL(minTTL: 1000, lifetime: 500))
                expect(error) != CredentialsManagerError(code: .largeMinTTL(minTTL: 2000, lifetime: 1000))
            }

            it("should pattern match by code") {
                let error = CredentialsManagerError(code: .noCredentials)
                expect(error ~= CredentialsManagerError.noCredentials) == true
            }

            it("should not pattern match by code with a different error") {
                let error = CredentialsManagerError(code: .noCredentials)
                expect(error ~= CredentialsManagerError.noRefreshToken) == false
            }

            it("should pattern match by code with a generic error") {
                let error = CredentialsManagerError(code: .noCredentials)
                expect(error ~= (CredentialsManagerError.noCredentials) as Error) == true
            }

            it("should not pattern match by code with a different generic error") {
                let error = CredentialsManagerError(code: .noCredentials)
                expect(error ~= (CredentialsManagerError.noRefreshToken) as Error) == false
            }

        }

        describe("debug description") {

            it("should match the localized message") {
                let error = CredentialsManagerError(code: .noCredentials)
                expect(error.debugDescription) == CredentialsManagerError.noCredentials.debugDescription
            }

            it("should match the error description") {
                let error = CredentialsManagerError(code: .noCredentials)
                expect(error.debugDescription) == CredentialsManagerError.noCredentials.errorDescription
            }

        }

        describe("error message") {

            it("should return message for no credentials") {
                let message = "No credentials were found in the store."
                let error = CredentialsManagerError(code: .noCredentials)
                expect(error.localizedDescription) == message
            }

            it("should return message for no refresh token") {
                let message = "The stored credentials instance does not contain a Refresh Token."
                let error = CredentialsManagerError(code: .noRefreshToken)
                expect(error.localizedDescription) == message
            }

            it("should return message for renew failed") {
                let message = "The credentials renewal failed. The underlying 'AuthenticationError' can be"
                + " accessed via the 'cause' property."
                let error = CredentialsManagerError(code: .renewFailed)
                expect(error.localizedDescription) == message
            }

            it("should return message for biometrics failed") {
                let message = "The Biometric authentication failed. The underlying 'LAError' can be accessed"
                + " via the 'cause' property."
                let error = CredentialsManagerError(code: .biometricsFailed)
                expect(error.localizedDescription) == message
            }

            it("should return message for revoke failed") {
                let message = "The revocation of the Refresh Token failed. The underlying 'AuthenticationError'"
                + " can be accessed via the 'cause' property."
                let error = CredentialsManagerError(code: .revokeFailed)
                expect(error.localizedDescription) == message
            }

            it("should return message when minTTL is too big") {
                let minTTL = 7200
                let lifetime = 3600
                let message = "The minTTL requested (\(minTTL)s) is greater than the"
                + " lifetime of the renewed Access Token (\(lifetime)s). Request a lower minTTL or increase the"
                + " 'Token Expiration' setting of your Auth0 API in the Dashboard."
                let error = CredentialsManagerError(code: .largeMinTTL(minTTL: minTTL, lifetime: lifetime))
                expect(error.localizedDescription) == message
            }

        }

    }

}
