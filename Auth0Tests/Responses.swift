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

func authResponse(accessToken accessToken: String, idToken: String? = nil) -> OHHTTPStubsResponse {
    var json = [
        "access_token": accessToken,
        "token_type": "bearer",
    ]

    if let token = idToken {
        json["id_token"] = token
    }
    return OHHTTPStubsResponse(JSONObject: json, statusCode: 200, headers: nil)
}

func createdUser(email email: String, username: String? = nil, verified: Bool = true) -> OHHTTPStubsResponse {
    var json: [String: AnyObject] = [
        "email": email,
        "email_verified": verified ? "true" : "false",
        ]

    if let username = username {
        json["username"] = username
    }
    return OHHTTPStubsResponse(JSONObject: json, statusCode: 200, headers: nil)
}

func authFailure(code code: String, description: String, name: String? = nil) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(JSONObject: ["code": code, "description": description, "statusCode": 400, "name": name ?? code], statusCode: 400, headers: nil)
}

func authFailure(error error: String, description: String) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(JSONObject: ["error": error, "error_description": description], statusCode: 400, headers: nil)
}