import Foundation

// MARK: - Concrete implementation

/// Concrete implementation of ``EmbeddedAuthClient``.
///
/// Obtain instances via ``Auth0/embeddedAuthClient(clientId:domain:session:)``
/// or ``Auth0/embeddedAuthClient(session:bundle:)``.
final class Auth0EmbeddedAuthClient: EmbeddedAuthClient, @unchecked Sendable {

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

    // MARK: Protocol conformance

    /// Starts a new embedded authorization flow.
    func authorize(connection: String?,
                   capabilities: [EmbeddedCapability],
                   scope: String?,
                   audience: String?) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        markSessionActive()
        var body: [String: Any] = [
            "client_id": clientId,
            "capabilities": capabilities.map { $0.action.rawValue }
        ]
        if let connection { body["connection"] = connection }
        if let scope      { body["scope"]      = scope      }
        if let audience   { body["audience"]   = audience   }
        return buildAuthorizeRequest(body: body)
    }

    /// Submits an email address as the user's identifier.
    func identifyEmail(_ email: String) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        guard sessionActive else { return missingSessionRequest() }
        var body: [String: Any] = [
            "client_id": clientId,
            "action": EmbeddedAction.identifyEmail.rawValue,
            "email": email
        ]
        if let s = authSession { body["auth_session"] = s }
        return buildAuthorizeRequest(body: body)
    }

    /// Submits a phone number as the user's identifier.
    func identifyPhone(_ phone: String) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        guard sessionActive else { return missingSessionRequest() }
        var body: [String: Any] = [
            "client_id": clientId,
            "action": EmbeddedAction.identifyPhone.rawValue,
            "phone": phone
        ]
        if let s = authSession { body["auth_session"] = s }
        return buildAuthorizeRequest(body: body)
    }

    /// Requests that the server send an email OTP challenge.
    func challengeEmail() -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        guard sessionActive else { return missingSessionRequest() }
        var body: [String: Any] = [
            "client_id": clientId,
            "action": EmbeddedAction.challengeEmail.rawValue,
            "index": 0
        ]
        if let s = authSession { body["auth_session"] = s }
        return buildAuthorizeRequest(body: body)
    }

    /// Submits a one-time password to verify the user's identity.
    func verifyOtp(_ otp: String, type: OtpType) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        guard sessionActive else { return missingSessionRequest() }
        var body: [String: Any] = [
            "client_id": clientId,
            "action": EmbeddedAction.verifyOTP.rawValue,
            "otp": otp,
            "type": type.rawValue
        ]
        if let s = authSession { body["auth_session"] = s }
        return buildAuthorizeRequest(body: body)
    }

}

// MARK: - Private

private extension Auth0EmbeddedAuthClient {

    var authSession: String? {
        lock.withLock { _authSession }
    }

    var sessionActive: Bool {
        lock.withLock { _sessionActive }
    }

    func markSessionActive() {
        lock.withLock { _sessionActive = true }
    }

    func setAuthSession(_ value: String?) {
        lock.withLock {
            _authSession = value
            if value == nil { _sessionActive = false }
        }
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

    func buildAuthorizeRequest(body: [String: Any]) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        let endpoint = url.appending("e/authorize")
        return Request(
            session: session,
            url: endpoint,
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

}
