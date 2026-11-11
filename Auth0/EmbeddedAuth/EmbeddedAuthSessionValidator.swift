import Foundation

/// Fails the request locally when there is no active ``EmbeddedAuth`` session.
///
/// Prevents continuation methods from making a network call when ``EmbeddedAuth/authorize(connection:capabilities:scope:audience:)``
/// has not been called first (or after a successful ``EmbeddedAuth/verifyOtp(_:type:)`` call).
struct EmbeddedAuthSessionValidator: RequestValidator {

    let hasSession: Bool

    func validate() throws {
        guard hasSession else {
            throw EmbeddedAuthError(
                info: ["error": "no_active_session",
                       "error_description": "No active embedded auth session. Call authorize() first."],
                statusCode: 0
            )
        }
    }

}

/// Fails the request locally when the input of a step is not valid, before anything is sent.
///
/// The message must never contain secrets such as passkey data.
struct EmbeddedAuthInputValidator: RequestValidator {

    let message: String

    func validate() throws {
        throw EmbeddedAuthError(
            info: ["error": "invalid_input", "error_description": message],
            statusCode: 0
        )
    }

}

/// Fails the request locally for a requirement that an external ``EmbeddedAuth`` conformance does not implement.
struct EmbeddedAuthNotImplementedValidator: RequestValidator {

    let requirement: String

    func validate() throws {
        throw EmbeddedAuthError(
            info: ["error": notImplementedError,
                   "error_description": "\(requirement) is not implemented by this EmbeddedAuth conformance."],
            statusCode: 0
        )
    }

}
