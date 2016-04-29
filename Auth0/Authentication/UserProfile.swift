// UserProfile.swift
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

public struct UserProfile {

    public let id: String
    public let name: String
    public let nickname: String
    public let pictureURL: NSURL
    public let createdAt: NSDate

    public let email: String?
    public let emailVerified: Bool
    public let givenName: String?
    public let familyName: String?

    let values: [String: AnyObject]

    public init?(dictionary: [String: AnyObject]) {
        guard
            let id = dictionary["user_id"] as? String,
            let name = dictionary["name"] as? String,
            let nickname = dictionary["nickname"] as? String,
            let picture = dictionary["picture"] as? String, let pictureURL = NSURL(string: picture),
            let date = dictionary["created_at"] as? String, let createdAt = fromSO8601(date)
            else { return nil }
        self.id = id
        self.name = name
        self.nickname = nickname
        self.pictureURL = pictureURL
        self.createdAt = createdAt
        self.email = dictionary["email"] as? String
        self.emailVerified = dictionary["email_verified"] as? Bool ?? false
        self.givenName = dictionary["given_name"] as? String
        self.familyName = dictionary["family_name"] as? String
        self.values = dictionary
    }

    public subscript(key: String) -> AnyObject? {
        return self.values[key]
    }

    public func value<Type>(key: String) -> Type? {
        return self[key] as? Type
    }

    public var userMetadata: [String: AnyObject] {
        return self["user_metadata"] as? [String: AnyObject] ?? [:]
    }

    public var appMetadata: [String: AnyObject] {
        return self["app_metadata"] as? [String: AnyObject] ?? [:]
    }

}

private func fromSO8601(string: String) -> NSDate? {
    let formatter = NSDateFormatter()
    formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
    return formatter.dateFromString(string)
}
