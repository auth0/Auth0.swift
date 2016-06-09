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

let UserId = "auth0|\(NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: ""))"
let SupportAtAuth0 = "support@auth0.com"
let Support = "support"
let Auth0Phone = "+10123456789"
let Nickname = "sup"
let PictureURL = NSURL(string: "https://auth0.com")!
let CreatedAt = "2015-08-19T17:18:00.123Z"
let CreatedAtTimestamp = 1440004680.123

func authResponse(accessToken accessToken: String, idToken: String? = nil) -> OHHTTPStubsResponse {
    var json = [
        "access_token": accessToken,
        "token_type": "bearer",
    ]

    if let token = idToken {
        json["id_token"] = token
    }
    return OHHTTPStubsResponse(JSONObject: json, statusCode: 200, headers: ["Content-Type": "application/json"])
}

func createdUser(email email: String, username: String? = nil, verified: Bool = true) -> OHHTTPStubsResponse {
    var json: [String: AnyObject] = [
        "email": email,
        "email_verified": verified ? "true" : "false",
        ]

    if let username = username {
        json["username"] = username
    }
    return OHHTTPStubsResponse(JSONObject: json, statusCode: 200, headers: ["Content-Type": "application/json"])
}

func resetPasswordResponse() -> OHHTTPStubsResponse {
    let data = "We've just sent you an email to reset your password.".dataUsingEncoding(NSUTF8StringEncoding)!
    return OHHTTPStubsResponse(data: data, statusCode: 200, headers: ["Content-Type": "application/json"])
}

func authFailure(code code: String, description: String, name: String? = nil) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(JSONObject: ["code": code, "description": description, "statusCode": 400, "name": name ?? code], statusCode: 400, headers: ["Content-Type": "application/json"])
}

func authFailure(error error: String, description: String) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(JSONObject: ["error": error, "error_description": description], statusCode: 400, headers: ["Content-Type": "application/json"])
}

func passwordless(email: String, verified: Bool) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(JSONObject: ["email": email, "verified": "\(verified)"], statusCode: 200, headers: ["Content-Type": "application/json"])
}

func tokenInfo() -> OHHTTPStubsResponse {
    return userInfo()
}

func userInfo() -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(JSONObject: basicProfile(), statusCode: 200, headers: nil)
}

func basicProfile(id: String = UserId, name: String = Support, nickname: String = Nickname, picture: String = PictureURL.absoluteString, createdAt: String = CreatedAt) -> [String: AnyObject] {
    return ["user_id": id, "name": name, "nickname": nickname, "picture": picture, "created_at": createdAt]
}

func managementResponse(payload: AnyObject) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(JSONObject: payload, statusCode: 200, headers: ["Content-Type": "application/json"])
}

func managementErrorResponse(error error: String, description: String, code: String, statusCode: Int = 400) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(JSONObject: ["code": code, "description": description, "statusCode": statusCode, "error": error], statusCode: Int32(statusCode), headers: ["Content-Type": "application/json"])
}
