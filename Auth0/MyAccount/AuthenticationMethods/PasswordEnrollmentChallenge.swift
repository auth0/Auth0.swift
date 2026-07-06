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

}
