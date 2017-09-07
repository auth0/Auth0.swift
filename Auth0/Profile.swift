// Profile.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
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

/**
 Auth0 normalized user profile returned by Auth0
 
 - seeAlso: [Normalized User Profile](https://auth0.com/docs/user-profile/normalized)
 */
@objc(A0Profile)
public class Profile: NSObject, JSONObjectPayload {

    public let id: String
    public let name: String
    public let nickname: String
    public let pictureURL: URL
    public let createdAt: Date

    public let email: String?
    public let emailVerified: Bool
    public let givenName: String?
    public let familyName: String?

    public let additionalAttributes: [String: Any]
    public let identities: [Identity]

    public subscript(key: String) -> Any? {
        return self.additionalAttributes[key]
    }

    public func value<Type>(_ key: String) -> Type? {
        return self[key] as? Type
    }

    public var userMetadata: [String: Any] {
        return self["user_metadata"] as? [String: Any] ?? [:]
    }

    public var appMetadata: [String: Any] {
        return self["app_metadata"] as? [String: Any] ?? [:]
    }

    required public init(id: String, name: String, nickname: String, pictureURL: URL, createdAt: Date, email: String?, emailVerified: Bool, givenName: String?, familyName: String?, attributes: [String: Any], identities: [Identity]) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.pictureURL = pictureURL
        self.createdAt = createdAt

        self.email = email
        self.emailVerified = emailVerified
        self.givenName = givenName
        self.familyName = familyName

        self.additionalAttributes = attributes
        self.identities = identities
    }

    convenience required public init?(json: [String: Any]) {
        guard
            let id = json["user_id"] as? String ?? json["sub"] as? String,
            let name = json["name"] as? String,
            let nickname = json["nickname"] as? String,
            let picture = json["picture"] as? String, let pictureURL = URL(string: picture),
            let dateString = json["created_at"] as? String ?? json["updated_at"] as? String, let createdAt = date(from: dateString)
            else { return nil }
        let email = json["email"] as? String
        let emailVerified = json["email_verified"] as? Bool ?? false
        let givenName = json["given_name"] as? String
        let familyName = json["family_name"] as? String
        let identityValues = json["identities"] as? [[String: Any]] ?? []
        let identities = identityValues.flatMap { Identity(json: $0) }
        let keys = Set(["user_id", "name", "nickname", "picture", "created_at", "email", "email_verified", "given_name", "family_name", "identities"])
        var values: [String: Any] = [:]
        json.forEach { key, value in
            guard !keys.contains(key) else { return }
            values[key] = value
        }
        let attributes = values
        self.init(id: id, name: name, nickname: nickname, pictureURL: pictureURL, createdAt: createdAt, email: email, emailVerified: emailVerified, givenName: givenName, familyName: familyName, attributes: attributes, identities: identities)
    }

}
