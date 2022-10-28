// swiftlint:disable function_body_length

import Foundation

/// OIDC Standard Claims user information.
///
/// ## See Also
///
/// - [Claims](https://auth0.com/docs/secure/tokens/json-web-tokens/json-web-token-claims)
public struct UserInfo: JSONObjectPayload {

    /// The list of public claims.
    public static let publicClaims = [
        "sub",
        "name",
        "given_name",
        "family_name",
        "middle_name",
        "nickname",
        "preferred_username",
        "profile",
        "picture",
        "website",
        "email",
        "email_verified",
        "gender",
        "birthdate",
        "zoneinfo",
        "locale",
        "phone_number",
        "phone_number_verified",
        "address",
        "updated_at"
    ]

    // MARK: - Claims

    /// The Auth0 user identifier.
    public let sub: String

    /// The name of the user.
    ///
    /// - Requires: The `profile` scope.
    public let name: String?

    /// The first name of the user.
    ///
    /// - Requires: The `profile` scope.
    public let givenName: String?

    /// The last name of the user.
    ///
    /// - Requires: The `profile` scope.
    public let familyName: String?

    /// The middle name of the user.
    ///
    /// - Requires: The `profile` scope.
    public let middleName: String?

    /// The nickname of the user.
    ///
    /// - Requires: The `profile` scope.
    public let nickname: String?

    /// The preferred username of the user.
    ///
    /// - Requires: The `profile` scope.
    public let preferredUsername: String?

    /// The URL of the user's profile page.
    ///
    /// - Requires: The `profile` scope.
    public let profile: URL?

    /// The URL of the user's picture.
    ///
    /// - Requires: The `profile` scope.
    public let picture: URL?

    /// The URL of the user's website.
    ///
    /// - Requires: The `profile` scope.
    public let website: URL?

    /// The email of the user.
    ///
    /// - Requires: The `email` scope.
    public let email: String?

    /// If the user's email is verified.
    ///
    /// - Requires: The `email` scope.
    public let emailVerified: Bool?

    /// The gender of the user.
    ///
    /// - Requires: The `profile` scope.
    public let gender: String?

    /// The birthdate of the user.
    ///
    /// - Requires: The `profile` scope.
    public let birthdate: String?

    /// The time zone of the user.
    ///
    /// - Requires: The `profile` scope.
    public let zoneinfo: TimeZone?

    /// The locale of the user.
    ///
    /// - Requires: The `profile` scope.
    public let locale: Locale?

    /// The phone number of the user.
    ///
    /// - Requires: The `phone_number` scope.
    public let phoneNumber: String?

    /// If the user's phone number is verified.
    ///
    /// - Requires: The `phone_number` scope.
    public let phoneNumberVerified: Bool?

    /// The address of the user.
    ///
    /// - Requires: The `address` scope.
    public let address: [String: String]?

    /// The date and time the user's information was last updated.
    ///
    /// - Requires: The `profile` scope.
    public let updatedAt: Date?

    /// Any custom claims.
    public let customClaims: [String: Any]?

}

// MARK: - Initializer

public extension UserInfo {

    /// Creates a new `UserInfo` from a JSON dictionary.
    init?(json: [String: Any]) {
        guard let sub = json["sub"] as? String else { return nil }

        let name = json["name"] as? String
        let givenName = json["given_name"] as? String
        let familyName = json["family_name"] as? String
        let middleName = json["middle_name"] as? String
        let nickname = json["nickname"] as? String
        let preferredUsername = json["preferred_username"] as? String

        var profile: URL?
        if let profileURL = json["profile"] as? String { profile = URL(string: profileURL) }

        var picture: URL?
        if let pictureURL = json["picture"] as? String { picture = URL(string: pictureURL) }

        var website: URL?
        if let websiteURL = json["website"] as? String { website = URL(string: websiteURL) }

        let email = json["email"] as? String
        let emailVerified = json["email_verified"] as? Bool

        let gender = json["gender"] as? String
        let birthdate = json["birthdate"] as? String

        var zoneinfo: TimeZone?
        if let timeZone = json["zoneinfo"] as? String { zoneinfo = TimeZone(identifier: timeZone) }

        var locale: Locale?
        if let localeInfo = json["locale"] as? String { locale = Locale(identifier: localeInfo) }

        let phoneNumber = json["phone_number"] as? String
        let phoneNumberVerified = json["phone_number_verified"] as? Bool
        let address = json["address"] as? [String: String]

        var updatedAt: Date?
        if let dateString = json["updated_at"] as? String {
            updatedAt = date(from: dateString)
        }

        var customClaims = json
        UserInfo.publicClaims.forEach { customClaims.removeValue(forKey: $0) }

        self.init(sub: sub,
                  name: name,
                  givenName: givenName,
                  familyName: familyName,
                  middleName: middleName,
                  nickname: nickname,
                  preferredUsername: preferredUsername,
                  profile: profile,
                  picture: picture,
                  website: website,
                  email: email,
                  emailVerified: emailVerified,
                  gender: gender,
                  birthdate: birthdate,
                  zoneinfo: zoneinfo,
                  locale: locale,
                  phoneNumber: phoneNumber,
                  phoneNumberVerified: phoneNumberVerified,
                  address: address,
                  updatedAt: updatedAt,
                  customClaims: customClaims)
    }

}
