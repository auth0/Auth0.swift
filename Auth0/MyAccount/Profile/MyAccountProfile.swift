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
public struct MyAccountProfile: Sendable {

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
        case profilePolicy = "profile_policy"
    }

    /// `Decodable` initializer.
    ///
    /// - Parameter decoder: The decoder that holds the My Account API profile response.
    /// - Throws: A `DecodingError` if a present field has an unexpected type.
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
    }

}

// MARK: - ProfileFieldPolicy

/// Describes the access policy for a single profile field.
///
/// Returned as part of ``MyAccountProfile/profilePolicy`` to indicate whether
/// a field is editable by the user and who is authoritative for it.
public struct ProfileFieldPolicy: Decodable, Sendable {

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
///
/// Two values are equal when their ``rawValue`` is equal, so `.unknown("read_only") == .readOnly`.
public enum ProfileFieldAccess: Sendable, Hashable {

    /// The field can be read and written by the user.
    case readWrite

    /// The field is read-only and cannot be updated through the profile API.
    case readOnly

    /// An access level not known to this version of the SDK. The associated value is the raw value returned by
    /// Auth0.
    case unknown(String)

}

extension ProfileFieldAccess: RawRepresentable {

    /// Conformance to `Equatable`. Values are equal when their ``rawValue`` is equal.
    public static func == (lhs: ProfileFieldAccess, rhs: ProfileFieldAccess) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    /// Conformance to `Hashable`, consistent with ``==(_:_:)``.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    /// The value used by the My Account API, e.g. `"read_only"`.
    public var rawValue: String {
        switch self {
        case .readWrite: return "read_write"
        case .readOnly: return "read_only"
        case .unknown(let value): return value
        }
    }

    /// Creates a ``ProfileFieldAccess`` from the value used by the My Account API.
    ///
    /// - Parameter rawValue: The raw value, e.g. `"read_only"`. Unrecognized values map to ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "read_write": self = .readWrite
        case "read_only": self = .readOnly
        default: self = .unknown(rawValue)
        }
    }

}

extension ProfileFieldAccess: Decodable {

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

}

// MARK: - ProfileFieldSource

/// Who is authoritative for a profile field's value.
///
/// Two values are equal when their ``rawValue`` is equal, so `.unknown("idp") == .idp`.
public enum ProfileFieldSource: Sendable, Hashable {

    /// The value is owned and managed by the user.
    case user

    /// The value is owned and managed by the identity provider.
    case idp

    /// The value is a system-managed field and cannot be changed.
    case system

    /// A source not known to this version of the SDK. The associated value is the raw value returned by Auth0.
    case unknown(String)

}

extension ProfileFieldSource: RawRepresentable {

    /// Conformance to `Equatable`. Values are equal when their ``rawValue`` is equal.
    public static func == (lhs: ProfileFieldSource, rhs: ProfileFieldSource) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    /// Conformance to `Hashable`, consistent with ``==(_:_:)``.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    /// The value used by the My Account API, e.g. `"idp"`.
    public var rawValue: String {
        switch self {
        case .user: return "user"
        case .idp: return "idp"
        case .system: return "system"
        case .unknown(let value): return value
        }
    }

    /// Creates a ``ProfileFieldSource`` from the value used by the My Account API.
    ///
    /// - Parameter rawValue: The raw value, e.g. `"idp"`. Unrecognized values map to ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "user": self = .user
        case "idp": self = .idp
        case "system": self = .system
        default: self = .unknown(rawValue)
        }
    }

}

extension ProfileFieldSource: Decodable {

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

}
