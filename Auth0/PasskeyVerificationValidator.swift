#if PASSKEYS_PLATFORM
import Foundation

/**
 Validates the `verification` codes of the passkey signup token exchange.

 Auth0 rejects a `verification` object without codes, and a code that is an empty string, with an `invalid_request`
 error. This validator catches both before the network request is sent.

 ## See Also

 - ``RequestValidator``
 - ``PasskeyVerificationMethod``
 */
struct PasskeyVerificationValidator: RequestValidator {

    /// The one-time codes, keyed by identifier. `nil` when no verification is required.
    let verification: [PasskeyVerificationMethod: String]?

    /**
     Validates that `verification`, when present, has at least one code, and that the codes of the email and of the
     phone, when present, are not empty. Any other identifier is left for Auth0 to validate.

     When both codes are empty, the email is the one named.

     - Throws: ``AuthenticationError`` with the `invalid_request` code if the verification is not valid.
     */
    func validate() throws {
        guard let verification = verification else { return }

        if verification.isEmpty {
            throw invalidRequest("Missing required parameter: verification must have atleast one identifier otp code")
        }

        if verification[.email]?.isEmpty == true {
            throw invalidRequest("\"verification.email\" is not allowed to be empty")
        }

        if verification[.phone]?.isEmpty == true {
            throw invalidRequest("\"verification.phone\" is not allowed to be empty")
        }
    }

    private func invalidRequest(_ description: String) -> AuthenticationError {
        return AuthenticationError(info: ["error": "invalid_request", "error_description": description], statusCode: 0)
    }
}
#endif
