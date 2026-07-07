import Foundation
import JWTDecode

private struct _A0Credentials {
    let accessToken: String
    let tokenType: String
    let idToken: String
    let refreshToken: String?
    let expiresIn: Date
    let scope: String?
    let recoveryCode: String?
}

/// User's credentials obtained from Auth0.
@objc(A0Credentials)
public final class Credentials: NSObject, Sendable {

    /// Token that can be used to make authenticated requests to the specified API (the **audience** value used on login).
    ///
    /// ## See Also
    ///
    /// - [Access Tokens](https://auth0.com/docs/secure/tokens/access-tokens)
    /// - [Audience](https://auth0.com/docs/secure/tokens/access-tokens/get-access-tokens#control-access-token-audience)
    public let accessToken: String

    /// Indicates how the access token should be used. For example, as a bearer token.
    public let tokenType: String

    /// When the access token expires.
    public let expiresIn: Date

    /// Token that can be used to request a new access token.
    ///
    /// - Requires: The scope `offline_access` to have been requested on login. Make sure that your Auth0 application
    /// has the **refresh token** [grant enabled](https://auth0.com/docs/get-started/applications/update-grant-types).
    /// If you are also specifying an audience value, make sure that the corresponding Auth0 API has the
    /// **Allow Offline Access** [setting enabled](https://auth0.com/docs/get-started/apis/api-settings#access-settings).
    ///
    /// ## See Also
    ///
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    public let refreshToken: String?

    /// Token that contains the user information.
    ///
    /// - Important: The ID tokens obtained from Web Auth login are automatically validated by Auth0.swift, ensuring their
    /// contents have not been tampered with. **This is not the case for the ID tokens obtained from the Authentication API
    /// client**, including the ones received when renewing the credentials using the refresh token. You must
    /// [validate](https://auth0.com/docs/secure/tokens/id-tokens/validate-id-tokens) any ID tokens received from the
    /// Authentication API client before using the information they contain.
    ///
    /// ## See Also
    ///
    /// - [ID Tokens](https://auth0.com/docs/secure/tokens/id-tokens)
    /// - [JSON Web Tokens](https://auth0.com/docs/secure/tokens/json-web-tokens)
    /// - [jwt.io](https://jwt.io)
    public let idToken: String

    /// The scopes that have been granted by Auth0.
    ///
    /// ## See Also
    ///
    /// - [Scopes](https://auth0.com/docs/get-started/apis/scopes)
    public let scope: String?

    /// MFA recovery code that the application must display to the user, to be stored securely for future use.
    ///
    /// ## See Also
    ///
    /// - [MFA Recovery Codes](https://auth0.com/docs/secure/multi-factor-authentication/configure-recovery-codes-for-mfa)
    public let recoveryCode: String?

    /// The date at which the IPSIE `session_expiry` ceiling is reached, or `nil` when the claim is
    /// absent or outside the valid range `(0, 10_000_000_000)`.
    ///
    /// - Important: Reflects the *current* ID token only. ``CredentialsManager`` enforces the ceiling
    /// using the value pinned to the Keychain at initial login, which survives refresh-token renewals.
    public var sessionExpiresAt: Date? {
        guard let seconds = Credentials.parseSessionExpiry(fromIdToken: self.idToken) else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(seconds))
    }

    /// Decodes the IPSIE `session_expiry` claim from a JWT string.
    ///
    /// Returns the Unix-seconds timestamp as an `Int64`, or `nil` when the token is absent, unparseable,
    /// does not carry the claim, or carries a value outside `(0, 10_000_000_000)`.
    /// The upper bound rejects timestamps expressed in milliseconds (13-digit values produced by
    /// `Date.now()` in JavaScript) which would silently disable the ceiling if accepted.
    /// The claim is read as `Double` so a fractional value is truncated rather than dropped.
    /// The result is `Int64` (not `Int`): a valid ceiling can exceed `Int32.max` (year 2038),
    /// which would overflow the 32-bit `Int` used on watchOS.
    static func parseSessionExpiry(fromIdToken idToken: String?) -> Int64? {
        guard let idToken = idToken,
              let jwt = try? decode(jwt: idToken),
              let rawValue = jwt.body["session_expiry"] as? Double else {
            return nil
        }
        // Bound the value as a `Double` before truncating, so the ceiling is enforced identically
        // on every platform and the truncation never overflows the destination integer.
        guard rawValue > 0, rawValue < 10_000_000_000 else { return nil }
        return Int64(rawValue)
    }

    /// Custom description that redacts the tokens with `<REDACTED>`.
    public override var description: String {
        let redacted = "<REDACTED>"
        let values = _A0Credentials(accessToken: redacted,
                                    tokenType: self.tokenType,
                                    idToken: redacted,
                                    refreshToken: (self.refreshToken != nil) ? redacted : nil,
                                    expiresIn: self.expiresIn,
                                    scope: self.scope,
                                    recoveryCode: (self.recoveryCode != nil) ? redacted : nil)
        return String(describing: values).replacingOccurrences(of: "_A0Credentials", with: "Credentials")
    }

    // MARK: - Initializer

    /// Default initializer.
    public init(accessToken: String = "",
                tokenType: String = "",
                idToken: String = "",
                refreshToken: String? = nil,
                expiresIn: Date = Date(),
                scope: String? = nil,
                recoveryCode: String? = nil) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.scope = scope
        self.recoveryCode = recoveryCode
    }

}

