#if WEB_AUTH_PLATFORM
import Foundation
import Combine

/// Web-based PAR (Pushed Authorization Request) authorization.
///
/// Handles the browser authorization step of a PAR flow — opens the `/authorize` endpoint
/// with a `request_uri` obtained from your backend's PAR endpoint call, and returns the
/// authorization code for your backend to exchange for tokens.
///
/// ## See Also
///
/// - ``AuthorizationCode``
/// - ``WebAuthError``
/// - ``PARWebAuth``
public protocol PARAuth: Trackable, Sendable {

    /// The Auth0 Client ID.
    var clientId: String { get }

    /// The Auth0 Domain URL.
    var url: URL { get }

    // MARK: - Builder Methods

    /// Provide a session transfer token to be passed as a query parameter to the `/authorize` endpoint.
    /// This enables web single sign-on by transferring an existing session to the browser.
    ///
    /// - Parameter token: The session transfer token obtained from ``Authentication/ssoExchange(refreshToken:parameters:headers:)``.
    /// - Returns: The same instance to allow method chaining.
    func sessionTransferToken(_ token: String) -> Self

    /// Specify a custom ``WebAuthProvider`` to handle the browser session.
    ///
    /// - Parameter provider: A custom provider.
    /// - Returns: The same instance to allow method chaining.
    func provider(_ provider: @escaping WebAuthProvider) -> Self

    /// Use a private browser session to avoid storing the session cookie in the shared cookie jar.
    ///
    /// - Returns: The same instance to allow method chaining.
    func useEphemeralSession() -> Self

    // MARK: - Start

    /// Start the PAR authorization flow using a `request_uri` from a PAR response.
    /// Opens the browser with the authorize URL and returns the authorization code
    /// for the app to exchange via BFF.
    ///
    /// - Parameters:
    ///   - requestUri: The `request_uri` obtained from the PAR endpoint (must start with `urn:ietf:params:oauth:request_uri:`).
    ///   - callback: Callback with the authorization code result. Always called on the main thread.
    func start(requestUri: String, callback: @escaping @Sendable @MainActor (WebAuthResult<AuthorizationCode>) -> Void)

    #if canImport(_Concurrency)
    /// Start the PAR authorization flow using async/await.
    ///
    /// - Parameter requestUri: The `request_uri` obtained from the PAR endpoint.
    /// - Returns: An ``AuthorizationCode`` containing the authorization code.
    /// - Throws: A ``WebAuthError`` if the operation fails.
    @MainActor
    func start(requestUri: String) async throws -> AuthorizationCode
    #endif

    /// Start the PAR authorization flow as a Combine publisher.
    ///
    /// - Parameter requestUri: The `request_uri` obtained from the PAR endpoint.
    /// - Returns: A publisher that emits an ``AuthorizationCode`` or a ``WebAuthError``.
    func start(requestUri: String) -> AnyPublisher<AuthorizationCode, WebAuthError>

}
#endif
