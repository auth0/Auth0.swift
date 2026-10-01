import Foundation

// MARK: - Result alias

/// `Result` wrapper for Embedded Login operations.
public typealias EmbeddedAuthResult<T> = Result<T, EmbeddedAuthError>

// MARK: - IdentifierType

/// The type of identifier a user submits during the identify step.
public enum IdentifierType {
    /// An email address.
    case email
}

// MARK: - Protocol

/// Client for Embedded Login's interactive authorization loop (`POST /e/authorize`).
///
/// Obtain an instance via ``Auth0/embeddedAuth(clientId:domain:session:)`` or
/// ``Auth0/embeddedAuth(session:bundle:)``.
///
/// ## Usage
///
/// ```swift
/// let client = Auth0.embeddedAuth()
///
/// // Drive the authorization loop
/// do {
///     try await client.authorize(connection: "my-connection").start()
/// } catch let error as EmbeddedAuthError {
///     if case .insufficientAuthorization(let nextActions) = error.kind {
///         // nextActions tells you which step to present
///     }
/// }
/// let credentials = try await client.verifyOtp("123456", type: .oob).start()
/// ```
///
/// ## See Also
/// - ``EmbeddedAuthError``
/// - ``NextAction``
public protocol EmbeddedAuth: Trackable, Loggable, Sendable {

    /// Starts a new embedded authorization flow.
    ///
    /// Calls `POST /e/authorize` with `capabilities` advertised.
    /// Always throws ``EmbeddedAuthError`` with ``EmbeddedAuthError/kind`` equal to
    /// ``EmbeddedAuthErrorKind/insufficientAuthorization(nextActions:)``
    /// on the first call; read its associated `nextActions` to determine which step to present.
    ///
    /// - Parameters:
    ///   - connection:   Connection name to target.
    ///   - capabilities: Actions this SDK version supports. Defaults to ``EmbeddedCapability/all``.
    ///   - scope:        OAuth scope string. Defaults to `"openid profile email offline_access"`.
    ///   - audience:     Optional API audience.
    func authorize(connection: String,
                   capabilities: [EmbeddedCapability],
                   scope: String,
                   audience: String?) -> Request<Void, EmbeddedAuthError>

    /// Submits a user identifier to continue the authorization flow.
    ///
    /// Requires an active session (``authorize(connection:capabilities:scope:audience:)`` must have been called first).
    /// - Parameters:
    ///   - identifier: The identifier value (e.g. an email address).
    ///   - type: The type of identifier being submitted.
    func identify(_ identifier: String, type: IdentifierType) -> Request<Void, EmbeddedAuthError>

    /// Requests that the server send an email OTP challenge.
    ///
    /// Requires an active session.
    /// - Parameter index: The zero-based index of the `challengeEmail` entry from the
    ///   `nextActions` associated value of ``EmbeddedAuthErrorKind/insufficientAuthorization(nextActions:)``.
    func challengeEmail(index: Int) -> Request<Void, EmbeddedAuthError>

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

    /// Starts a new embedded authorization flow targeting the given connection using all default capabilities and the default scope.
    func authorize(connection: String) -> Request<Void, EmbeddedAuthError> {
        authorize(connection: connection,
                  capabilities: EmbeddedCapability.all,
                  scope: "openid profile email offline_access",
                  audience: nil)
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
