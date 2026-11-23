import Foundation

// MARK: - Concrete implementation

/// Concrete implementation of ``EmbeddedAuth``.
///
/// Runs the interactive authorization loop (`POST /e/authorize`). Obtain instances via
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

    /// The state of the flow in progress: its rotated `auth_session` and what it revealed about the sign-up password.
    /// `nil` when no flow is active.
    ///
    /// Internal storage only, and not part of the ``EmbeddedAuth`` protocol, so callers cannot read the session. The
    /// flow is strictly sequential — each step starts only after the previous one delivers its result — so this
    /// value is never touched concurrently.
    ///
    /// - Warning: Never call another step while a prior step's network request is still in-flight
    ///   (e.g. retrying `authorize()` inside a loop). A concurrent `exchange(code:)` completion
    ///   will clear the state and overwrite whatever the new `authorize()` established.
    var transactionState: EmbeddedAuthState?

    init(clientId: String,
         url: URL,
         session: URLSession = .shared,
         auth0ClientInfo: Auth0ClientInfo = Auth0ClientInfo()) {
        self.clientId = clientId
        self.url = url
        self.session = session
        self.auth0ClientInfo = auth0ClientInfo
    }

    // MARK: Authorization loop

    /// Starts a new embedded authorization flow, abandoning any flow already in progress.
    func authorize(connection: String,
                   capabilities: [EmbeddedCapability],
                   scope: String = "openid profile email offline_access",
                   audience: String?) -> Request<Void, EmbeddedAuthError> {
        transactionState = nil
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
            guard let authSession = transactionState?.authSession else { return noActiveSession() }
            return authorizeRequest(body: [
                "client_id": clientId,
                "action": EmbeddedAction.identifyEmail.rawValue,
                "email": identifier,
                "auth_session": authSession
            ])
        case .phone:
            guard let authSession = transactionState?.authSession else { return noActiveSession() }
            return authorizeRequest(body: [
                "client_id": clientId,
                "action": EmbeddedAction.identifyPhone.rawValue,
                "phone": identifier,
                "auth_session": authSession
            ])
        case .username:
            guard let authSession = transactionState?.authSession else { return noActiveSession() }
            return authorizeRequest(body: [
                "client_id": clientId,
                "action": EmbeddedAction.identifyUsername.rawValue,
                "username": identifier,
                "auth_session": authSession
            ])
        }
    }

    /// Submits the user's password to verify their identity.
    /// On success, internally exchanges the authorization code for ``Credentials``.
    func verifyPassword(_ password: String) -> Request<Credentials, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: decodeAuthorizationCodeResponse,
            parameters: [
                "client_id": clientId,
                "action": EmbeddedAction.verifyPassword.rawValue,
                "password": password,
                "auth_session": authSession
            ],
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Requests that the server send a phone OTP challenge.
    func challengePhone(index: Int, deliveryMethod: PhoneDeliveryMethod) -> Request<Void, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return authorizeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.challengePhone.rawValue,
            "index": index,
            "delivery_method": deliveryMethod.rawValue,
            "auth_session": authSession
        ])
    }

    /// Requests that the server send a push notification to the user's enrolled device.
    func challengePush(index: Int) -> Request<Void, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return authorizeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.challengePush.rawValue,
            "index": index,
            "auth_session": authSession
        ])
    }

    /// Polls for push notification approval.
    func verifyOob() -> Request<Credentials, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: decodeAuthorizationCodeResponse,
            parameters: [
                "client_id": clientId,
                "action": EmbeddedAction.verifyOob.rawValue,
                "auth_session": authSession
            ],
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Submits a recovery code to verify the user's identity.
    func verifyRecoveryCode(_ code: String) -> Request<Void, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return authorizeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.verifyRecoveryCode.rawValue,
            "code": code,
            "auth_session": authSession
        ])
    }

    /// Confirms the user has recorded their rotated recovery code.
    func confirmRecoveryCode() -> Request<Credentials, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: decodeAuthorizationCodeResponse,
            parameters: [
                "client_id": clientId,
                "action": EmbeddedAction.confirmRecoveryCode.rawValue,
                "auth_session": authSession
            ],
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Starts registering a new user. Always fails with a continuation.
    func signup() -> Request<Void, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return authorizeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.signup.rawValue,
            "auth_session": authSession
        ])
    }

    /// Confirms the registration, optionally with a password for the new account.
    /// On success, internally exchanges the authorization code for ``Credentials``.
    ///
    /// The password is only placed in the request body: it is never stored on the client.
    func confirmSignup(password: String?) -> Request<Credentials, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        var body: [String: Any] = [
            "client_id": clientId,
            "action": EmbeddedAction.confirmSignup.rawValue,
            "auth_session": authSession
        ]
        if let password { body["password"] = password }
        return Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: decodeAuthorizationCodeResponse,
            parameters: body,
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Requests that the server send an email OTP challenge.
    func challengeEmail(index: Int) -> Request<Void, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return authorizeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.challengeEmail.rawValue,
            "index": index,
            "auth_session": authSession
        ])
    }

    /// Submits a one-time password to verify the user's identity.
    /// On success, internally exchanges the authorization code for ``Credentials``.
    func verifyOtp(_ otp: String, type: OtpType) -> Request<Credentials, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        let body: [String: Any] = [
            "client_id": clientId,
            "action": EmbeddedAction.verifyOTP.rawValue,
            "otp": otp,
            "type": type.rawValue,
            "auth_session": authSession
        ]
        return Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: decodeAuthorizationCodeResponse,
            parameters: body,
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

}

// MARK: - Wire types (Decodable)

struct AuthorizationCodeResponse: Decodable {
    let authorizationCode: String

    enum CodingKeys: String, CodingKey {
        case authorizationCode = "authorization_code"
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
            handle: decodeAuthorizeResponse,
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

    /// Updates the flow's state after a step fails, and returns the error to deliver.
    ///
    /// - On a continuation (`.insufficientAuthorization`) the rotated `auth_session` becomes the active session so the
    ///   next step can proceed. The password requirement of a sign-up is remembered from the sign-up offer, or from a
    ///   `password_required` answer, and used to correct ``SignupPassword/isRequired`` on the error's
    ///   ``NextAction/confirmSignup(password:)``, because the server does not repeat it at the confirm step.
    /// - On a network failure (`.network`) the state is preserved so the caller can retry the same step.
    /// - On all other failures the state is cleared; any follow-on step will fail locally with `.noActiveSession`.
    func updateSessionFromFailure(_ error: EmbeddedAuthError) -> EmbeddedAuthError {
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
            transactionState = EmbeddedAuthState(authSession: authSession, passwordRequirement: requirement)
            return actions == nextActions ? error : error.withNextActions(actions)
        case .network:
            return error
        default:
            transactionState = nil
            return error
        }
    }
}

// MARK: - Private

private extension Auth0EmbeddedAuth {

    func noActiveSession<T: Sendable>() -> Request<T, EmbeddedAuthError> {
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

private extension NextAction {

    /// This action with the password flag of a ``NextAction/confirmSignup(password:)`` set to `isRequired`. Any other
    /// action is returned as is.
    func withRequired(_ isRequired: Bool) -> NextAction {
        guard case .confirmSignup(let password?) = self else { return self }
        return .confirmSignup(password: SignupPassword(isRequired: isRequired, complexity: password.complexity))
    }

}
