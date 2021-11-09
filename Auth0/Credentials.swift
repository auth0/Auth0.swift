import Foundation

/**
 User's credentials obtained from Auth0.
 */
public class Credentials: NSObject, JSONObjectPayload, NSSecureCoding {

    /// Token used that allows calling to the requested APIs (audience sent on Auth)
    public let accessToken: String
    /// Type of the access token
    public let tokenType: String
    /// When the access_token expires
    public let expiresIn: Date
    /// If the API allows you to request new access tokens and the scope `offline_access` was included on Auth
    public let refreshToken: String?
    /// Token that details the user identity after authentication
    public let idToken: String
    /// Granted scopes, only populated when a requested scope or scopes was not granted and Auth is OIDC Conformant
    public let scope: String?
    /// MFA recovery code that the application must display to the end-user to be stored securely for future use
    public let recoveryCode: String?

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

    convenience required public init(json: [String: Any]) {
        var expiresIn: Date?

        if let value = json["expires_in"],
           let double = NumberFormatter().number(from: String(describing: value))?.doubleValue {
            expiresIn = Date(timeIntervalSinceNow: double)
        }

        self.init(accessToken: json["access_token"] as? String ?? "",
                  tokenType: json["token_type"] as? String ?? "",
                  idToken: json["id_token"] as? String ?? "",
                  refreshToken: json["refresh_token"] as? String,
                  expiresIn: expiresIn ?? Date(),
                  scope: json["scope"] as? String,
                  recoveryCode: json["recovery_code"] as? String)
    }

    // MARK: - NSSecureCoding

    convenience required public init?(coder aDecoder: NSCoder) {
        let accessToken = aDecoder.decodeObject(forKey: "accessToken")
        let tokenType = aDecoder.decodeObject(forKey: "tokenType")
        let idToken = aDecoder.decodeObject(forKey: "idToken")
        let refreshToken = aDecoder.decodeObject(forKey: "refreshToken")
        let expiresIn = aDecoder.decodeObject(forKey: "expiresIn")
        let scope = aDecoder.decodeObject(forKey: "scope")
        let recoveryCode = aDecoder.decodeObject(forKey: "recoveryCode")

        self.init(accessToken: accessToken as? String ?? "",
                  tokenType: tokenType as? String ?? "",
                  idToken: idToken as? String ?? "",
                  refreshToken: refreshToken as? String,
                  expiresIn: expiresIn as? Date ?? Date(),
                  scope: scope as? String,
                  recoveryCode: recoveryCode as? String)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.accessToken, forKey: "accessToken")
        aCoder.encode(self.tokenType, forKey: "tokenType")
        aCoder.encode(self.idToken, forKey: "idToken")
        aCoder.encode(self.refreshToken, forKey: "refreshToken")
        aCoder.encode(self.expiresIn, forKey: "expiresIn")
        aCoder.encode(self.scope, forKey: "scope")
        aCoder.encode(self.recoveryCode, forKey: "recoveryCode")
    }

    public static var supportsSecureCoding: Bool = true
}
