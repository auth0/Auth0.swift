/// A multi-factor challenge.
public struct Challenge: Codable {

    /// How the user will get the challenge and prove possession. 
    public let challengeType: String

    /// Out-of-Band (OOB) code.
    public let oobCode: String?

    /// When the challenge response includes a `prompt` binding method, your app needs to prompt the user for the
    /// `binding_code` and send it as part of the request. 
    public let bindingMethod: String?

    enum CodingKeys: String, CodingKey {
        case challengeType = "challenge_type"
        case oobCode = "oob_code"
        case bindingMethod = "binding_method"
    }

}
