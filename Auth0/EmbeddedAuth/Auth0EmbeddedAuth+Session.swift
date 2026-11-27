import Foundation

extension Auth0EmbeddedAuth {

    /// Updates the flow's state after a step fails, and returns the error to deliver.
    ///
    /// - On a continuation (`.insufficientAuthorization`) the rotated `auth_session` becomes the active session so the
    ///   next step can proceed, together with the PKCE `verifier` of the `authorize` request being answered, or the one
    ///   already held when a later step answers. An answer with neither, which is a late answer of a superseded flow,
    ///   opens no state. The password requirement of a sign-up is remembered from the sign-up offer, or from a
    ///   `password_required` answer, and used to correct ``SignupPassword/isRequired`` on the error's
    ///   ``NextAction/confirmSignup(password:)``, because the server does not repeat it at the confirm step.
    /// - On a network failure (`.network`) the state is preserved so the caller can retry the same step.
    /// - On all other failures the state is cleared; any follow-on step will fail locally with `.noActiveSession`.
    func updateSessionFromFailure(_ error: EmbeddedAuthError, verifier: String? = nil) -> EmbeddedAuthError {
        switch error.reason {
        case .insufficientAuthorization(let reason, let nextActions):
            guard let authSession = error.info["auth_session"] as? String else { return error }
            let announced = nextActions.lazy.compactMap { action -> CredentialRequirement? in
                if case .signup(_, let requirement) = action { return requirement }
                return nil
            }.first
            let requirement: CredentialRequirement?
            if case .passwordRequired = reason {
                // The sign-up offer comes from the connection's configuration, but the server can still answer
                // `password_required` for a password it calls optional, when the users service refuses an account
                // without one. Treat that answer as proof the password is needed, so the app stops offering a skip
                // that always fails.
                requirement = .required
            } else {
                requirement = announced ?? transactionState?.passwordRequirement
            }
            let actions = nextActions.map { $0.withRequired(requirement == .required) }
            if let verifier = verifier ?? transactionState?.verifier {
                transactionState = EmbeddedAuthState(authSession: authSession,
                                                     passwordRequirement: requirement,
                                                     verifier: verifier)
            } else {
                transactionState = nil
            }
            return actions == nextActions ? error : error.withNextActions(actions)
        case .network:
            return error
        default:
            transactionState = nil
            return error
        }
    }
}

private extension NextAction {

    /// This action with the password flag of a ``NextAction/confirmSignup(password:)`` set to `isRequired`. Any other
    /// action is returned as is.
    func withRequired(_ isRequired: Bool) -> NextAction {
        guard case .confirmSignup(let password?) = self else { return self }
        return .confirmSignup(password: SignupPassword(isRequired: isRequired, complexity: password.complexity))
    }

}
