// Responses.swift
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
import OHHTTPStubs

@testable import Auth0

let UserId = "auth0|\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
let SupportAtAuth0 = "support@auth0.com"
let Support = "support"
let Auth0Phone = "+10123456789"
let Nickname = "sup"
let PictureURL = URL(string: "https://auth0.com/picture")!
let WebsiteURL = URL(string: "https://auth0.com/website")!
let ProfileURL = URL(string: "https://auth0.com/profile")!
let UpdatedAt = "2015-08-19T17:18:01.000Z"
let UpdatedAtUnix = "1440004681"
let UpdatedAtTimestamp = 1440004681.000
let CreatedAt = "2015-08-19T17:18:00.000Z"
let CreatedAtUnix = "1440004680"
let CreatedAtTimestamp = 1440004680.000
let Sub = "auth0|\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
let LocaleUS = "en-US"
let ZoneEST = "US/Eastern"
let OTP = "123456"
let MFAToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
let JWKKid = "key123"

func authResponse(accessToken: String, idToken: String? = nil, expiresIn: Double? = nil) -> OHHTTPStubsResponse {
    var json = [
        "access_token": accessToken,
        "token_type": "bearer",
    ]

    if let token = idToken {
        json["id_token"] = token
    }

    if let expires = expiresIn {
        json["expires_in"] = String(expires)
    }
    return OHHTTPStubsResponse(jsonObject: json, statusCode: 200, headers: ["Content-Type": "application/json"])
}

func createdUser(email: String, username: String? = nil, verified: Bool = true) -> OHHTTPStubsResponse {
    var json: [String: Any] = [
        "email": email,
        "email_verified": verified ? "true" : "false",
        ]

    if let username = username {
        json["username"] = username
    }
    return OHHTTPStubsResponse(jsonObject: json, statusCode: 200, headers: ["Content-Type": "application/json"])
}

func resetPasswordResponse() -> OHHTTPStubsResponse {
    let data = "We've just sent you an email to reset your password.".data(using: .utf8)!
    return OHHTTPStubsResponse(data: data, statusCode: 200, headers: ["Content-Type": "application/json"])
}

func revokeTokenResponse() -> OHHTTPStubsResponse {
    let data = "".data(using: .utf8)!
    return OHHTTPStubsResponse(data: data, statusCode: 200, headers: ["Content-Type": "application/json"])
}

func authFailure(code: String, description: String, name: String? = nil) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(jsonObject: ["code": code, "description": description, "statusCode": 400, "name": name ?? code], statusCode: 400, headers: ["Content-Type": "application/json"])
}

func authFailure(error: String, description: String) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(jsonObject: ["error": error, "error_description": description], statusCode: 400, headers: ["Content-Type": "application/json"])
}

func passwordless(_ email: String, verified: Bool) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(jsonObject: ["email": email, "verified": "\(verified)"], statusCode: 200, headers: ["Content-Type": "application/json"])
}

func tokenInfo() -> OHHTTPStubsResponse {
    return userInfo(withProfile: basicProfile())
}

func userInfo(withProfile profile: [String: Any]) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(jsonObject: profile, statusCode: 200, headers: nil)
}

func basicProfile(_ id: String = UserId, name: String = Support, nickname: String = Nickname, picture: String = PictureURL.absoluteString, createdAt: String = CreatedAtUnix) -> [String: Any] {
    return ["user_id": id, "name": name, "nickname": nickname, "picture": picture, "created_at": createdAt]
}

func basicProfileOIDC(_ sub: String = Sub, name: String = Support, nickname: String = Nickname, picture: String = PictureURL.absoluteString, updatedAt: String = UpdatedAtUnix) -> [String: Any] {
    return ["sub": sub, "name": name, "nickname": nickname, "picture": picture, "updated_at": updatedAt]
}
func managementResponse(_ payload: Any) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(jsonObject: payload, statusCode: 200, headers: ["Content-Type": "application/json"])
}

func managementErrorResponse(error: String, description: String, code: String, statusCode: Int = 400) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(jsonObject: ["code": code, "description": description, "statusCode": statusCode, "error": error], statusCode: Int32(statusCode), headers: ["Content-Type": "application/json"])
}

func jwksResponse(kid: String? = JWKKid) -> OHHTTPStubsResponse {
    let jwk = generateRSAJWK()
    let jwks = ["keys": [
        ["alg": jwk.algorithm,
         "kty": jwk.keyType,
         "use": jwk.usage,
             "n": jwk.rsaModulus,
             "e": jwk.rsaExponent,
             "kid": kid]
        ]
    ]
    
    return OHHTTPStubsResponse(jsonObject: jwks, statusCode: 200, headers: nil)
}

func jwksErrorResponse() -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(jsonObject: [], statusCode: 500, headers: nil)
}
