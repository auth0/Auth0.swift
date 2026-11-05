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

/// Fails the request locally for an ``EmbeddedAuth`` step the client does not implement.
///
/// Backs the default implementations of protocol requirements added after the first release, so existing
/// external conformers keep compiling and fail predictably instead of reaching the network.
struct EmbeddedAuthUnsupportedStepValidator: RequestValidator {

    func validate() throws {
        throw EmbeddedAuthError.notImplemented
    }

}

extension EmbeddedAuthError {

    /// The error returned by a step the client does not implement.
    static var notImplemented: EmbeddedAuthError {
        EmbeddedAuthError(
            info: ["error": "not_implemented",
                   "error_description": "This EmbeddedAuth client does not implement this step."],
            statusCode: 0
        )
    }

}

extension EmbeddedAuth {

    /// Builds a request that fails with ``EmbeddedAuthError/notImplemented`` before any network call.
    func unsupportedStepRequest<T: Sendable>() -> Request<T, EmbeddedAuthError> {
        Request(
            session: .shared,
            url: URL(fileURLWithPath: "/"),
            method: "POST",
            requestValidator: [EmbeddedAuthUnsupportedStepValidator()],
            handle: { _, callback in callback(.failure(EmbeddedAuthError.notImplemented)) },
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

}
