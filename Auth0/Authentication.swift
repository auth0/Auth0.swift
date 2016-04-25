// Authentication.swift
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
import Alamofire

public struct Authentication {
    public let clientId: String
    public let url: NSURL

    let manager: Alamofire.Manager

    init(clientId: String, url: NSURL) {
        self.init(clientId: clientId, url: url, manager: Alamofire.Manager.sharedInstance)
    }

    init(clientId: String, url: NSURL, manager: Alamofire.Manager) {
        self.clientId = clientId
        self.url = url
        self.manager = manager
    }

    public enum Error: ErrorType {
        case Response(code: String, description: String)
        case InvalidResponse(response: AnyObject)
        case Unknown(cause: ErrorType)
    }

    public func login(username: String, password: String, connection: String, scope: String = "openid", parameters: [String: AnyObject] = [:]) -> CredentialsRequest {
        var payload: [String: AnyObject] = [
            "username": username,
            "password": password,
            "connection": connection,
            "grant_type": "password",
            "scope": scope,
            "client_id": self.clientId,
        ]
        parameters.forEach { key, value in payload[key] = value }
        let resourceOwner = NSURL(string: "/oauth/ro", relativeToURL: self.url)!
        let request = self.manager.request(.POST, resourceOwner, parameters: payload).validate()
        return CredentialsRequest(request: request)
    }

    public func createUser(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: AnyObject]? = nil) -> CreateUserRequest {
        var payload: [String: AnyObject] = [
            "email": email,
            "password": password,
            "connection": connection,
            "client_id": self.clientId,
        ]
        if let username = username {
            payload["username"] = username
        }

        if let userMetadata = userMetadata {
            payload["user_metadata"] = userMetadata
        }

        let createUser = NSURL(string: "/dbconnections/signup", relativeToURL: self.url)!
        let request = self.manager.request(.POST, createUser, parameters: payload).validate()
        return CreateUserRequest(request: request)
    }

    public func resetPassword(email: String, connection: String) -> ResetPasswordRequest {
        let payload = [
            "email": email,
            "connection": connection,
            "client_id": self.clientId
        ]
        let resetPassword = NSURL(string: "/dbconnections/change_password", relativeToURL: self.url)!
        let request = self.manager.request(.POST, resetPassword, parameters: payload).validate()
        return ResetPasswordRequest(request: request)
    }
}