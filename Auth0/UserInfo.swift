// UserInfo.swift
//
// Copyright (c) 2017 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/// OIDC Standard Claims user information
/// - note: [Claims](https://auth0.com/docs/protocols/oidc#claims)
@objc(A0UserInfo)
@objcMembers public class UserInfo: NSObject, JSONObjectPayload {

    public static let publicClaims = ["sub", "name", "given_name", "family_name", "middle_name", "nickname", "preferred_username", "profile", "picture", "website", "email", "email_verified", "gender", "birthdate", "zoneinfo", "locale", "phone_number", "phone_number_verified", "address", "updated_at"]

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

    required public init(sub: String, name: String?, givenName: String?, familyName: String?, middleName: String?, nickname: String?, preferredUsername: String?, profile: URL?, picture: URL?, website: URL?, email: String?, emailVerified: Bool?, gender: String?, birthdate: String?, zoneinfo: TimeZone?, locale: Locale?, phoneNumber: String?, phoneNumberVerified: Bool?, address: [String: String]?, updatedAt: Date?, customClaims: [String: Any]?) {
        self.sub = sub

        self.name = name
        self.givenName = givenName
        self.familyName = familyName
        self.middleName = middleName
        self.nickname = nickname
        self.preferredUsername = preferredUsername

        self.profile = profile
        self.picture = picture
        self.website = website

        self.email = email
        self.emailVerified = emailVerified

        self.gender = gender
        self.birthdate = birthdate

        self.zoneinfo = zoneinfo
        self.locale = locale

        self.phoneNumber = phoneNumber
        self.phoneNumberVerified = phoneNumberVerified
        self.address = address

        self.updatedAt = updatedAt

        self.customClaims = customClaims
    }

    convenience required public init?(json: [String: Any]) {
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

        self.init(sub: sub, name: name, givenName: givenName, familyName: familyName, middleName: middleName, nickname: nickname, preferredUsername: preferredUsername, profile: profile, picture: picture, website: website, email: email, emailVerified: emailVerified, gender: gender, birthdate: birthdate, zoneinfo: zoneinfo, locale: locale, phoneNumber: phoneNumber, phoneNumberVerified: phoneNumberVerified, address: address, updatedAt: updatedAt, customClaims: customClaims)
    }
}
