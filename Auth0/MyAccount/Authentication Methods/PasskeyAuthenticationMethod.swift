#if PASSKEYS_PLATFORM
import Foundation

/// A passkey authentication method.
public struct PasskeyAuthenticationMethod: Identifiable, Equatable, Sendable {

    /// Unique identifier of the authentication method.
    public let id: String

    /// Type of the authentication method. Equals to `passkey`.
    public let type: String

    /// Creation date of the authentication method.
    public let createdAt: Date

    /// Unique identifier of the user identity.
    public let userIdentityId: String

    /// User handle associated with the passkey credential.
    public let userHandle: Data // This comes base64url-encoded

    /// Unique identifier of the passkey credential.
    public let keyId: String

    /// Public key of the passkey credential.
    public let publicKey: Data // This comes base64-encoded

    /// Kind of device the passkey is stored on as defined by backup eligibility.
    public let credentialDeviceType: CredentialDeviceType

    /// Whether the passkey was backed up.
    public let isCredentialBackedUp: Bool

}

extension PasskeyAuthenticationMethod: Decodable {

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case userIdentityId = "identity_user_id"
        case userHandle = "user_handle"
        case keyId = "key_id"
        case publicKey = "public_key"
        case credentialDeviceType = "credential_device_type"
        case isCredentialBackedUp = "credential_backed_up"
        case createdAt = "created_at"
    }

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        guard case let userHandleString = try values.decode(String.self, forKey: .userHandle),
              let userHandleData = userHandleString.a0_decodeBase64URLSafe() else {
            throw DecodingError.dataCorruptedError(forKey: .userHandle,
                                                   in: values,
                                                   debugDescription: "Format of user_handle is not recognized.")
        }

        userHandle = userHandleData

        guard case let publicKeyString = try values.decode(String.self, forKey: .publicKey),
              let publicKeyData = Data(base64Encoded: publicKeyString) else {
            throw DecodingError.dataCorruptedError(forKey: .publicKey,
                                                   in: values,
                                                   debugDescription: "Format of public_key is not recognized.")
        }

        publicKey = publicKeyData

        id = try values.decode(String.self, forKey: .id)
        type = try values.decode(String.self, forKey: .type)
        userIdentityId = try values.decode(String.self, forKey: .userIdentityId)
        keyId = try values.decode(String.self, forKey: .keyId)
        credentialDeviceType = try values.decode(CredentialDeviceType.self, forKey: .credentialDeviceType)
        isCredentialBackedUp = try values.decode(Bool.self, forKey: .isCredentialBackedUp)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
    }

}

/// Kind of device the passkey is stored on as defined by backup eligibility.
public enum CredentialDeviceType: String, Sendable, Decodable {

    /// Passkey that cannot be backed up and synced to another device.
    case singleDevice = "single_device"

    /// Passkey that can be backed up and synced to another device, when enabled by the user.
    case multiDevice = "multi_device"

}
#endif
