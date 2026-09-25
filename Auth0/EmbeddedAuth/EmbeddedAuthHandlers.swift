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

    /// Decodes an `/e/authorize` response into an ``EmbeddedAuthorizationCode``.
    ///
    /// A `403 insufficient_authorization` failure carries the rotated `auth_session`, which is
    /// captured for the next step; a terminal `access_denied` clears it. A `200` success clears
    /// the session and yields the authorization code.
    func decodeAuthorizeResponse(
        _ result: Result<ResponseValue, EmbeddedAuthError>,
        callback: @Sendable (Result<EmbeddedAuthorizationCode, EmbeddedAuthError>) -> Void
    ) {
        switch result {
        case .failure(let error):
            if error.isInsufficientAuthorization,
               let newSession = error.info["auth_session"] as? String {
                setAuthSession(newSession)
            } else if error.isAccessDenied {
                setAuthSession(nil)
            }
            callback(.failure(error))
        case .success(let response):
            guard let data = response.data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["authorization_code"] as? String else {
                callback(.failure(EmbeddedAuthError(from: response)))
                return
            }
            setAuthSession(nil)
            callback(.success(EmbeddedAuthorizationCode(code: code)))
        }
    }

    /// Decodes a `verifyOtp` `/e/authorize` response and, on success, exchanges the authorization
    /// code for ``Credentials``.
    ///
    /// Session bookkeeping matches ``decodeAuthorizeResponse(_:callback:)``. On `200` the session
    /// is cleared and the code is exchanged synchronously — safe because this runs on a URLSession
    /// background thread (see ``exchangeCodeSynchronously(_:)``).
    func decodeVerifyOtpResponse(
        _ result: Result<ResponseValue, EmbeddedAuthError>,
        callback: @Sendable (Result<Credentials, EmbeddedAuthError>) -> Void
    ) {
        switch result {
        case .failure(let error):
            if error.isInsufficientAuthorization,
               let newSession = error.info["auth_session"] as? String {
                setAuthSession(newSession)
            } else if error.isAccessDenied {
                setAuthSession(nil)
            }
            callback(.failure(error))
        case .success(let response):
            guard let data = response.data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["authorization_code"] as? String else {
                callback(.failure(EmbeddedAuthError(from: response)))
                return
            }
            setAuthSession(nil)
            // Synchronous exchange: safe because we're already on a URLSession background thread.
            callback(exchangeCodeSynchronously(code))
        }
    }

}
