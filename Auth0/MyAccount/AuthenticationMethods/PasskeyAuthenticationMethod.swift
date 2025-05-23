#if PASSKEYS_PLATFORM
import Foundation

/// A passkey authentication method.
public struct PasskeyAuthenticationMethod: Identifiable, Equatable, Sendable {

    /// Unique identifier of the authentication method.
    public let id: String

    /// Type of the authentication method. Equals to `passkey`.
    public let type: String

    /// Unique identifier of the user identity linked with the authentication method.
    public let userIdentityId: String

    /// The user agent of the browser o device used to enroll the passkey.
    public let userAgent: String?

    /// Details of the passkey credential.
    public let credential: PasskeyCredential

    /// Creation date of the authentication method.
    public let createdAt: Date

}

/// A passkey credential.
public struct PasskeyCredential: Identifiable, Equatable, Sendable {

    /// Unique identifier of the passkey credential.
    public let id: String

    /// Public key of the passkey credential.
    public let publicKey: Data // This comes base64-encoded

    /// User handle associated with the passkey credential.
    public let userHandle: Data // This comes base64url-encoded

    /// Kind of device the passkey credential is stored on as defined by backup eligibility.
    public let deviceType: PasskeyDeviceType

    /// Whether the passkey credential was backed up.
    public let isBackedUp: Bool

}

/// Kind of device the passkey is stored on as defined by backup eligibility.
public enum PasskeyDeviceType: String, Sendable, Decodable {

    /// Passkey that cannot be backed up and synced to another device.
    case singleDevice = "single_device"

    /// Passkey that can be backed up and synced to another device, when enabled by the user.
    case multiDevice = "multi_device"

}

extension PasskeyAuthenticationMethod: Decodable {

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case userIdentityId = "identity_user_id"
        case userAgent = "user_agent"
        case credential
        case createdAt = "created_at"
    }

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let createdAtFormatter = ISO8601DateFormatter()
        createdAtFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard case let createdAtString = try values.decode(String.self, forKey: .createdAt),
              let createdAtDate = createdAtFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt,
                                                   in: values,
                                                   debugDescription: "Format of created_at is not recognized.")
        }

        createdAt = createdAtDate

        id = try values.decode(String.self, forKey: .id)
        type = try values.decode(String.self, forKey: .type)
        userIdentityId = try values.decode(String.self, forKey: .userIdentityId)
        userAgent = try values.decodeIfPresent(String.self, forKey: .userAgent)
        credential = try decoder.singleValueContainer().decode(PasskeyCredential.self)
    }

}

extension PasskeyCredential: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "key_id"
        case publicKey = "public_key"
        case userHandle = "user_handle"
        case deviceType = "credential_device_type"
        case isBackedUp = "credential_backed_up"
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
        deviceType = try values.decode(PasskeyDeviceType.self, forKey: .deviceType)
        isBackedUp = try values.decode(Bool.self, forKey: .isBackedUp)
    }

}
#endif
