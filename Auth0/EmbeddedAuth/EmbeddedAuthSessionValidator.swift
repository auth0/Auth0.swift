import Foundation

/// Fails the request locally when there is no active ``EmbeddedAuthClient`` session.
///
/// Prevents continuation methods from making a network call when ``EmbeddedAuthClient/authorize(connection:capabilities:scope:audience:)``
/// has not been called first (or after a successful ``EmbeddedAuthorizationCode`` was already issued).
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
