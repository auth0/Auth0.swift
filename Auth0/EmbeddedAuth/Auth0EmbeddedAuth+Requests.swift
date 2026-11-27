import Foundation

extension Auth0EmbeddedAuth {

    /// Builds a `POST /e/authorize` request for an intermediate step of the loop.
    ///
    /// - Parameter verifier: The PKCE `code_verifier` of the request that starts the flow, which pairs with the
    ///   `code_challenge` in its `body`. Continuation requests pass `nil`.
    func authorizeRequest(body: [String: Any], verifier: String? = nil) -> Request<Void, EmbeddedAuthError> {
        Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: { [weak self] result, callback in
                guard let self else {
                    // The client is gone, so there is no flow to update: deliver the answer as it is.
                    callback(result.map { _ in () })
                    return
                }
                decodeAuthorizeResponse(result, verifier: verifier, callback: callback)
            },
            parameters: body,
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Builds a `POST /e/authorize` request for a step that completes the flow with an `authorization_code`, and
    /// exchanges that code for ``Credentials``.
    ///
    /// - Parameter verifier: The PKCE `code_verifier` of the flow as it is when the step is built. The exchange sends
    ///   this one, so the code always pairs with the flow that issued it, whatever happens to the client's state while
    ///   the request is in flight.
    func authorizationCodeRequest(body: [String: Any], verifier: String?) -> Request<Credentials, EmbeddedAuthError> {
        Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: { [self] result, callback in
                decodeAuthorizationCodeResponse(result, verifier: verifier, callback: callback)
            },
            parameters: body,
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Exchanges the authorization code returned by a completed flow for ``Credentials``, with the PKCE `code_verifier`
    /// of that flow.
    func exchange(code: String, verifier: String?) -> Request<Credentials, EmbeddedAuthError> {
        var parameters: [String: Any] = [
            "client_id": clientId,
            "grant_type": "authorization_code",
            "code": code
        ]
        if let verifier { parameters["code_verifier"] = verifier }
        return Request(
            session: session,
            url: url.appending("oauth/token"),
            method: "POST",
            handle: { result, callback in
                switch result {
                case .failure(let error):
                    callback(.failure(error))
                case .success(let response):
                    guard let data = response.data,
                          let credentials = try? JSONDecoder().decode(Credentials.self, from: data) else {
                        callback(.failure(EmbeddedAuthError(from: response)))
                        return
                    }
                    callback(.success(credentials))
                }
            },
            parameters: parameters,
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }
}
