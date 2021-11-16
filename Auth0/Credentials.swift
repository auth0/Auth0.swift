import Foundation

/**
 User's credentials obtained from Auth0.
 */
public final class Credentials {

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

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case scope
        case recoveryCode = "recovery_code"
    }

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

extension Credentials: Codable {

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

// MARK: - Internal Methods

extension Credentials {

    func archive() throws -> Data {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        try archiver.encodeEncodable(self, forKey: NSKeyedArchiveRootObjectKey)
        archiver.finishEncoding()
        return archiver.encodedData
    }

    static func unarchive(from data: Data) throws -> Credentials {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        guard let decoded = unarchiver.decodeDecodable(self, forKey: NSKeyedArchiveRootObjectKey) else {
            let context = DecodingError.Context(codingPath: [],
                                                debugDescription: "Unable to decode Credentials",
                                                underlyingError: nil)
            throw DecodingError.dataCorrupted(context)
        }
        unarchiver.finishDecoding()
        return decoded
    }

}
