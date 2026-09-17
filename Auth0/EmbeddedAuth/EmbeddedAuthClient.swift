import Foundation

// MARK: - Protocol

/// Client for the Embedded Authorization loop (`POST /e/authorize`).
///
/// Obtain an instance via ``Auth0/embeddedAuthClient(clientId:domain:session:)`` or
/// ``Auth0/embeddedAuthClient(session:bundle:)``.
///
/// ## Usage
///
/// ```swift
/// let client = Auth0.embeddedAuthClient()
/// let authentication = Auth0.authentication()
///
/// // 1. Start the flow
/// do {
///     let code = try await client.authorize().start()
///     // exchange code — but this step never succeeds on the first call
/// } catch let error as EmbeddedAuthError where error.isInsufficientAuthorization {
///     // nextActions tells you which step to present
/// }
///
/// // 2–N. Continue until you receive EmbeddedAuthorizationCode
/// let code = try await client.verifyOtp("123456", type: .oob).start()
///
/// // N+1. Exchange code for Credentials
/// let credentials = try await authentication.codeExchange(withCode: code.code,
///                                                         codeVerifier: "",
///                                                         redirectURI: "").start()
/// ```
///
/// ## See Also
/// - ``EmbeddedAuthError``
/// - ``NextAction``
/// - ``EmbeddedAuthorizationCode``
public protocol EmbeddedAuthClient: Trackable, Loggable, Sendable {

    /// Starts a new embedded authorization flow.
    ///
    /// Calls `POST /e/authorize` with `capabilities` advertised.
    /// Always throws ``EmbeddedAuthError`` with ``EmbeddedAuthError/isInsufficientAuthorization`` `true`
    /// on the first call; read ``EmbeddedAuthError/nextActions`` to determine which step to present.
    ///
    /// - Parameters:
    ///   - connection:   Optional connection name to target a specific connection.
    ///   - capabilities: Actions this SDK version supports. Defaults to ``EmbeddedCapability/all``.
    ///   - scope:        Optional OAuth scope string.
    ///   - audience:     Optional API audience.
    func authorize(connection: String?,
                   capabilities: [EmbeddedCapability],
                   scope: String?,
                   audience: String?) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError>

    /// Submits an email address as the user's identifier.
    ///
    /// Requires an active session (``authorize(connection:capabilities:scope:audience:)`` must have been called first).
    /// - Parameter email: The email address to identify with.
    func identifyEmail(_ email: String) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError>

    /// Submits a phone number as the user's identifier.
    ///
    /// Requires an active session.
    /// - Parameter phone: The phone number to identify with.
    func identifyPhone(_ phone: String) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError>

    /// Requests that the server send an email OTP challenge.
    ///
    /// Requires an active session.
    /// - Parameter index: Index of the challenge target in the `next` menu (defaults to `0`).
    func challengeEmail(index: Int) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError>

    /// Submits a one-time password to verify the user's identity.
    ///
    /// On success, returns ``EmbeddedAuthorizationCode`` which the caller should exchange for ``Credentials``
    /// via ``Authentication/codeExchange(withCode:codeVerifier:redirectURI:)``.
    ///
    /// Requires an active session.
    ///
    /// - Parameters:
    ///   - otp:  The one-time code entered by the user.
    ///   - type: Whether the code is OOB (email/SMS) or TOTP.
    func verifyOtp(_ otp: String, type: OtpType) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError>

}

// MARK: - Default overloads

public extension EmbeddedAuthClient {

    /// Starts a new embedded authorization flow using all default capabilities and no connection filter.
    func authorize() -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        authorize(connection: nil, capabilities: EmbeddedCapability.all, scope: nil, audience: nil)
    }

    /// Starts a new embedded authorization flow targeting a specific connection.
    func authorize(connection: String) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        authorize(connection: connection, capabilities: EmbeddedCapability.all, scope: nil, audience: nil)
    }

    /// Requests an email OTP challenge targeting the first entry in the `next` menu.
    func challengeEmail() -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        challengeEmail(index: 0)
    }

}

// MARK: - Factory

/// Embedded Authorization client.
///
/// ## Usage
///
/// ```swift
/// Auth0.embeddedAuthClient(clientId: "client-id", domain: "samples.us.auth0.com")
/// ```
///
/// - Parameters:
///   - clientId: Client ID of your Auth0 application.
///   - domain:   Domain of your Auth0 tenant, for example `samples.us.auth0.com`.
///   - session:  `URLSession` instance used for networking. Defaults to `URLSession.shared`.
/// - Returns: An ``EmbeddedAuthClient`` instance.
public func embeddedAuthClient(clientId: String, domain: String, session: URLSession = .shared) -> EmbeddedAuthClient {
    Auth0EmbeddedAuthClient(clientId: clientId, url: .httpsURL(from: domain), session: session)
}

/// Embedded Authorization client, reading credentials from `Auth0.plist`.
///
/// ## Usage
///
/// ```swift
/// Auth0.embeddedAuthClient()
/// ```
///
/// - Parameters:
///   - session: `URLSession` instance used for networking. Defaults to `URLSession.shared`.
///   - bundle:  Bundle used to locate `Auth0.plist`. Defaults to `Bundle.main`.
/// - Returns: An ``EmbeddedAuthClient`` instance.
/// - Warning: Calling this method without a valid `Auth0.plist` will crash your application.
public func embeddedAuthClient(session: URLSession = .shared, bundle: Bundle = .main) -> EmbeddedAuthClient {
    let values = plistValues(bundle: bundle)!
    return embeddedAuthClient(clientId: values.clientId, domain: values.domain, session: session)
}
