/// The result of a passwordless OTP challenge on a database connection.
public struct PasswordlessChallenge: Codable, Sendable {

    /// Opaque session token. Pass this to ``Authentication/login(authSession:otp:audience:scope:)-1o1uw``
    /// along with the OTP entered by the user.
    public let authSession: String

    enum CodingKeys: String, CodingKey {
        case authSession = "auth_session"
    }

}
