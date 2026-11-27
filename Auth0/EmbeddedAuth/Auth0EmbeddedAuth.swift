// swiftlint:disable file_length

import Foundation

// MARK: - Concrete implementation

/// Concrete implementation of ``EmbeddedAuth``.
///
/// Runs the interactive authorization loop (`POST /e/authorize`). Obtain instances via
/// ``Auth0/embeddedAuth(clientId:domain:session:)`` or ``Auth0/embeddedAuth(session:bundle:)``.
///
/// A client tracks a single in-progress flow: calling ``authorize(connection:capabilities:scope:audience:)``
/// again abandons any previous one, so a new sign-in never reuses a stale session or PKCE verifier.
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

    /// The state of the flow in progress: its rotated `auth_session`, the PKCE `code_verifier` and what the flow revealed
    /// about the sign-up password. `nil` when no flow is active.
    ///
    /// Internal storage only, and not part of the ``EmbeddedAuth`` protocol, so callers cannot read the session or the
    /// verifier. The flow is strictly sequential — each step starts only after the previous one delivers its result —
    /// so this value is never touched concurrently.
    ///
    /// - Warning: Never call another step while a prior step's network request is still in-flight
    ///   (e.g. retrying `authorize()` inside a loop). A concurrent `exchange(code:verifier:)` completion
    ///   will clear the state, session and verifier, and undo whatever the new `authorize()` established.
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
        let pkce = ChallengeGenerator()
        var body: [String: Any] = [
            "client_id": clientId,
            "capabilities": capabilities.map { $0.action.rawValue },
            "connection": connection,
            "scope": scope,
            "code_challenge": pkce.challenge,
            "code_challenge_method": pkce.method
        ]
        if let audience { body["audience"] = audience }
        return authorizeRequest(body: body, verifier: pkce.verifier)
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
        return authorizationCodeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.verifyPassword.rawValue,
            "password": password,
            "auth_session": authSession
        ], verifier: transactionState?.verifier)
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
        return authorizationCodeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.verifyOob.rawValue,
            "auth_session": authSession
        ], verifier: transactionState?.verifier)
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
        return authorizationCodeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.confirmRecoveryCode.rawValue,
            "auth_session": authSession
        ], verifier: transactionState?.verifier)
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
        return authorizationCodeRequest(body: body, verifier: transactionState?.verifier)
    }

    #if PASSKEYS_PLATFORM
    /// Submits a passkey assertion to sign the user in.
    /// On success, internally exchanges the authorization code for ``Credentials``.
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func verifyPasskey(_ passkey: any LoginPasskey) -> Request<Credentials, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        let assertion: [String: Any]
        do {
            assertion = try Self.passkeyAssertion(from: passkey)
        } catch let error as PasskeyInputError {
            return invalidInputRequest(message: error.message)
        } catch {
            return invalidInputRequest(message: "This passkey can't be used.")
        }
        return authorizationCodeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.verifyPasskey.rawValue,
            "auth_session": authSession,
            "authn_response": assertion
        ], verifier: transactionState?.verifier)
    }
    #endif

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
        return authorizationCodeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.verifyOTP.rawValue,
            "otp": otp,
            "type": type.rawValue,
            "auth_session": authSession
        ], verifier: transactionState?.verifier)
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

// MARK: - Local failures

extension Auth0EmbeddedAuth {

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

#if PASSKEYS_PLATFORM

// MARK: - Passkey assertion

extension Auth0EmbeddedAuth {

    /// Maps a passkey to the `authn_response` object, with only the fields the server accepts, base64url-encoded.
    ///
    /// `clientExtensionResults` is always empty: the SDK requests no WebAuthn extension, so there is nothing to forward.
    /// It is sent anyway, as a browser does, so that the server can start to use extensions without a new SDK version.
    ///
    /// Max lengths are not checked here: the server decides.
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    static func passkeyAssertion(from passkey: any LoginPasskey) throws -> [String: Any] {
        guard let userID = passkey.userID, !userID.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no user handle. Only discoverable passkeys are supported.")
        }
        let credentialID = passkey.credentialID
        guard !credentialID.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no credential ID.")
        }
        let clientData = passkey.rawClientDataJSON
        guard !clientData.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no client data.")
        }
        guard let authenticatorData = passkey.rawAuthenticatorData, !authenticatorData.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no authenticator data.")
        }
        guard let signature = passkey.signature, !signature.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no signature.")
        }

        let id = credentialID.encodeBase64URLSafe()
        var assertion: [String: Any] = [
            "id": id,
            "rawId": id,
            "type": "public-key",
            "clientExtensionResults": [String: Any](),
            "response": [
                "clientDataJSON": clientData.encodeBase64URLSafe(),
                "authenticatorData": authenticatorData.encodeBase64URLSafe(),
                "signature": signature.encodeBase64URLSafe(),
                "userHandle": userID.encodeBase64URLSafe()
            ]
        ]
        if let attachment = passkey.attachment.stringValue {
            assertion["authenticatorAttachment"] = attachment
        }
        return assertion
    }

    /// Fails the request locally because the input is not valid: nothing is sent and the session is kept.
    ///
    /// The message must never contain secrets such as passkey data.
    func invalidInputRequest<T: Sendable>(message: String) -> Request<T, EmbeddedAuthError> {
        Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            requestValidator: [EmbeddedAuthInputValidator(message: message)],
            handle: { _, callback in
                callback(.failure(EmbeddedAuthError(
                    info: ["error": "invalid_input", "error_description": message],
                    statusCode: 0
                )))
            },
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

}

#endif

private extension NextAction {

    /// This action with the password flag of a ``NextAction/confirmSignup(password:)`` set to `isRequired`. Any other
    /// action is returned as is.
    func withRequired(_ isRequired: Bool) -> NextAction {
        guard case .confirmSignup(let password?) = self else { return self }
        return .confirmSignup(password: SignupPassword(isRequired: isRequired, complexity: password.complexity))
    }

}
