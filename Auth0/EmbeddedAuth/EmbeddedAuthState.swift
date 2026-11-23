import Foundation

/// The state of the embedded authorization flow in progress.
///
/// A client holds one while a flow is active (see `Auth0EmbeddedAuth.transactionState`), and replaces it whenever a
/// response rotates the session, so it never changes in place. It is memory only: it never holds a password, and the
/// SDK never logs it.
struct EmbeddedAuthState: Sendable, Equatable {

    /// The rotated `auth_session` the next step sends.
    let authSession: String

    /// Whether the connection asks for a password at sign-up, as learned from the flow so far; `nil` when not known.
    ///
    /// The server does not repeat it when it offers the confirm step, so the client uses it to fill
    /// ``SignupPassword/isRequired``.
    let passwordRequirement: CredentialRequirement?

    init(authSession: String, passwordRequirement: CredentialRequirement? = nil) {
        self.authSession = authSession
        self.passwordRequirement = passwordRequirement
    }

}
