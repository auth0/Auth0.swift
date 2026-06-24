/// The result of a passwordless OTP challenge on a database connection.
public struct PasswordlessChallenge: Codable, Sendable {

    /// Opaque session token used internally by ``Authentication/login(otp:challenge:audience:scope:)``.
    public let authSession: String

    enum CodingKeys: String, CodingKey {
        case authSession = "auth_session"
    }

}
