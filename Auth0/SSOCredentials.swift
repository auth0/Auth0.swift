import Foundation

private struct _A0SSOCredentials {
    let sessionTransferToken: String
    let issuedTokenType: String
    let expiresIn: Date
    let idToken: String
    let refreshToken: String?
}

/// Credentials obtained from Auth0 to perform web single sign-on (SSO).
public struct SSOCredentials: CustomStringConvertible {

    /// Token that can be used to request a web session.
    public let sessionTransferToken: String

    /// Type of the session transfer token.
    public let issuedTokenType: String

    /// When the session transfer token expires.
    public let expiresIn: Date

    /// Token that contains the user information.
    ///
    /// - Important: You must [validate](https://auth0.com/docs/secure/tokens/id-tokens/validate-id-tokens) any ID
    /// tokens received from the Authentication API client before using the information they contain.
    ///
    /// ## See Also
    ///
    /// - [ID Tokens](https://auth0.com/docs/secure/tokens/id-tokens)
    /// - [JSON Web Tokens](https://auth0.com/docs/secure/tokens/json-web-tokens)
    /// - [jwt.io](https://jwt.io)
    public let idToken: String

    /// Rotated refresh token. Only available when Refresh Token Rotation is enabled.
    ///
    /// - Important: If you're using the Authentication API client directly to perform the SSO exchange, make sure to store this
    /// new refresh token replacing the previous one.
    ///
    /// ## See Also
    ///
    /// - [Refresh Token Rotation](https://auth0.com/docs/secure/tokens/refresh-tokens/refresh-token-rotation)
    public let refreshToken: String?

    /// Custom description that redacts the tokens with `<REDACTED>`.
    public var description: String {
        let redacted = "<REDACTED>"
        let values = _A0SSOCredentials(sessionTransferToken: redacted,
                                       issuedTokenType: self.issuedTokenType,
                                       expiresIn: self.expiresIn,
                                       idToken: redacted,
                                       refreshToken: (self.refreshToken != nil) ? redacted : nil)
        return String(describing: values).replacingOccurrences(of: "_A0SSOCredentials", with: "SSOCredentials")
    }

    // MARK: - Initializer

    /// Default initializer.
    public init(sessionTransferToken: String,
                issuedTokenType: String,
                expiresIn: Date,
                idToken: String,
                refreshToken: String? = nil) {
        self.sessionTransferToken = sessionTransferToken
        self.issuedTokenType = issuedTokenType
        self.expiresIn = expiresIn
        self.idToken = idToken
        self.refreshToken = refreshToken
    }
}

// MARK: - Codable

extension SSOCredentials: Codable {

    enum CodingKeys: String, CodingKey {
        case sessionTransferToken = "access_token"
        case issuedTokenType = "issued_token_type"
        case expiresIn = "expires_in"
        case idToken = "id_token"
        case refreshToken = "refresh_token"
    }

    /// `Encodable` initializer.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(sessionTransferToken, forKey: .sessionTransferToken)
        try container.encode(issuedTokenType, forKey: .issuedTokenType)
        try container.encode(expiresIn.timeIntervalSinceNow, forKey: .expiresIn)
        try container.encode(idToken, forKey: .idToken)
        try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
    }

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        sessionTransferToken = try values.decode(String.self, forKey: .sessionTransferToken)
        issuedTokenType = try values.decode(String.self, forKey: .issuedTokenType)
        idToken = try values.decode(String.self, forKey: .idToken)
        refreshToken = try values.decodeIfPresent(String.self, forKey: .refreshToken)

        if let string = try? values.decode(String.self, forKey: .expiresIn), let double = Double(string) {
            expiresIn = Date(timeIntervalSinceNow: double)
        } else if let double = try? values.decode(Double.self, forKey: .expiresIn) {
            expiresIn = Date(timeIntervalSinceNow: double)
        } else if let date = try? values.decode(Date.self, forKey: .expiresIn) {
            expiresIn = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .expiresIn,
                                                   in: values,
                                                   debugDescription: "Format of expires_in is not recognized.")
        }
    }

}
