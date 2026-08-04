/// Describes the password policy that a new password must satisfy, as returned by the My Account API
/// when starting a password enrollment. Use it to build a UI that guides the user toward a compliant
/// password.
public struct PasswordPolicy: Decodable, Sendable {

    /// Rules governing the structural complexity of the password (length, character types, etc.).
    public let complexity: PasswordComplexity

    /// Rules that prevent the password from containing personal information taken from the user profile.
    public let profileData: PasswordProfileData

    /// Rules that prevent reuse of previously used passwords.
    public let history: PasswordHistory

    /// Rules that prevent the use of common dictionary words as passwords.
    public let dictionary: PasswordDictionary

    enum CodingKeys: String, CodingKey {
        case complexity
        case profileData = "profile_data"
        case history
        case dictionary
    }

}

/// Structural complexity requirements for a password.
public struct PasswordComplexity: Decodable, Sendable {

    /// The minimum number of characters the password must contain.
    public let minLength: Int?

    /// The character classes the password may be required to include.
    /// Possible values: `uppercase`, `lowercase`, `number`, `special`.
    public let characterTypes: [String]?

    /// How the ``characterTypes`` requirement is enforced.
    /// Possible values: `all` (every listed type is required), `three_of_four`.
    public let characterTypeRule: String?

    /// Whether identical consecutive characters are permitted.
    /// Possible values: `allow`, `block`.
    public let identicalCharacters: String?

    /// Whether sequential characters (e.g. `abc`, `123`) are permitted.
    /// Possible values: `allow`, `block`.
    public let sequentialCharacters: String?

    /// How a password that exceeds the maximum allowed length is handled.
    /// Possible values: `truncate`, `error`.
    public let maxLengthExceeded: String?

    enum CodingKeys: String, CodingKey {
        case minLength = "min_length"
        case characterTypes = "character_types"
        case characterTypeRule = "character_type_rule"
        case identicalCharacters = "identical_characters"
        case sequentialCharacters = "sequential_characters"
        case maxLengthExceeded = "max_length_exceeded"
    }

}

/// Rules that block the use of personal information from the user profile within a password.
public struct PasswordProfileData: Decodable, Sendable {

    /// Whether blocking of personal information is enabled.
    public let active: Bool?

    /// The user profile fields whose values must not appear in the password
    /// (e.g. `name`, `email`, `user_metadata.first`).
    public let blockedFields: [String]?

    enum CodingKeys: String, CodingKey {
        case active
        case blockedFields = "blocked_fields"
    }

}

/// Rules that prevent reuse of previously used passwords.
public struct PasswordHistory: Decodable, Sendable {

    /// Whether password history enforcement is enabled.
    public let active: Bool?

    /// The number of previous passwords that cannot be reused.
    public let size: Int?

}

/// Rules that prevent the use of common dictionary words as passwords.
public struct PasswordDictionary: Decodable, Sendable {

    /// Whether dictionary checking is enabled.
    public let active: Bool?

    /// The default dictionary used for the check.
    /// Possible values: `en_10k`, `en_100k`.
    public let `default`: String?

}
