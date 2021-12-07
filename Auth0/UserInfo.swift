import Foundation

/// OIDC Standard Claims user information.
/// - Note: [Claims](https://auth0.com/docs/security/tokens/json-web-tokens/json-web-token-claims)
public struct UserInfo: JSONObjectPayload {

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

    public let sub: String

    public let name: String?
    public let givenName: String?
    public let familyName: String?
    public let middleName: String?
    public let nickname: String?
    public let preferredUsername: String?

    public let profile: URL?
    public let picture: URL?
    public let website: URL?

    public let email: String?
    public let emailVerified: Bool?

    public let gender: String?
    public let birthdate: String?

    public let zoneinfo: TimeZone?
    public let locale: Locale?

    public let phoneNumber: String?
    public let phoneNumberVerified: Bool?

    public let address: [String: String]?
    public let updatedAt: Date?

    public let customClaims: [String: Any]?

}

public extension UserInfo {

    // swiftlint:disable:next function_body_length
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
