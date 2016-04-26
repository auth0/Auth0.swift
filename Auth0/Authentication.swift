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
    let session: NSURLSession

    init(clientId: String, url: NSURL) {
        self.init(clientId: clientId, url: url, manager: Alamofire.Manager.sharedInstance)
    }

    init(clientId: String, url: NSURL, manager: Alamofire.Manager, session: NSURLSession = NSURLSession.sharedSession()) {
        self.clientId = clientId
        self.url = url
        self.manager = manager
        self.session = session
    }

    public enum Error: ErrorType {
        case Response(code: String, description: String)
        case InvalidResponse(response: AnyObject)
        case Unknown(cause: ErrorType)
    }

    public func login(username: String, password: String, connection: String, scope: String = "openid", parameters: [String: AnyObject] = [:]) -> FoundationRequest<Credentials> {
        let resourceOwner = NSURL(string: "/oauth/ro", relativeToURL: self.url)!
        var payload: [String: AnyObject] = [
            "username": username,
            "password": password,
            "connection": connection,
            "grant_type": "password",
            "scope": scope,
            "client_id": self.clientId,
            ]
        parameters.forEach { key, value in payload[key] = value }
        return FoundationRequest(session: session, url: resourceOwner, method: "POST", execute: credentials, payload: payload)
    }


    public func createUser(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: AnyObject]? = nil) -> FoundationRequest<DatabaseUser> {
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
        return FoundationRequest(session: session, url: createUser, method: "POST", execute: databaseUser, payload: payload)
    }

    public func resetPassword(email: String, connection: String) -> AuthenticationRequest<Void> {
        let payload = [
            "email": email,
            "connection": connection,
            "client_id": self.clientId
        ]
        let resetPassword = NSURL(string: "/dbconnections/change_password", relativeToURL: self.url)!
        return AuthenticationRequest(manager: manager, url: resetPassword, method: .POST, execute: noBody, payload: payload)
    }

    public func signUp(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: AnyObject]? = nil, scope: String = "openid", parameters: [String: AnyObject] = [:]) -> ConcatRequest<DatabaseUser, Credentials> {
        return createUser(email, username: username, password: password, connection: connection, userMetadata: userMetadata)
            .concat(login(email, password: password, connection: connection, scope: scope, parameters: parameters))
    }
}