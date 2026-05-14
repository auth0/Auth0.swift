#if WEB_AUTH_PLATFORM
import Foundation

/// The result of a PAR (Pushed Authorization Request) authorization flow.
///
/// Contains the authorization code returned by the `/authorize` endpoint, which should be sent
/// to your backend (BFF) for token exchange.
///
/// ## See Also
///
/// - ``PARWebAuth``
public struct AuthorizationCode {

    /// The authorization code returned by the `/authorize` endpoint.
    public let code: String

    /// The state parameter returned in the redirect, if present.
    /// This is the state that was originally sent by your backend to the `/oauth/par` endpoint.
    public let state: String?

    /// Creates a new `AuthorizationCode` instance.
    ///
    /// - Parameters:
    ///   - code: The authorization code.
    ///   - state: The state parameter, if any.
    public init(code: String, state: String? = nil) {
        self.code = code
        self.state = state
    }

}
#endif
