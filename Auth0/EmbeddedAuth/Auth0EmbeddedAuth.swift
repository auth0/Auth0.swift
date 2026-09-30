import Foundation

// MARK: - Concrete implementation

/// Concrete implementation of ``EmbeddedAuth``.
///
/// Handles both discovery (`GET /e/discovery`) and the interactive authorization
/// loop (`POST /e/authorize`). Obtain instances via
/// ``Auth0/embeddedAuth(clientId:domain:session:)`` or ``Auth0/embeddedAuth(session:bundle:)``.
///
/// A client tracks a single in-progress flow: calling ``authorize(connection:capabilities:scope:audience:)``
/// again abandons any previous one, so a new sign-in never reuses a stale session.
final class Auth0EmbeddedAuth: EmbeddedAuth, @unchecked Sendable {

    /// Auth0 application client ID.
    let clientId: String

    /// Base URL derived from the tenant domain.
    let url: URL

    /// URL session used for all network requests.
    let session: URLSession

    /// Auth0-Client telemetry header value.
    var auth0ClientInfo: Auth0ClientInfo

    /// Optional logger for request/response tracing.
    var logger: Logger?

    /// The rotated `auth_session` for the in-progress flow; `nil` when no flow is active.
    ///
    /// Internal storage only — deliberately not named `authSession` and not exposed on the
    /// ``EmbeddedAuth`` protocol, so callers cannot read the session. The flow is strictly
    /// sequential — each step starts only after the previous one delivers its result — so this
    /// value is never touched concurrently.
    var currentSession: String?

    init(clientId: String,
         url: URL,
         session: URLSession = .shared,
         auth0ClientInfo: Auth0ClientInfo = Auth0ClientInfo()) {
        self.clientId = clientId
        self.url = url
        self.session = session
        self.auth0ClientInfo = auth0ClientInfo
    }

    // MARK: Discovery

    func discover(connection: String?) -> Request<DiscoveryResult, EmbeddedAuthError> {
        var params: [String: Any] = ["client_id": clientId]
        if let connection {
            params["connection"] = connection
        }
        return Request(session: session,
                       url: url.appending("e/discovery"),
                       method: "GET",
                       handle: decodeDiscoveryResult,
                       parameters: params,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo)
    }

    // MARK: Authorization loop

    /// Starts a new embedded authorization flow, abandoning any flow already in progress.
    func authorize(connection: String,
                   capabilities: [EmbeddedCapability],
                   scope: String = "openid profile email offline_access",
                   audience: String?) -> Request<Void, EmbeddedAuthError> {
        currentSession = nil
        var body: [String: Any] = [
            "client_id": clientId,
            "capabilities": capabilities.map { $0.action.rawValue },
            "connection": connection,
            "scope": scope
        ]
        if let audience { body["audience"] = audience }
        return authorizeRequest(body: body)
    }

    /// Submits a user identifier to continue the authorization flow.
    func identify(_ identifier: String, type: IdentifierType) -> Request<Void, EmbeddedAuthError> {
        switch type {
        case .email:
            guard let currentSession else { return missingSessionRequest() }
            return authorizeRequest(body: [
                "client_id": clientId,
                "action": EmbeddedAction.identifyEmail.rawValue,
                "email": identifier,
                "auth_session": currentSession
            ])
        }
    }

    /// Requests that the server send an email OTP challenge.
    func challengeEmail(index: Int) -> Request<Void, EmbeddedAuthError> {
        guard let currentSession else { return missingSessionRequest() }
        return authorizeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.challengeEmail.rawValue,
            "index": index,
            "auth_session": currentSession
        ])
    }

    /// Submits a one-time password to verify the user's identity.
    /// On success, internally exchanges the authorization code for ``Credentials``.
    func verifyOtp(_ otp: String, type: OtpType) -> Request<Credentials, EmbeddedAuthError> {
        guard let currentSession else { return missingSessionRequest() }
        let body: [String: Any] = [
            "client_id": clientId,
            "action": EmbeddedAction.verifyOTP.rawValue,
            "otp": otp,
            "type": type.rawValue,
            "auth_session": currentSession
        ]
        return Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: { [self] result, callback in decodeVerifyOtpResponse(result, callback: callback) },
            parameters: body,
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

}

