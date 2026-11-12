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

/// Fails the request locally because an ``EmbeddedAuth`` conformance does not implement `requirement`.
struct EmbeddedAuthNotImplementedValidator: RequestValidator {

    let requirement: String

    func validate() throws {
        throw EmbeddedAuthError.notImplemented(requirement: requirement)
    }

}

extension EmbeddedAuthError {

    /// The error for a method the conforming type does not implement. Carries no request data.
    static func notImplemented(requirement: String) -> EmbeddedAuthError {
        EmbeddedAuthError(
            info: ["error": notImplementedError,
                   "error_description": "\(requirement) is not implemented by this EmbeddedAuth conformance."],
            statusCode: 0
        )
    }

}
