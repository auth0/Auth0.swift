import Foundation

// MARK: - Result alias

/// `Result` wrapper for Embedded Login operations.
public typealias EmbeddedAuthResult<T> = Result<T, EmbeddedAuthError>

// MARK: - Protocol

/// Client for Embedded Login, covering both discovery (`GET /e/discovery`) and the
/// interactive authorization loop (`POST /e/authorize`).
///
/// Obtain an instance via ``Auth0/embeddedAuth(clientId:domain:session:)`` or
/// ``Auth0/embeddedAuth(session:bundle:)``.
///
/// ## Usage
///
/// ```swift
/// let client = Auth0.embeddedAuth()
///
/// // Discover the available login options
/// let discovery = try await client.discover().start()
///
/// // Or drive the authorization loop
/// do {
///     _ = try await client.authorize(connection: "my-connection").start()
/// } catch let error as EmbeddedAuthError where error.isInsufficientAuthorization {
///     // error.nextActions tells you which step to present
/// }
/// let credentials = try await client.verifyOtp("123456", type: .oob).start()
/// ```
///
/// ## See Also
/// - ``DiscoveryResult``
/// - ``EmbeddedAuthError``
/// - ``NextAction``
public protocol EmbeddedAuth: Trackable, Loggable, Sendable {

    /// Fetches the live set of login alternatives for this client.
    ///
    /// Calls `GET /e/discovery?client_id=<id>[&connection=<name>]`.
    ///
    /// - Parameter connection: Optional connection name to filter results to a single connection.
    ///   Pass `nil` (the default) to retrieve all alternatives.
    /// - Returns: A request that yields a ``DiscoveryResult``.
    func discover(connection: String?) -> Request<DiscoveryResult, EmbeddedAuthError>

    /// Starts a new embedded authorization flow.
    ///
    /// Calls `POST /e/authorize` with `capabilities` advertised.
    /// Always throws ``EmbeddedAuthError`` with ``EmbeddedAuthError/isInsufficientAuthorization`` `true`
    /// on the first call; read ``EmbeddedAuthError/nextActions`` to determine which step to present.
    ///
    /// - Parameters:
    ///   - connection:   Connection name to target. Required by the server — a missing value yields `invalid_request`.
    ///   - capabilities: Actions this SDK version supports. Defaults to ``EmbeddedCapability/all``.
    ///   - scope:        Optional OAuth scope string.
    ///   - audience:     Optional API audience.
    func authorize(connection: String,
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
    /// - Parameter index: The zero-based index of the `challengeEmail` entry from ``EmbeddedAuthError/nextActions``.
    func challengeEmail(index: Int) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError>

    /// Submits a one-time password to verify the user's identity.
    ///
    /// On success, exchanges the returned authorization code for ``Credentials`` internally and returns them directly.
    ///
    /// Requires an active session.
    ///
    /// - Parameters:
    ///   - otp:  The one-time code entered by the user.
    ///   - type: Whether the code is OOB (email/SMS) or TOTP.
    func verifyOtp(_ otp: String, type: OtpType) -> Request<Credentials, EmbeddedAuthError>

}

public extension EmbeddedAuth {

    /// Fetches all live login alternatives for this client (no connection filter).
    func discover() -> Request<DiscoveryResult, EmbeddedAuthError> {
        discover(connection: nil)
    }

    /// Starts a new embedded authorization flow targeting the given connection using all default capabilities.
    func authorize(connection: String) -> Request<EmbeddedAuthorizationCode, EmbeddedAuthError> {
        authorize(connection: connection, capabilities: EmbeddedCapability.all, scope: nil, audience: nil)
    }

}

// MARK: - Factory

/// Embedded Login client.
///
/// ## Usage
///
/// ```swift
/// Auth0.embeddedAuth(clientId: "client-id", domain: "samples.us.auth0.com")
/// ```
///
/// - Parameters:
///   - clientId: Client ID of your Auth0 application.
///   - domain:   Domain of your Auth0 account, for example `samples.us.auth0.com`.
///   - session:  `URLSession` instance used for networking. Defaults to `URLSession.shared`.
/// - Returns: Embedded Login client.
public func embeddedAuth(clientId: String,
                         domain: String,
                         session: URLSession = .shared) -> EmbeddedAuth {
    Auth0EmbeddedAuth(clientId: clientId,
                      url: .httpsURL(from: domain),
                      session: session)
}

/// Embedded Login client.
///
/// The Auth0 Client ID & Domain are loaded from the `Auth0.plist` file in your main bundle.
///
/// ## Usage
///
/// ```swift
/// Auth0.embeddedAuth()
/// ```
///
/// - Parameters:
///   - session: `URLSession` instance used for networking. Defaults to `URLSession.shared`.
///   - bundle:  Bundle used to locate the `Auth0.plist` file. Defaults to `Bundle.main`.
/// - Returns: Embedded Login client.
/// - Warning: Calling this method without a valid `Auth0.plist` file will crash your application.
public func embeddedAuth(session: URLSession = .shared, bundle: Bundle = .main) -> EmbeddedAuth {
    let values = plistValues(bundle: bundle)!
    return embeddedAuth(clientId: values.clientId, domain: values.domain, session: session)
}
