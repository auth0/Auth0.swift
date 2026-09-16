import Foundation

// MARK: - Result alias

/// `Result` wrapper for Embedded Login operations.
public typealias EmbeddedAuthResult<T> = Result<T, EmbeddedAuthError>

// MARK: - Protocol

/// Client for the Embedded Login Discovery API.
///
/// Obtain an instance via ``Auth0/embeddedAuth(clientId:domain:session:)`` or
/// ``Auth0/embeddedAuth(session:bundle:)``.
///
/// ## Usage
///
/// ```swift
/// let result = try await Auth0.embeddedAuth().discover().start()
/// ```
///
/// ## See Also
/// - ``DiscoveryResult``
/// - ``EmbeddedAuthError``
public protocol EmbeddedAuth: Trackable, Loggable, Sendable {

    /// Fetches the live set of login alternatives for this client.
    ///
    /// Calls `GET /e/discovery?client_id=<id>[&connection=<name>]`.
    ///
    /// - Parameter connection: Optional connection name to filter results to a single connection.
    ///   Pass `nil` (the default) to retrieve all alternatives (up to 100).
    /// - Returns: A request that yields a ``DiscoveryResult``.
    func discover(connection: String?) -> Request<DiscoveryResult, EmbeddedAuthError>

}

public extension EmbeddedAuth {

    /// Fetches all live login alternatives for this client (no connection filter).
    func discover() -> Request<DiscoveryResult, EmbeddedAuthError> {
        discover(connection: nil)
    }

}

// MARK: - Factory

/// Embedded Login Discovery client.
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
/// - Returns: Embedded Login Discovery client.
public func embeddedAuth(clientId: String,
                         domain: String,
                         session: URLSession = .shared) -> EmbeddedAuth {
    Auth0EmbeddedAuth(clientId: clientId,
                      url: .httpsURL(from: domain),
                      session: session)
}

/// Embedded Login Discovery client.
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
/// - Returns: Embedded Login Discovery client.
/// - Warning: Calling this method without a valid `Auth0.plist` file will crash your application.
public func embeddedAuth(session: URLSession = .shared, bundle: Bundle = .main) -> EmbeddedAuth {
    let values = plistValues(bundle: bundle)!
    return embeddedAuth(clientId: values.clientId, domain: values.domain, session: session)
}
