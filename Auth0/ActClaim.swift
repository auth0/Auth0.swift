import Foundation

/// Represents the `act` (actor) claim from an ID token issued during a token exchange delegation flow.
///
/// The `act` claim identifies the acting party — the entity performing actions on behalf of the subject. It is set
/// server-side via Auth0 Actions using the `api.authentication.setActor()` command.
///
/// The claim may be nested to represent delegation chains (e.g., `act.act` for multi-hop delegation).
///
/// ## Usage
///
/// ```swift
/// if let act = credentialsManager.user?.act {
///     print("Actor: \(act.sub)")
///     // Check for delegation chain
///     if let innerAct = act.act {
///         print("Original actor: \(innerAct.sub)")
///     }
/// }
/// ```
///
/// ## See Also
///
/// - [RFC 8693: OAuth 2.0 Token Exchange - act Claim](https://tools.ietf.org/html/rfc8693#section-4.1)
/// - [Custom Token Exchange Documentation](https://auth0.com/docs/authenticate/custom-token-exchange)
public final class ActClaim: Sendable {

    /// The subject identifier of the acting party.
    public let sub: String?

    /// A nested `act` claim representing the next actor in a delegation chain.
    public let act: ActClaim?

    /// Any additional claims beyond `sub` and `act` (e.g., `org`, `role`).
    public let additionalClaims: [String: String]

    /// Creates a new `ActClaim` from a JSON dictionary.
    ///
    /// - Parameter json: A dictionary representing the `act` claim from a decoded JWT.
    /// - Returns: An `ActClaim` instance, or `nil` if the dictionary is empty.
    public init?(json: [String: Any]) {
        guard !json.isEmpty else { return nil }

        self.sub = json["sub"] as? String

        if let nestedAct = json["act"] as? [String: Any] {
            self.act = ActClaim(json: nestedAct)
        } else {
            self.act = nil
        }

        var additional: [String: String] = [:]
        for (key, value) in json where key != "sub" && key != "act" {
            if let stringValue = value as? String {
                additional[key] = stringValue
            }
        }
        self.additionalClaims = additional
    }
}
