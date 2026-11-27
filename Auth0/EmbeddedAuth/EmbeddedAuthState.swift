import Foundation

/// The state of the embedded authorization flow in progress.
///
/// A client holds one while a flow is active (see `Auth0EmbeddedAuth.transactionState`), and replaces it whenever a
/// response rotates the session, so it never changes in place. It is memory only: it never holds a password, and the
/// SDK never logs it. Its description and its reflection redact the session and the PKCE verifier.
///
/// A state always has a PKCE verifier, so a flow that has none can't exist: the client opens a state only from the
/// answer to the `authorize` request that created the verifier.
struct EmbeddedAuthState: Sendable, Equatable {

    /// The rotated `auth_session` the next step sends.
    let authSession: String

    /// Whether the connection asks for a password at sign-up, as learned from the flow so far; `nil` when not known.
    ///
    /// The server does not repeat it when it offers the confirm step, so the client uses it to fill
    /// ``SignupPassword/isRequired``.
    let passwordRequirement: CredentialRequirement?

    /// The PKCE `code_verifier` that pairs with the `code_challenge` the `authorize` request of this flow sent.
    ///
    /// It is adopted together with the session, in the same place, so it always matches the challenge that request
    /// sent, and every later state carries it forward. A step that completes the flow takes it from the state when the
    /// step is built, and the token exchange sends that one.
    let verifier: String

    init(authSession: String, passwordRequirement: CredentialRequirement? = nil, verifier: String) {
        self.authSession = authSession
        self.passwordRequirement = passwordRequirement
        self.verifier = verifier
    }

}

// MARK: - Redaction

extension EmbeddedAuthState: CustomStringConvertible, CustomReflectable {

    private static let redacted = "<REDACTED>"

    var description: String {
        let requirement = passwordRequirement.map { String(describing: $0) } ?? "nil"
        return "EmbeddedAuthState(authSession: \(Self.redacted), passwordRequirement: \(requirement), "
            + "verifier: \(Self.redacted))"
    }

    var customMirror: Mirror {
        Mirror(self,
               children: ["authSession": Self.redacted,
                          "passwordRequirement": passwordRequirement as Any,
                          "verifier": Self.redacted],
               displayStyle: .struct)
    }

}
