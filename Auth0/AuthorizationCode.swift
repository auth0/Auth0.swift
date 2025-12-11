#if WEB_AUTH_PLATFORM
import Foundation

/// Result containing the authorization code from a PAR (Pushed Authorization Request) flow.
///
/// This struct is returned when using ``WebAuth/startForCode(requestURI:callback:)``
/// for PAR flows where the BFF (Backend-For-Frontend) handles the token exchange.
///
/// ## Usage
///
/// ```swift
/// // 1. BFF initiates PAR and returns request_uri
/// let parResponse = try await bffClient.initiatePAR()
///
/// // 2. SDK opens authorize and returns authorization code
/// let authCode = try await Auth0
///     .webAuth()
///     .startForCode(requestURI: parResponse.requestURI)
///
/// // 3. Send code to BFF for token exchange
/// let credentials = try await bffClient.exchangeCode(authCode.code)
///
/// // 4. Store credentials
/// credentialsManager.store(credentials: credentials)
/// ```
///
/// ## See Also
///
/// - ``WebAuth/startForCode(requestURI:callback:)``
/// - [RFC 9126 - Pushed Authorization Requests](https://datatracker.ietf.org/doc/html/rfc9126)
public struct AuthorizationCode: Sendable {
    
    /// The authorization code received from the callback.
    ///
    /// This code should be sent to your BFF to exchange for tokens
    /// using Auth0's `/oauth/token` endpoint with the `client_secret`.
    public let code: String
    
    /// The state parameter returned in the callback, if present.
    public let state: String?
    
    /// Creates a new authorization code result.
    ///
    /// - Parameters:
    ///   - code: The authorization code from the callback.
    ///   - state: The optional state parameter from the callback.
    public init(code: String, state: String? = nil) {
        self.code = code
        self.state = state
    }
}
#endif
