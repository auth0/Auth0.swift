import Foundation

// MARK: - Authorization loop decoders

extension Auth0EmbeddedAuth {

    /// Decodes an `/e/authorize` response for intermediate steps.
    ///
    /// A `403 insufficient_authorization` failure carries the rotated `auth_session`, which becomes
    /// the active session for the next step; any other failure clears it (see
    /// ``EmbeddedAuthFlowState/apply(_:)``). Intermediate steps never produce a successful `200`
    /// response in practice — if one arrives, the session is cleared and `.success(())` forwarded.
    func decodeAuthorizeResponse(
        _ result: Result<ResponseValue, EmbeddedAuthError>,
        callback: @Sendable (Result<Void, EmbeddedAuthError>) -> Void
    ) {
        switch result {
        case .failure(let error):
            callback(.failure(record(error)))
        case .success:
            flow.end()
            callback(.success(()))
        }
    }

    /// Decodes an `/e/authorize` response that completes the flow with an `authorization_code` and
    /// exchanges that code for ``Credentials``.
    ///
    /// Reusable by any step whose success response carries an `authorization_code`. Session
    /// bookkeeping on failure matches ``decodeAuthorizeResponse(_:callback:)``. On `200` the
    /// returned code is exchanged via a chained ``exchange(code:)`` request. When that exchange settles the
    /// session is cleared, except after a network failure: the call may not have reached the server, so the
    /// session is kept and the caller can retry the step.
    func decodeAuthorizationCodeResponse(
        _ result: Result<ResponseValue, EmbeddedAuthError>,
        callback: @escaping @Sendable (Result<Credentials, EmbeddedAuthError>) -> Void
    ) {
        switch result {
        case .failure(let error):
            callback(.failure(record(error)))
        case .success(let response):
            guard let data = response.data,
                  let body = try? JSONDecoder().decode(AuthorizationCodeResponse.self, from: data) else {
                flow.end()
                callback(.failure(EmbeddedAuthError(from: response)))
                return
            }
            exchange(code: body.authorizationCode).start { [self] exchangeResult in
                switch exchangeResult {
                case .success(let credentials):
                    flow.end()
                    callback(.success(credentials))
                case .failure(let error):
                    callback(.failure(record(error)))
                }
            }
        }
    }

    /// Applies a failed step to the flow, then returns the error to deliver: the error itself, carrying the password
    /// requirement the flow learned so far.
    ///
    /// This is the single place that attaches the requirement. An error does not know about the flow, because it is
    /// parsed lazily from the server's JSON and the server does not repeat the requirement at the confirm step.
    private func record(_ error: EmbeddedAuthError) -> EmbeddedAuthError {
        flow.apply(error)
        return error.withSignupPasswordRequirement(flow.signupPasswordRequirement)
    }

}
