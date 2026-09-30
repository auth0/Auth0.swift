import Foundation

// MARK: - Authorization loop decoders

extension Auth0EmbeddedAuth {

    /// Decodes an `/e/authorize` response for intermediate steps.
    ///
    /// A `403 insufficient_authorization` failure carries the rotated `auth_session`, which becomes
    /// the active session for the next step; any other failure clears it (see
    /// ``updateSessionFromFailure(_:)``). Intermediate steps never produce a successful `200`
    /// response in practice — if one arrives, the session is cleared and `.success(())` forwarded.
    func decodeAuthorizeResponse(
        _ result: Result<ResponseValue, EmbeddedAuthError>,
        callback: @Sendable (Result<Void, EmbeddedAuthError>) -> Void
    ) {
        switch result {
        case .failure(let error):
            updateSessionFromFailure(error)
            callback(.failure(error))
        case .success:
            currentSession = nil
            callback(.success(()))
        }
    }

    /// Decodes a `verifyOtp` `/e/authorize` response and, on success, exchanges the authorization
    /// code for ``Credentials``.
    ///
    /// A thin wrapper over ``decodeAuthorizationCodeResponse(_:callback:)``, shared by every step
    /// that completes the flow by returning an `authorization_code`.
    func decodeVerifyOtpResponse(
        _ result: Result<ResponseValue, EmbeddedAuthError>,
        callback: @escaping @Sendable (Result<Credentials, EmbeddedAuthError>) -> Void
    ) {
        decodeAuthorizationCodeResponse(result, callback: callback)
    }

    /// Decodes an `/e/authorize` response that completes the flow with an `authorization_code` and
    /// exchanges that code for ``Credentials``.
    ///
    /// Reusable by any step whose success response carries an `authorization_code`. Session
    /// bookkeeping on failure matches ``decodeAuthorizeResponse(_:callback:)``. On `200` the
    /// returned code is exchanged via a chained ``exchange(code:)`` request; the code is single-use,
    /// so the flow's session is cleared once that exchange settles regardless of its outcome.
    func decodeAuthorizationCodeResponse(
        _ result: Result<ResponseValue, EmbeddedAuthError>,
        callback: @escaping @Sendable (Result<Credentials, EmbeddedAuthError>) -> Void
    ) {
        switch result {
        case .failure(let error):
            updateSessionFromFailure(error)
            callback(.failure(error))
        case .success(let response):
            guard let data = response.data,
                  let body = try? JSONDecoder().decode(AuthorizationCodeResponse.self, from: data) else {
                currentSession = nil
                callback(.failure(EmbeddedAuthError(from: response)))
                return
            }
            exchange(code: body.authorizationCode).start { [self] exchangeResult in
                currentSession = nil
                callback(exchangeResult)
            }
        }
    }

}
