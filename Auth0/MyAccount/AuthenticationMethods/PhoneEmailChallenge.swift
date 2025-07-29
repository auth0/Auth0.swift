/// A Recovery code enrollment challenge.
public struct PhoneEmailChallenge {

    /// The unique identifier for the authentication method.
    public let authenticationId: String

    /// The unique session identifier for the enrollment.
    public let authenticationSession: String
}

extension PhoneEmailChallenge: Decodable {

    enum CodingKeys: String, CodingKey {
        case authenticationSession = "auth_session"
        case authenticationId = "id"
    }

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        guard let headers = decoder.userInfo[.headersKey] as? [String: Any],
              let locationHeader = headers["Location"] as? String,
              let authenticationMethodId = locationHeader.components(separatedBy: "/").last else {
            let errorDescription = "Missing authentication method identifier in header 'Location'"
            let errorContext = DecodingError.Context(codingPath: [],
                                                     debugDescription: errorDescription)
            throw DecodingError.dataCorrupted(errorContext)
        }

        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(authenticationId: try values.decode(String.self, forKey: .authenticationId),
                  authenticationSession: try values.decode(String.self, forKey: .authenticationSession))
    }

}


