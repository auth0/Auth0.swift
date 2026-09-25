import Foundation

// MARK: - Concrete implementation

/// Concrete implementation of ``EmbeddedAuth``.
///
/// Handles both discovery (`GET /e/discovery`) and the interactive authorization
/// loop (`POST /e/authorize`). Obtain instances via
/// ``Auth0/embeddedAuth(clientId:domain:session:)`` or ``Auth0/embeddedAuth(session:bundle:)``.
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

    private let lock = NSLock()
    private var _authSession: String?
    /// True once `authorize()` has been called and the flow has not yet completed (200) or been reset.
    private var _sessionActive: Bool = false

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

    /// Starts a new embedded authorization flow.
    func authorize(connection: String,
                   capabilities: [EmbeddedCapability],
                   scope: String?,
                   audience: String?) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        markSessionActive()
        var body: [String: Any] = [
            "client_id": clientId,
            "capabilities": capabilities.map { $0.action.rawValue },
            "connection": connection
        ]
        if let scope { body["scope"] = scope }
        if let audience { body["audience"] = audience }
        return Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: { [weak self] result, callback in
                guard let self else { return }
                self.decodeAuthorizeResponse(result, callback: callback)
            },
            parameters: body,
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Submits an email address as the user's identifier.
    func identifyEmail(_ email: String) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        guard sessionActive, let activeSession = authSession else { return missingSessionRequest() }
        let body: [String: Any] = [
            "client_id": clientId,
            "action": EmbeddedAction.identifyEmail.rawValue,
            "email": email,
            "auth_session": activeSession
        ]
        return Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: { [weak self] result, callback in
                guard let self else { return }
                self.decodeAuthorizeResponse(result, callback: callback)
            },
            parameters: body,
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Submits a phone number as the user's identifier.
    func identifyPhone(_ phone: String) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        guard sessionActive, let activeSession = authSession else { return missingSessionRequest() }
        let body: [String: Any] = [
            "client_id": clientId,
            "action": EmbeddedAction.identifyPhone.rawValue,
            "phone": phone,
            "auth_session": activeSession
        ]
        return Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: { [weak self] result, callback in
                guard let self else { return }
                self.decodeAuthorizeResponse(result, callback: callback)
            },
            parameters: body,
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Requests that the server send an email OTP challenge.
    func challengeEmail(index: Int) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        guard sessionActive, let activeSession = authSession else { return missingSessionRequest() }
        let body: [String: Any] = [
            "client_id": clientId,
            "action": EmbeddedAction.challengeEmail.rawValue,
            "index": index,
            "auth_session": activeSession
        ]
        return Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: { [weak self] result, callback in
                guard let self else { return }
                self.decodeAuthorizeResponse(result, callback: callback)
            },
            parameters: body,
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Submits a one-time password to verify the user's identity.
    /// On success, internally exchanges the authorization code for ``Credentials``.
    func verifyOtp(_ otp: String, type: OtpType) -> Request<Credentials, EmbeddedAuthError> {
        guard sessionActive, let activeSession = authSession else { return missingCredentialsSessionRequest() }
        let body: [String: Any] = [
            "client_id": clientId,
            "action": EmbeddedAction.verifyOTP.rawValue,
            "otp": otp,
            "type": type.rawValue,
            "auth_session": activeSession
        ]
        return Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: { [weak self] result, callback in
                guard let self else { return }
                self.decodeVerifyOtpResponse(result, callback: callback)
            },
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

// MARK: - Session state (accessed cross-file by the response decoders)

extension Auth0EmbeddedAuth {

    func setAuthSession(_ value: String?) {
        lock.withLock {
            _authSession = value
            if value == nil { _sessionActive = false }
        }
    }

    /// Exchanges an authorization code for Credentials by calling `POST /oauth/token`.
    ///
    /// Blocks the calling thread until the response arrives. This is called from within the
    /// `verifyOtp` request's completion handler, which runs on `session`'s serial delegate
    /// queue. To avoid deadlocking that queue, the nested exchange runs on a **dedicated**
    /// `URLSession` (cloned from `session.configuration`, so it keeps any custom protocol
    /// classes) that has its own delegate queue — the two completions never contend.
    func exchangeCodeSynchronously(_ code: String) -> Result<Credentials, EmbeddedAuthError> {
        let semaphore = DispatchSemaphore(value: 0)
        // `nonisolated(unsafe)` is sound here: the completion handler writes `exchangeResult`
        // exactly once and always before `signal()`, and this method reads it only after
        // `wait()` returns — the semaphore establishes the happens-before ordering.
        nonisolated(unsafe) var exchangeResult: Result<Credentials, EmbeddedAuthError> = .failure(
            EmbeddedAuthError(info: [:], statusCode: 0)
        )

        let tokenURL = url.appending("oauth/token")
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "code": code,
            "code_verifier": "",
            "redirect_uri": ""
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        let exchangeSession = URLSession(configuration: session.configuration)
        defer { exchangeSession.finishTasksAndInvalidate() }

        exchangeSession.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            if let error {
                exchangeResult = .failure(EmbeddedAuthError(
                    info: ["error": "network_error", "error_description": error.localizedDescription],
                    statusCode: 0
                ))
                return
            }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard statusCode == 200, let data else {
                let info: [String: Any]
                if let data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    info = json
                } else {
                    info = [:]
                }
                exchangeResult = .failure(EmbeddedAuthError(info: info, statusCode: statusCode))
                return
            }
            do {
                exchangeResult = .success(try JSONDecoder().decode(Credentials.self, from: data))
            } catch {
                exchangeResult = .failure(EmbeddedAuthError(info: [:], statusCode: statusCode))
            }
        }.resume()

        semaphore.wait()
        return exchangeResult
    }

}

// MARK: - Private

private extension Auth0EmbeddedAuth {

    var authSession: String? {
        lock.withLock { _authSession }
    }

    var sessionActive: Bool {
        lock.withLock { _sessionActive }
    }

    func markSessionActive() {
        lock.withLock { _sessionActive = true }
    }

    func missingSessionRequest() -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
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

    func missingCredentialsSessionRequest() -> Request<Credentials, EmbeddedAuthError> {
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
