import Foundation

/// Represents the acting party in a token exchange delegation/impersonation flow.
///
/// An `ActorToken` bundles the token and its type URI together, ensuring both are always provided as required by
/// [RFC 8693](https://tools.ietf.org/html/rfc8693). Auth0 requires both `actor_token` and `actor_token_type` to be
/// present when performing delegation.
///
/// ## Usage
///
/// ```swift
/// let actor = ActorToken(token: "admin-id-token",
///                        tokenType: "urn:ietf:params:oauth:token-type:id_token")
/// ```
///
/// ## See Also
///
/// - [RFC 8693: OAuth 2.0 Token Exchange](https://tools.ietf.org/html/rfc8693#section-2.1)
/// - [Custom Token Exchange Documentation](https://auth0.com/docs/authenticate/custom-token-exchange)
public struct ActorToken: Sendable {

    /// The token representing the acting party (the entity performing actions on behalf of the subject).
    public let token: String

    /// A URI indicating the type of the actor token (e.g., `urn:ietf:params:oauth:token-type:id_token`
    /// or a custom URI like `http://corporate-idp/id-token`).
    public let tokenType: String

    /// Creates a new `ActorToken`.
    ///
    /// - Parameters:
    ///   - token: The token representing the acting party.
    ///   - tokenType: A URI indicating the type of the actor token.
    public init(token: String, tokenType: String) {
        self.token = token
        self.tokenType = tokenType
    }
}
