// Credentials.swift
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
 User's credentials obtained from Auth0.
 What values are available depends on what type of Auth request you perfomed,
 so if you used WebAuth (`/authorize` call) the `response_type` and `scope` will determine what tokens you get
 */
@objc(A0Credentials)
public class Credentials: NSObject, JSONObjectPayload {

    /// Token used that allows calling to the requested APIs (audience sent on Auth)
    public let accessToken: String?
    /// Type of the access token
    public let tokenType: String?
    /// When the access_token expires
    public let expiresIn: Date?
    /// If the API allows you to request new access tokens and the scope `offline_access` was included on Auth
    public let refreshToken: String?

    // Token that details the user identity after authentication
    public let idToken: String?

    public init(accessToken: String? = nil, tokenType: String? = nil, idToken: String? = nil, refreshToken: String? = nil, expiresIn: Date? = nil) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }

    convenience required public init(json: [String: Any]) {
        var expiresIn: Date?
        switch json["expires_in"] {
        case let string as String:
            guard let double = Double(string) else { break }
            expiresIn = Date(timeIntervalSinceNow: double)
        case let int as Int:
            expiresIn = Date(timeIntervalSinceNow: Double(int))
        case let double as Double:
            expiresIn = Date(timeIntervalSinceNow: double)
        default:
            expiresIn = nil
        }
        self.init(accessToken: json["access_token"] as? String, tokenType: json["token_type"] as? String, idToken: json["id_token"] as? String, refreshToken: json["refresh_token"] as? String, expiresIn: expiresIn)
    }

}
