import Foundation

// MARK: - MyAccountProfile

/// The authenticated user's profile retrieved from the My Account API.
///
/// Contains profile attributes together with a per-field access policy
/// (``profilePolicy``) that describes which fields the user is allowed to update.
///
/// ## See Also
/// - ``MyAccount/getUserProfile(options:)``
/// - ``MyAccount/updateUserProfile(_:)``
/// - ``MyAccountError``
public struct MyAccountProfile: @unchecked Sendable {

    /// The unique identifier for the user.
    public let userId: String?

    /// The user's given name (first name or forename).
    public let givenName: String?

    /// The user's family name (last name or surname).
    public let familyName: String?

    /// The user's full name.
    public let name: String?

    /// The user's preferred nickname or alias.
    public let nickname: String?

    /// URL of the user's profile picture, photo, or avatar.
    public let picture: String?

    /// The user's email address. Read-only; manage via the My Account identifiers API.
    public let email: String?

    /// Whether the user's email address has been verified.
    public let emailVerified: Bool?

    /// The user's phone number. Read-only; manage via the My Account identifiers API.
    public let phoneNumber: String?

    /// Whether the user's phone number has been verified.
    public let phoneVerified: Bool?

    /// The user's username. Read-only; manage via the My Account identifiers API.
    public let username: String?

    /// The ISO 8601 timestamp when the user was created.
    public let createdAt: String?

    /// The ISO 8601 timestamp when the user was last updated.
    public let updatedAt: String?

    /// Custom data associated with the user. The values can be any JSON-compatible type.
    ///
    /// To delete a key via ``MyAccount/updateUserProfile(_:)``, pass `nil` for its value
    /// in ``UpdateUserProfileRequest/userMetadata``.
    public let userMetadata: [String: Any]?

    /// Per-field write-eligibility map, keyed by RFC 6901 JSON Pointer (e.g. `"/given_name"`).
    ///
    /// Each entry describes whether the corresponding field is readable or writable and who
    /// controls it. Use this to drive UI affordances without hard-coding connection-type logic.
    ///
    /// - Note: Present only when the `profile_policy` field is not filtered out via
    ///   ``GetUserProfileOptions/fields``.
    public let profilePolicy: [String: ProfileFieldPolicy]?

}

// MARK: - Decodable

extension MyAccountProfile: Decodable {

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case givenName = "given_name"
        case familyName = "family_name"
        case name
        case nickname
        case picture
        case email
        case emailVerified = "email_verified"
        case phoneNumber = "phone_number"
        case phoneVerified = "phone_verified"
        case username
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userMetadata = "user_metadata"
        case profilePolicy = "profile_policy"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        givenName = try container.decodeIfPresent(String.self, forKey: .givenName)
        familyName = try container.decodeIfPresent(String.self, forKey: .familyName)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        picture = try container.decodeIfPresent(String.self, forKey: .picture)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        emailVerified = try container.decodeIfPresent(Bool.self, forKey: .emailVerified)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        phoneVerified = try container.decodeIfPresent(Bool.self, forKey: .phoneVerified)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        profilePolicy = try container.decodeIfPresent([String: ProfileFieldPolicy].self, forKey: .profilePolicy)
        if let rawMeta = try container.decodeIfPresent([String: JSONValue].self, forKey: .userMetadata) {
            userMetadata = rawMeta.mapValues { $0.anyValue }
        } else {
            userMetadata = nil
        }
    }

}

// MARK: - ProfileFieldPolicy

/// Describes the access policy for a single profile field.
///
/// Returned as part of ``MyAccountProfile/profilePolicy`` to indicate whether
/// a field is editable by the user and who is authoritative for it.
public struct ProfileFieldPolicy: Decodable, Sendable {

    /// A human-readable label for the field, suitable for display in UI.
    ///
    /// - Note: May be absent depending on the API version or field selection.
    public let label: String?

    /// Whether the field can be read or written by the user.
    public let access: ProfileFieldAccess

    /// Who is authoritative for this field's value.
    public let source: ProfileFieldSource

    /// Present when ``access`` is ``ProfileFieldAccess/readOnly``. Explains why the field
    /// cannot be updated (e.g., `"managed_by_identity_provider"`).
    public let reason: String?

}

// MARK: - ProfileFieldAccess

/// Whether a profile field can be updated by the user.
public enum ProfileFieldAccess: String, Decodable, Sendable {

    /// The field can be read and written by the user.
    case readWrite = "read_write"

    /// The field is read-only and cannot be updated through the profile API.
    case readOnly = "read_only"

}

// MARK: - ProfileFieldSource

/// Who is authoritative for a profile field's value.
public enum ProfileFieldSource: String, Decodable, Sendable {

    /// The value is owned and managed by the user.
    case user

    /// The value is owned and managed by the identity provider.
    case idp

    /// The value is a system-managed field and cannot be changed.
    case system

}

// MARK: - JSONValue (internal)

/// An internal helper for decoding arbitrary JSON values into `Any`.
///
/// This enables `user_metadata` (a heterogeneous JSON object) to be decoded
/// through the standard `JSONDecoder` path used by `myAcccountDecodable`.
enum JSONValue: Decodable {

    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            // Decode Bool before Int/Double — JSON true/false would otherwise mis-decode as 1/0.
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Unsupported JSON value type")
        }
    }

    var anyValue: Any {
        switch self {
        case .string(let value): return value
        case .int(let value): return value
        case .double(let value): return value
        case .bool(let value): return value
        case .object(let value): return value.mapValues { $0.anyValue }
        case .array(let value): return value.map { $0.anyValue }
        case .null: return NSNull()
        }
    }

}
