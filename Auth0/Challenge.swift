public struct Challenge: Codable {
    public let challengeType: String
    public let oobCode: String?
    public let bindingMethod: String?

    public enum CodingKeys: String, CodingKey {
        case challengeType = "challenge_type"
        case oobCode = "oob_code"
        case bindingMethod = "binding_method"
    }
}
