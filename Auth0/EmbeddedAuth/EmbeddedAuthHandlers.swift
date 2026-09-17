import Foundation

// MARK: - Response decoders

func decodeDiscoveryResult(
    from result: Result<ResponseValue, EmbeddedAuthError>,
    callback: @Sendable (Result<DiscoveryResult, EmbeddedAuthError>) -> Void
) {
    switch result {
    case .failure(let error):
        callback(.failure(error))
    case .success(let response):
        guard let data = response.data else {
            callback(.failure(EmbeddedAuthError(from: response)))
            return
        }
        do {
            let decoded = try JSONDecoder().decode(DiscoveryResponse.self, from: data)
            callback(.success(DiscoveryResult(options: decoded.alternatives.compactMap(\.loginOption))))
        } catch {
            callback(.failure(EmbeddedAuthError(from: response)))
        }
    }
}

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
    /// Session bookkeeping on failure matches ``decodeAuthorizeResponse(_:callback:)``. On `200`
    /// the returned code is exchanged via a chained ``exchange(code:)`` request, and the flow's
    /// session is cleared only once that exchange succeeds.
    func decodeVerifyOtpResponse(
        _ result: Result<ResponseValue, EmbeddedAuthError>,
        callback: @escaping @Sendable (Result<Credentials, EmbeddedAuthError>) -> Void
    ) {
        switch result {
        case .failure(let error):
            updateSessionFromFailure(error)
            callback(.failure(error))
        case .success(let response):
            guard let data = response.data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["authorization_code"] as? String else {
                callback(.failure(EmbeddedAuthError(from: response)))
                return
            }
            exchange(code: code).start { [self] exchangeResult in
                if case .success = exchangeResult { currentSession = nil }
                callback(exchangeResult)
            }
        }
    }

}
