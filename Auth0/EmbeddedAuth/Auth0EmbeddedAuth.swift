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

    func verifyPassword(_ password: String) -> Request<Credentials, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return authorizationCodeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.verifyPassword.rawValue,
            "password": password,
            "auth_session": authSession
        ], verifier: transactionState?.verifier)
    }

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

    func challengePush(index: Int) -> Request<Void, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return authorizeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.challengePush.rawValue,
            "index": index,
            "auth_session": authSession
        ])
    }

    func verifyOob() -> Request<Credentials, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return authorizationCodeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.verifyOob.rawValue,
            "auth_session": authSession
        ], verifier: transactionState?.verifier)
    }

    func verifyRecoveryCode(_ code: String) -> Request<Void, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return authorizeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.verifyRecoveryCode.rawValue,
            "code": code,
            "auth_session": authSession
        ])
    }

    func confirmRecoveryCode() -> Request<Credentials, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return authorizationCodeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.confirmRecoveryCode.rawValue,
            "auth_session": authSession
        ], verifier: transactionState?.verifier)
    }

    func signup() -> Request<Void, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return authorizeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.signup.rawValue,
            "auth_session": authSession
        ])
    }

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
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func verifyPasskey(_ passkey: any LoginPasskey) -> Request<Credentials, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        let assertion: [String: Any]
        do {
            assertion = try passkeyAssertion(from: passkey)
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

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func confirmSignup(passkey: any SignupPasskey) -> Request<Credentials, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        let registration: [String: Any]
        do {
            registration = try passkeyRegistration(from: passkey)
        } catch let error as PasskeyInputError {
            return invalidInputRequest(message: error.message)
        } catch {
            return invalidInputRequest(message: "This passkey can't be used.")
        }
        return authorizationCodeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.confirmSignup.rawValue,
            "auth_session": authSession,
            "passkey": registration
        ], verifier: transactionState?.verifier)
    }
    #endif

    func challengeEmail(index: Int) -> Request<Void, EmbeddedAuthError> {
        guard let authSession = transactionState?.authSession else { return noActiveSession() }
        return authorizeRequest(body: [
            "client_id": clientId,
            "action": EmbeddedAction.challengeEmail.rawValue,
            "index": index,
            "auth_session": authSession
        ])
    }

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
