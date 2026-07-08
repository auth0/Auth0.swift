import Foundation

/// A Password enrollment challenge.
public struct PasswordEnrollmentChallenge {

    /// The unique identifier for the authentication method.
    public let authenticationId: String

    /// The unique session identifier for the enrollment.
    public let authenticationSession: String

    /// The password policy the new password must satisfy.
    public let policy: PasswordPolicy
}

extension PasswordEnrollmentChallenge: Decodable {

    enum CodingKeys: String, CodingKey {
        case authenticationSession = "auth_session"
        case authenticationId = "id"
        case policy
    }

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        guard let locationHeader = decoder.userInfo[.locationHeaderKey] as? String,
              let _ = locationHeader.components(separatedBy: "/").last else {
            let errorDescription = "Missing authentication method identifier in header 'Location'"
            let errorContext = DecodingError.Context(codingPath: [],
                                                     debugDescription: errorDescription)
            throw DecodingError.dataCorrupted(errorContext)
        }

        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(authenticationId: try values.decode(String.self, forKey: .authenticationId),
                  authenticationSession: try values.decode(String.self, forKey: .authenticationSession),
                  policy: try values.decode(PasswordPolicy.self, forKey: .policy))
    }

}