// MARK: - Codable

extension Credentials: Codable {

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case scope
        case recoveryCode = "recovery_code"
    }

    /// `Decodable` initializer.
    public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let accessToken = try values.decodeIfPresent(String.self, forKey: .accessToken)
        let tokenType = try values.decodeIfPresent(String.self, forKey: .tokenType)
        let idToken = try values.decodeIfPresent(String.self, forKey: .idToken)
        let refreshToken = try values.decodeIfPresent(String.self, forKey: .refreshToken)
        let scope = try values.decodeIfPresent(String.self, forKey: .scope)
        let recoveryCode = try values.decodeIfPresent(String.self, forKey: .recoveryCode)

        var expiresIn: Date?
        if let string = try? values.decode(String.self, forKey: .expiresIn), let double = Double(string) {
            expiresIn = Date(timeIntervalSinceNow: double)
        } else if let double = try? values.decode(Double.self, forKey: .expiresIn) {
            expiresIn = Date(timeIntervalSinceNow: double)
        } else if let date = try? values.decode(Date.self, forKey: .expiresIn) {
            expiresIn = date
        }

        self.init(accessToken: accessToken ?? "",
                  tokenType: tokenType ?? "",
                  idToken: idToken ?? "",
                  refreshToken: refreshToken,
                  expiresIn: expiresIn ?? Date(),
                  scope: scope,
                  recoveryCode: recoveryCode)
    }

}

// MARK: - NSSecureCoding

extension Credentials: NSSecureCoding {

    /// `NSSecureCoding` decoding initializer.
    public convenience init?(coder aDecoder: NSCoder) {
        let accessToken = aDecoder.decodeObject(of: NSString.self, forKey: "accessToken")
        let tokenType = aDecoder.decodeObject(of: NSString.self, forKey: "tokenType")
        let idToken = aDecoder.decodeObject(of: NSString.self, forKey: "idToken")
        let refreshToken = aDecoder.decodeObject(of: NSString.self, forKey: "refreshToken")
        let expiresIn = aDecoder.decodeObject(of: NSDate.self, forKey: "expiresIn")
        let scope = aDecoder.decodeObject(of: NSString.self, forKey: "scope")
        let recoveryCode = aDecoder.decodeObject(of: NSString.self, forKey: "recoveryCode")

        self.init(accessToken: accessToken as String? ?? "",
                  tokenType: tokenType as String? ?? "",
                  idToken: idToken as String? ?? "",
                  refreshToken: refreshToken as String?,
                  expiresIn: expiresIn as Date? ?? Date(),
                  scope: scope as String?,
                  recoveryCode: recoveryCode as String?)
    }

    /// `NSSecureCoding` encoding method.
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.accessToken as NSString, forKey: "accessToken")
        aCoder.encode(self.tokenType as NSString, forKey: "tokenType")
        aCoder.encode(self.idToken as NSString, forKey: "idToken")
        aCoder.encode(self.refreshToken as NSString?, forKey: "refreshToken")
        aCoder.encode(self.expiresIn as NSDate, forKey: "expiresIn")
        aCoder.encode(self.scope as NSString?, forKey: "scope")
        aCoder.encode(self.recoveryCode as NSString?, forKey: "recoveryCode")
    }

    /// Property that enables secure coding. Equals to `true`.
    public static var supportsSecureCoding: Bool { return true }

}

// MARK: - Internal Initializer

extension Credentials {

    convenience init(from credentials: Credentials, idToken: String? = nil, refreshToken: String? = nil) {
        self.init(accessToken: credentials.accessToken,
                  tokenType: credentials.tokenType,
                  idToken: idToken ?? credentials.idToken,
                  refreshToken: refreshToken ?? credentials.refreshToken,
                  expiresIn: credentials.expiresIn,
                  scope: credentials.scope)
    }

}
