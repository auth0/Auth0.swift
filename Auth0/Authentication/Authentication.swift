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

public typealias DatabaseUser = (email: String, username: String?, verified: Bool)

public struct Authentication {
    public let clientId: String
    public let url: NSURL

    let session: NSURLSession

    init(clientId: String, url: NSURL, session: NSURLSession = .sharedSession()) {
        self.clientId = clientId
        self.url = url
        self.session = session
    }

    public enum Error: ErrorType {
        case Response(code: String, description: String)
        case InvalidResponse(response: NSData?)
        case RequestFailed(cause: ErrorType)
    }

    public func login(username: String, password: String, connection: String, scope: String = "openid", parameters: [String: AnyObject] = [:]) -> Request<Credentials, Error> {
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
        return Request(session: session, url: resourceOwner, method: "POST", handle: credentials, payload: payload)
    }


    public func createUser(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: AnyObject]? = nil) -> Request<DatabaseUser, Error> {
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
        return Request(session: session, url: createUser, method: "POST", handle: databaseUser, payload: payload)
    }

    public func resetPassword(email: String, connection: String) -> Request<Void, Error> {
        let payload = [
            "email": email,
            "connection": connection,
            "client_id": self.clientId
        ]
        let resetPassword = NSURL(string: "/dbconnections/change_password", relativeToURL: self.url)!
        return Request(session: session, url: resetPassword, method: "POST", handle: noBody, payload: payload)
    }

    public func signUp(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: AnyObject]? = nil, scope: String = "openid", parameters: [String: AnyObject] = [:]) -> ConcatRequest<DatabaseUser, Credentials, Error> {
        return createUser(email, username: username, password: password, connection: connection, userMetadata: userMetadata)
            .concat(login(email, password: password, connection: connection, scope: scope, parameters: parameters))
    }

    public func startPasswordless(email email: String, type: PasswordlessType = .Code, connection: String = "email", parameters: [String: AnyObject] = [:]) -> Request<Void, Authentication.Error> {
        var payload: [String: AnyObject] = [
            "email": email,
            "connection": connection,
            "send": type.rawValue,
            "client_id": self.clientId,
        ]
        if case .WebLink = type where !parameters.isEmpty {
            payload["authParams"] = parameters
        }

        let start = NSURL(string: "/passwordless/start", relativeToURL: self.url)!
        return Request(session: session, url: start, method: "POST", handle: noBody, payload: payload)
    }

    public func startPasswordless(phoneNumber phoneNumber: String, type: PasswordlessType = .Code, connection: String = "sms") -> Request<Void, Authentication.Error> {
        let payload: [String: AnyObject] = [
            "phone_number": phoneNumber,
            "connection": connection,
            "send": type.rawValue,
            "client_id": self.clientId,
            ]
        let start = NSURL(string: "/passwordless/start", relativeToURL: self.url)!
        return Request(session: session, url: start, method: "POST", handle: noBody, payload: payload)
    }

    public func tokenInfo(token: String) -> Request<UserProfile, Authentication.Error> {
        let payload: [String: AnyObject] = ["id_token": token]
        let tokenInfo = NSURL(string: "/tokeninfo", relativeToURL: self.url)!
        return Request(session: session, url: tokenInfo, method: "POST", handle: profile, payload: payload)
    }

    public func userInfo(token: String) -> Request<UserProfile, Authentication.Error> {
        let userInfo = NSURL(string: "/userinfo", relativeToURL: self.url)!
        return Request(session: session, url: userInfo, method: "GET", handle: profile, headers: ["Authorization": "Bearer \(token)"])
    }

    public enum PasswordlessType: String {
        case Code = "code"
        case WebLink = "link"
        case iOSLink = "link_ios"
        case AndroidLink = "link_android"
    }
}