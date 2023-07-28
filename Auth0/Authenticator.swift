/// A multi-factor authenticator.
public struct Authenticator: Codable, Identifiable {

    /// The unique identifier of the authenticator.
    public let id: String

    /// The type of the authenticator, either `otp`, `oob`, or `recovery_code`.
    public let type: String

    /// Whether the authenticator has been confirmed or not.
    public let active: Bool

    /// The name of the authenticator.
    public let name: String?

    /// The channel used to send a code for OOB authenticators.
    public let oobChannel: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type = "authenticator_type"
        case active
        case name
        case oobChannel = "oob_channel"
    }

}
