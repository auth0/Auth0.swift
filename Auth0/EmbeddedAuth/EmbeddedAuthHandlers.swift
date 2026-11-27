import Foundation

// MARK: - Authorization loop decoders

extension Auth0EmbeddedAuth {

    /// Decodes an `/e/authorize` response for intermediate steps.
    ///
    /// A `403 insufficient_authorization` failure carries the rotated `auth_session`, which becomes
    /// the active session for the next step; any other failure clears it (see
    /// ``updateSessionFromFailure(_:verifier:)``). Intermediate steps never produce a successful `200`
    /// response in practice — if one arrives, the session is cleared and `.success(())` forwarded.
    ///
    /// When the request that started the flow passes its PKCE `verifier`, it becomes the active one together with
    /// the session the response opens (a continuation without an `auth_session` opens none), so a restarted
    /// `authorize` request always pairs with the challenge it sent. Both are adopted by
    /// ``updateSessionFromFailure(_:verifier:)``, so the two can't drift apart.
    func decodeAuthorizeResponse(
        _ result: Result<ResponseValue, EmbeddedAuthError>,
        verifier: String? = nil,
        callback: @Sendable (Result<Void, EmbeddedAuthError>) -> Void
    ) {
        switch result {
        case .failure(let error):
            callback(.failure(updateSessionFromFailure(error, verifier: verifier)))
        case .success:
            transactionState = nil
            callback(.success(()))
        }
    }

    /// Decodes an `/e/authorize` response that completes the flow with an `authorization_code` and
    /// exchanges that code for ``Credentials``.
    ///
    /// Reusable by any step whose success response carries an `authorization_code`. Session
    /// bookkeeping on failure matches ``decodeAuthorizeResponse(_:verifier:callback:)``. On `200` the
    /// returned code is exchanged via a chained ``exchange(code:verifier:)`` request, with the `verifier` of the flow
    /// that the step was built in. When that exchange settles the session is cleared, except after a network failure:
    /// the call may not have reached the server, so the session is kept and the caller can retry the step.
    func decodeAuthorizationCodeResponse(
        _ result: Result<ResponseValue, EmbeddedAuthError>,
        verifier: String?,
        callback: @escaping @Sendable (Result<Credentials, EmbeddedAuthError>) -> Void
    ) {
        switch result {
        case .failure(let error):
            callback(.failure(updateSessionFromFailure(error)))
        case .success(let response):
            guard let data = response.data,
                  let body = try? JSONDecoder().decode(AuthorizationCodeResponse.self, from: data) else {
                transactionState = nil
                callback(.failure(EmbeddedAuthError(from: response)))
                return
            }
            exchange(code: body.authorizationCode, verifier: verifier).start { [self] exchangeResult in
                switch exchangeResult {
                case .success(let credentials):
                    transactionState = nil
                    callback(.success(credentials))
                case .failure(let error):
                    callback(.failure(updateSessionFromFailure(error)))
                }
            }
        }
    }

}
