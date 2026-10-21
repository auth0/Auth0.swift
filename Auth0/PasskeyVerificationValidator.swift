#if PASSKEYS_PLATFORM
import Foundation

/**
 Validates the `verification` codes of the passkey signup token exchange against the identifiers that the signup
 challenge asked to verify.

 Auth0 rejects a missing code, and an empty code, with an `invalid_request` error. This validator
 reports the same errors before the network request is sent.

 ## See Also

 - ``RequestValidator``
 - ``PasskeyVerificationMethod``
 - ``PasskeySignupChallenge/verificationRequired``
 */
struct PasskeyVerificationValidator: RequestValidator {

    /// The one-time codes, keyed by identifier. Empty when the app did not provide any.
    let verification: [PasskeyVerificationMethod: String]

    /// The identifiers that the signup challenge asked to verify. `nil` or empty when verification is not enabled,
    /// or is not required for any identifier.
    let verificationRequired: [PasskeyVerificationMethod]?

    /**
     Validates that every identifier in `verificationRequired` has a non-empty code in `verification`.

     Nothing is validated when `verificationRequired` is `nil` or empty. Otherwise the identifiers are checked in the
     order the challenge lists them, and the first problem is reported: a missing code is
     `Missing required parameter: verification.<identifier>`, and an empty code is
     `"verification.<identifier>" is not allowed to be empty`. A code with only whitespace or newlines counts as empty.
     Codes for identifiers that are not required are not validated.

     - Throws: ``AuthenticationError`` with the `invalid_request` code if a required code is missing or empty.
     */
    func validate() throws {
        guard let required = verificationRequired, !required.isEmpty else { return }

        for identifier in required {
            guard let code = verification[identifier] else {
                throw invalidRequest("Missing required parameter: verification.\(identifier.rawValue)")
            }

            if code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw invalidRequest("\"verification.\(identifier.rawValue)\" is not allowed to be empty")
            }
        }
    }

    private func invalidRequest(_ description: String) -> AuthenticationError {
        return AuthenticationError(info: ["error": "invalid_request", "error_description": description], statusCode: 0)
    }
}
#endif
