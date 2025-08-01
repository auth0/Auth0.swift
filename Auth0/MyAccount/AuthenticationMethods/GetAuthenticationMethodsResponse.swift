public struct AuthenticationMethods: Decodable {
    public let authenticationMethods: [AuthenticationMethod]

    enum CodingKeys: String, CodingKey {
        case authenticationMethods = "authentication_methods"
    }
}

public struct AuthenticationMethod: Decodable {
    public let type: String?
    public let credentialBackedUp: Bool?
    public let credentialDeviceType: String?
    public let identityUserId: String?
    public let keyId: String?
    public let publicKey: String?
    public let transports: [String]?
    public let userAgent: String?
    public let userHandle: String?
    public let lastPasswordReset: String?
    public let id: String
    public let createdAt: String
    public let usage: [String]
    public let confirmed: Bool?
    public let name: String?
    public let preferredAuthenticationMethod: String?
    public let phoneNumber: String?

    enum CodingKeys: String, CodingKey {
        case type
        case identityUserId = "identity_user_id"
        case lastPasswordReset = "last_password_reset"
        case id
        case createdAt = "created_at"
        case usage
        case credentialBackedUp = "credential_backed_up"
        case credentialDeviceType = "credential_device_type"
        case keyId = "key_id"
        case userAgent = "user_agent"
        case userHandle = "user_handle"
        case publicKey = "public_key"
        case transports
        case confirmed
        case name
        case preferredAuthenticationMethod = "preferrred_authentication_method"
        case phoneNumber = "phone_number"
    }
}
