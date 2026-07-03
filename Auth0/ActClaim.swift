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
/// - [RFC 8693: OAuth 2.0 Token Exchange - act Claim](https://tools.ietf.org/html/rfc8693#section-4.4)
/// - [Custom Token Exchange Documentation](https://auth0.com/docs/authenticate/custom-token-exchange)
public final class ActClaim: Sendable {

    /// The subject identifier of the acting party.
    ///
    /// Per [RFC 8693 Section 4.4](https://tools.ietf.org/html/rfc8693#section-4.4), `sub` is required within an `act`
    /// claim. An `act` claim without a `sub` is considered invalid and will not be parsed.
    public let sub: String

    /// A nested `act` claim representing the next actor in a delegation chain.
    public let act: ActClaim?

    /// Any additional claims beyond `sub` and `act` (e.g., `org`, `role`).
    ///
    /// Values are preserved as-is, including non-string JSON values (numbers, booleans, objects, arrays), so that
    /// custom claims set via `api.authentication.setActor()` are not lost.
    public let additionalClaims: [String: any Sendable]

    /// Creates a new `ActClaim` from a JSON dictionary.
    ///
    /// - Parameter json: A dictionary representing the `act` claim from a decoded JWT.
    /// - Returns: An `ActClaim` instance, or `nil` if the dictionary does not contain a `sub` claim.
    public init?(json: [String: any Sendable]) {
        guard let sub = json["sub"] as? String else { return nil }
        self.sub = sub

        if let nestedAct = json["act"] as? [String: any Sendable] {
            self.act = ActClaim(json: nestedAct)
        } else {
            self.act = nil
        }

        var additional: [String: any Sendable] = [:]
        for (key, value) in json where key != "sub" && key != "act" {
            additional[key] = value
        }
        self.additionalClaims = additional
    }
}
