/// List of authentication methods belonging to the authenticated user.
public struct AuthenticationMethods: Decodable {
    public let authenticationMethods: [AuthenticationMethod]

    enum CodingKeys: String, CodingKey {
        case authenticationMethods = "authentication_methods"
    }
}

public struct AuthenticationMethod: Decodable {
    /// Authentication method type (factor)
    public let type: String?
    
    /// Whether the credential was backed up
    public let credentialBackedUp: Bool?
    
    /// Enum: "multi_device" "single_device"
    public let credentialDeviceType: String?
    
    /// The ID of the user identity linked with the authentication method
    public let identityUserId: String?
    
    /// The ID of the credential
    public let keyId: String?
    
    /// The public key
    public let publicKey: String?
    
    /// The transports used by clients to communicate with the authenticator
    public let transports: [String]?
    
    /// The user-agent of the browser used to create the passkey
    public let userAgent: String?
    
    /// The user handle of the user identity
    public let userHandle: String?

    /// The date of the last password reset
    public let lastPasswordReset: String?

    /// The ID of the user identity linked with the authentication method
    public let id: String

    /// The date and time when the authentication method was created
    public let createdAt: String

    /// Primary and/or secondary factor
    public let usage: [String]

    /// The authentication method status
    public let confirmed: Bool?

    /// The friendly name of the authentication method
    public let name: String?

    /// The preferred communication method via phone (sms or voice).
    public let preferredAuthenticationMethod: String?

    /// The destination phone number used to send verification codes via text and voice.
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
