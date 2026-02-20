import Foundation

private struct _A0APICredentials {
    let accessToken: String
    let tokenType: String
    let expiresIn: Date
    let scope: String
}

/// User's credentials obtained from Auth0 for a specific API as the result of exchanging a refresh token.
public struct APICredentials: CustomStringConvertible, Sendable {

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
    public let scope: String

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
                scope: String) {
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

    private static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()

    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    internal func encode() throws -> Data {
        return try Self.jsonEncoder.encode(self)
    }

    internal init(from data: Data) throws {
        self = try Self.jsonDecoder.decode(Self.self, from: data)
    }

}

public extension APICredentials {

    init(from credentials: Credentials) {
        self.accessToken = credentials.accessToken
        self.tokenType = credentials.tokenType
        self.expiresIn = credentials.expiresIn
        self.scope = credentials.scope ?? ""
    }

}
