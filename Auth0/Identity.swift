// Identity.swift
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
 Auth0 user identity
 */
@objc(A0Identity)
public class Identity: NSObject, JSONObjectPayload, NSSecureCoding {

    public let identifier: String
    public let provider: String
    public let connection: String

    public let social: Bool
    public let profileData: [String: Any]

    public let accessToken: String?
    public let expiresIn: Date?
    public let accessTokenSecret: String?

    override public var debugDescription: String {
        return "<identity: \(identifier) provider: \(provider) connection: \(connection)>"
    }

    // swiftlint:disable:next function_parameter_count
    public required init(identifier: String, provider: String, connection: String, social: Bool, profileData: [String: Any], accessToken: String?, expiresIn: Date?, accessTokenSecret: String?) {
        self.identifier = identifier
        self.provider = provider
        self.connection = connection
        self.social = social
        self.profileData = profileData
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.accessTokenSecret = accessTokenSecret
    }

    convenience public required init?(json: [String : Any]) {

        guard
            let identifier = json["user_id"] as? String,
            let provider = json["provider"] as? String,
            let connection = json["connection"] as? String
            else { return nil }

        let social = json["isSocial"] as? Bool ?? false
        let profileData = json["profileData"] as? [String: Any] ?? [:]

        let accessToken = json["access_token"] as? String
        let accessTokenSecret = json["access_token_secret"] as? String
        let expiresIn: Date?
        if let expiresInSeconds = json["expires_in"] as? TimeInterval {
            expiresIn = Date(timeIntervalSince1970: expiresInSeconds)
        } else {
            expiresIn = nil
        }
        self.init(identifier: identifier, provider: provider, connection: connection, social: social, profileData: profileData, accessToken: accessToken, expiresIn: expiresIn, accessTokenSecret: accessTokenSecret)
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(identifier, forKey: "user_id")
        aCoder.encode(provider, forKey: "provider")
        aCoder.encode(connection, forKey: "connection")
        aCoder.encode(social, forKey: "isSocial")
        aCoder.encode(profileData, forKey: "profileData")
        aCoder.encode(accessToken, forKey: "access_token")
        aCoder.encode(expiresIn, forKey: "expires_in")
        aCoder.encode(accessTokenSecret, forKey: "access_token_secret")
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        
        guard let identifier = aDecoder.decodeObject(forKey: "user_id") as? String,
            let provider = aDecoder.decodeObject(forKey: "provider") as? String,
            let connection = aDecoder.decodeObject(forKey: "connection") as? String,
            let profileData = aDecoder.decodeObject(forKey: "profileData") as? [String: Any] else {
                return nil
        }
        
        let social = aDecoder.decodeBool(forKey: "isSocial")
        let accessToken = aDecoder.decodeObject(forKey: "access_token") as? String
        let expiresIn = aDecoder.decodeObject(forKey: "expires_in") as? Date
        let accessTokenSecret = aDecoder.decodeObject(forKey: "access_token_secret") as? String
        
        self.init(identifier: identifier, provider: provider, connection: connection, social: social, profileData: profileData, accessToken: accessToken, expiresIn: expiresIn, accessTokenSecret: accessTokenSecret)
    }
}
