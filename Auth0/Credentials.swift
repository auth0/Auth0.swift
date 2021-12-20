import Foundation

private struct StructCredentials {
    let accessToken: String
    let tokenType: String
    let idToken: String
    let refreshToken: String?
    let expiresIn: Date
    let scope: String?
    let recoveryCode: String?
}

/**
 User's credentials obtained from Auth0.
 */
@objc(A0Credentials)
public final class Credentials: NSObject {

    /// Token that can be used to make authenticated requests to the specified API (the **audience** value used on authentication).
    public let accessToken: String
    /// Type of the Access Token.
    public let tokenType: String
    /// When the Access Token expires.
    public let expiresIn: Date
    /// Token that can be used to request a new Access Token. Requires the scope `offline_access` to be requested on authentication.
    public let refreshToken: String?
    /// Token that contains the user information.
    public let idToken: String
    /// Granted scopes. This value is only present when one or more of the requested scopes were not granted.
    public let scope: String?
    /// MFA recovery code that the application must display to the end-user, to be stored securely for future use.
    public let recoveryCode: String?

    /// Custom description that redacts the tokens with `<REDACTED>`.
    public override var description: String {
        let redacted = "<REDACTED>"
        let values = StructCredentials(accessToken: redacted,
                                       tokenType: self.tokenType,
                                       idToken: redacted,
                                       refreshToken: (self.refreshToken != nil) ? redacted : nil,
                                       expiresIn: self.expiresIn,
                                       scope: self.scope,
                                       recoveryCode: (self.recoveryCode != nil) ? redacted : nil)
        return String(describing: values).replacingOccurrences(of: "StructCredentials", with: "Credentials")
    }

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
