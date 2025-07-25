public struct AuthenticationMethods: Decodable {
    public let authenticationMethods: [AuthenticationMethod]
    
    enum CodingKeys: String, CodingKey {
        case authenticationMethods = "authentication_methods"
    }
}

public struct AuthenticationMethod: Decodable {
    let type: String?
    let credentialBackedUp: Bool?
    let credentialDeviceType: String?
    let identityUserId: String?
    let keyId: String?
    let publicKey: String?
    let transports: [String]?
    let userAgent: String?
    let userHandle: String?
    let lastPasswordReset: String?
    let id: String?
    let createdAt: String
    let usage: [String]
    let confirmed: Bool?
    let name: String?
    let preferredAuthenticationMethod: String?
    let phoneNumber: String?

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