// MARK: - Wire types (Decodable)

struct DiscoveryResponse: Decodable {
    let alternatives: [DiscoveryAlternativePayload]
}

struct AuthorizationCodeResponse: Decodable {
    let authorizationCode: String

    enum CodingKeys: String, CodingKey {
        case authorizationCode = "authorization_code"
    }
}

struct DiscoveryAlternativePayload: Decodable {

    let grantType: String
    let connection: String?
    let type: String?
    let subjectTokenType: String?
    let identifierTypes: [String]?
    let realm: String?

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case connection
        case type
        case subjectTokenType = "subject_token_type"
        case identifierTypes = "identifier_types"
        case realm
    }

    var loginOption: LoginOption? {
        switch grantType {
        case GrantTypeValue.authorizationCode:
            return .authorizationCode(connection: connection, type: type)
        case GrantTypeValue.tokenExchange:
            if let subjectTokenType {
                return .nativeSocial(subjectTokenType: subjectTokenType)
            }
        case GrantTypeValue.password:
            return .password
        case GrantTypeValue.webAuthn:
            if let connection {
                return .passkey(connection: connection)
            }
        case GrantTypeValue.passwordlessOTP:
            if let identifierTypes, let connection = connection {
                let identifiers: [PasswordlessIdentifier] = (identifierTypes).compactMap {
                    switch $0 {
                    case IdentifierTypeValue.email:       return .email
                    case IdentifierTypeValue.phoneNumber: return .phoneNumber
                    default:                              return nil
                    }
                }
                return .passwordlessOtp(connection: connection,
                                        identifiers: identifiers,
                                        type: type == TypeValue.auth0 ? .auth0 : .legacy)
            }
        case GrantTypeValue.passwordRealm:
            if let realm {
                return .passwordRealm(realm: realm)
            }
        default:
            return .unknown(rawGrantType: grantType, connection: connection)
        }
        return nil
    }

}

// MARK: - Session state & requests (used cross-file by the response decoders)

extension Auth0EmbeddedAuth {

    /// Builds a `POST /e/authorize` request for an intermediate step of the loop.
    func authorizeRequest(body: [String: Any]) -> Request<Void, EmbeddedAuthError> {
        Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: { [self] result, callback in decodeAuthorizeResponse(result, callback: callback) },
            parameters: body,
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Exchanges the authorization code returned by a completed flow for ``Credentials``.
    func exchange(code: String) -> Request<Credentials, EmbeddedAuthError> {
        Request(
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
            parameters: [
                "client_id": clientId,
                "grant_type": "authorization_code",
                "code": code
            ],
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Updates the flow's session after a step fails.
    ///
    /// - On a continuation (`insufficient_authorization`) the rotated `auth_session` becomes the
    ///   active session so the next step can proceed.
    /// - On a terminal failure (`access_denied`, `too_many_attempts`, or `too_many_logins`) the
    ///   session is cleared so a stray continuation call is rejected locally.
    /// - On any other failure (transient network errors, rate-limits, etc.) the session is left
    ///   untouched so the caller can retry the same step.
    func updateSessionFromFailure(_ error: EmbeddedAuthError) {
        if error.isInsufficientAuthorization, let newSession = error.info["auth_session"] as? String {
            currentSession = newSession
        } else if error.isAccessDenied || error.isTooManyAttempts || error.isTooManyLogins {
            currentSession = nil
        }
    }

}

// MARK: - Private

private extension Auth0EmbeddedAuth {

    func missingSessionRequest<T: Sendable>() -> Request<T, EmbeddedAuthError> {
        Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            requestValidator: [EmbeddedAuthSessionValidator(hasSession: false)],
            handle: { _, callback in
                callback(.failure(EmbeddedAuthError(
                    info: ["error": "no_active_session",
                           "error_description": "No active embedded auth session. Call authorize() first."],
                    statusCode: 0
                )))
            },
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

}
