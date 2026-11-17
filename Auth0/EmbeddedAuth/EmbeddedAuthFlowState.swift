import Foundation

/// The state of the embedded authorization flow a client is running.
///
/// Every transition is a method of this type, so the whole lifecycle reads in one place:
///
/// | Event | `session` | `signupPasswordRequirement` |
/// |-------|-----------|-----------------------------|
/// | ``Auth0EmbeddedAuth/authorize(connection:capabilities:scope:audience:)`` is called | cleared | cleared |
/// | Continuation with an `auth_session` | rotated | updated |
/// | Continuation without an `auth_session` | kept | updated |
/// | Network failure | kept | kept |
/// | Any other failure, an unexpected success, a completed token exchange | cleared | cleared |
///
/// "Updated" means: the requirement of a `signup` offer replaces it, and a `password_required` answer makes it
/// ``CredentialRequirement/required``.
///
/// The state is memory only. It never holds a password, and the SDK never logs it.
struct EmbeddedAuthFlowState: Sendable, Equatable {

    /// The rotated `auth_session` the next step sends; `nil` when no flow is in progress.
    private(set) var session: String?

    /// Whether the connection asks for a password at sign-up, as learned so far; `nil` when not known.
    ///
    /// The server does not repeat it when it offers the confirm step, so ``EmbeddedAuthError`` uses it to fill
    /// ``SignupPassword/isRequired``.
    private(set) var signupPasswordRequirement: CredentialRequirement?

    /// Ends the flow, forgetting everything about it.
    mutating func end() {
        self = EmbeddedAuthFlowState()
    }

    /// Applies a failed step to the flow.
    mutating func apply(_ failure: EmbeddedAuthError) {
        switch failure.reason {
        case .insufficientAuthorization(let reason, let nextActions):
            if let rotated = failure.info["auth_session"] as? String {
                session = rotated
            }
            for case .signup(_, let requirement) in nextActions {
                signupPasswordRequirement = requirement
            }
            // The sign-up offer comes from the connection's configuration, but the server can still answer
            // `password_required` for a password it calls optional, when the users service refuses an account without
            // one. Treat that answer as proof the password is needed, so the app stops offering a skip that always fails.
            if case .passwordRequired = reason {
                signupPasswordRequirement = .required
            }
        case .network:
            // The request may not have reached the server, so the same step can be retried.
            break
        default:
            end()
        }
    }

}
