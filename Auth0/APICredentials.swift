import Foundation

private struct _A0APICredentials {
    let accessToken: String
    let tokenType: String
    let expiresIn: Date
    let scope: String?
}

/// User's credentials obtained from Auth0 for a specific API as the resulf of exchaging a refresh token.
public struct APICredentials: CustomStringConvertible {

    /// Token that can be used to make authenticated requests to the API.
    ///
    /// ## See Also
    ///
    /// - [Access Tokens](https://auth0.com/docs/secure/tokens/access-tokens)
    public let accessToken: String

    /// Indicates how the access token should be used. For example, as a bearer token.
    public let tokenType: String

    /// When the access token expires.
    public let expiresIn: Date

    /// The scopes that have been granted by Auth0.
    ///
    /// ## See Also
    ///
    /// - [Scopes](https://auth0.com/docs/get-started/apis/scopes)
    public let scope: String?

    /// Custom description that redacts the access token with `<REDACTED>`.
    public var description: String {
        let redacted = "<REDACTED>"
        let values = _A0APICredentials(accessToken: redacted,
                                       tokenType: self.tokenType,
                                       expiresIn: self.expiresIn,
                                       scope: self.scope)
        return String(describing: values).replacingOccurrences(of: "_A0APICredentials", with: "APICredentials")
    }

    // MARK: - Initializer

    /// Default initializer.
    public init(accessToken: String,
                tokenType: String,
                expiresIn: Date,
                scope: String? = nil) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.scope = scope
    }
}

// MARK: - Codable

extension APICredentials: Codable {

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope
    }

    /// `Encodable` initializer.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(tokenType, forKey: .tokenType)
        try container.encode(expiresIn.timeIntervalSinceNow, forKey: .expiresIn)
        try container.encodeIfPresent(scope, forKey: .scope)
    }

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        accessToken = try values.decode(String.self, forKey: .accessToken)
        tokenType = try values.decode(String.self, forKey: .tokenType)
        scope = try values.decodeIfPresent(String.self, forKey: .scope)

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

// MARK: - Internal Initializer

extension APICredentials {

    init(from credentials: Credentials) {
        self.accessToken = credentials.accessToken
        self.tokenType = credentials.tokenType
        self.expiresIn = credentials.expiresIn
        self.scope = credentials.scope
    }

}
