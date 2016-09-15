// Auth0Authentication.swift
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

struct Auth0Authentication: Authentication {
    let clientId: String
    let url: NSURL
    var telemetry: Telemetry
    var logger: Logger?

    let session: NSURLSession

    init(clientId: String, url: NSURL, session: NSURLSession = NSURLSession.sharedSession(), telemetry: Telemetry = Telemetry()) {
        self.clientId = clientId
        self.url = url
        self.session = session
        self.telemetry = telemetry
    }

    func login(usernameOrEmail username: String, password: String, multifactorCode: String?, connection: String, scope: String, parameters: [String: AnyObject]) -> Request<Credentials, AuthenticationError> {
        let resourceOwner = NSURL(string: "/oauth/ro", relativeToURL: self.url)!
        var payload: [String: AnyObject] = [
            "username": username,
            "password": password,
            "connection": connection,
            "grant_type": "password",
            "scope": scope,
            "client_id": self.clientId,
            ]
        payload["mfa_code"] = multifactorCode
        parameters.forEach { key, value in payload[key] = value }
        return Request(session: session, url: resourceOwner, method: "POST", handle: authenticationObject, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }


    func createUser(email email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: AnyObject]? = nil) -> Request<DatabaseUser, AuthenticationError> {
        var payload: [String: AnyObject] = [
            "email": email,
            "password": password,
            "connection": connection,
            "client_id": self.clientId,
            ]
        payload["username"] = username
        payload["user_metadata"] = userMetadata

        let createUser = NSURL(string: "/dbconnections/signup", relativeToURL: self.url)!
        return Request(session: session, url: createUser, method: "POST", handle: databaseUser, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func resetPassword(email email: String, connection: String) -> Request<Void, AuthenticationError> {
        let payload = [
            "email": email,
            "connection": connection,
            "client_id": self.clientId
        ]
        let resetPassword = NSURL(string: "/dbconnections/change_password", relativeToURL: self.url)!
        return Request(session: session, url: resetPassword, method: "POST", handle: noBody, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func signUp(email email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: AnyObject]?, scope: String, parameters: [String: AnyObject]) -> ConcatRequest<DatabaseUser, Credentials, AuthenticationError> {
        let first = createUser(email: email, username: username, password: password, connection: connection, userMetadata: userMetadata)
        let second = login(usernameOrEmail: email, password: password, connection: connection, scope: scope, parameters: parameters)
        return ConcatRequest(first: first, second: second)
    }

    func startPasswordless(email email: String, type: PasswordlessType, connection: String, parameters: [String: AnyObject]) -> Request<Void, AuthenticationError> {
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
        return Request(session: session, url: start, method: "POST", handle: noBody, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func startPasswordless(phoneNumber phoneNumber: String, type: PasswordlessType, connection: String) -> Request<Void, AuthenticationError> {
        let payload: [String: AnyObject] = [
            "phone_number": phoneNumber,
            "connection": connection,
            "send": type.rawValue,
            "client_id": self.clientId,
            ]
        let start = NSURL(string: "/passwordless/start", relativeToURL: self.url)!
        return Request(session: session, url: start, method: "POST", handle: noBody, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func tokenInfo(token token: String) -> Request<Profile, AuthenticationError> {
        let payload: [String: AnyObject] = ["id_token": token]
        let tokenInfo = NSURL(string: "/tokeninfo", relativeToURL: self.url)!
        return Request(session: session, url: tokenInfo, method: "POST", handle: authenticationObject, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func userInfo(token token: String) -> Request<Profile, AuthenticationError> {
        let userInfo = NSURL(string: "/userinfo", relativeToURL: self.url)!
        return Request(session: session, url: userInfo, method: "GET", handle: authenticationObject, headers: ["Authorization": "Bearer \(token)"], logger: self.logger, telemetry: self.telemetry)
    }

    func loginSocial(token token: String, connection: String, scope: String, parameters: [String: AnyObject]) -> Request<Credentials, AuthenticationError> {
        var payload: [String: AnyObject] = [
            "access_token": token,
            "connection": connection,
            "scope": scope,
            "client_id": self.clientId,
            ]
        parameters.forEach { key, value in payload[key] = value }
        let accessToken = NSURL(string: "/oauth/access_token", relativeToURL: self.url)!
        return Request(session: session, url: accessToken, method: "POST", handle: authenticationObject, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func tokenExchange(withParameters parameters: [String: AnyObject]) -> Request<Credentials, AuthenticationError> {
        var payload: [String: AnyObject] = [
            "client_id": self.clientId
        ]
        parameters.forEach { payload[$0] = $1 }
        let token = NSURL(string: "/oauth/token", relativeToURL: self.url)!
        return Request(session: session, url: token, method: "POST", handle: authenticationObject, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func tokenExchange(withCode code: String, codeVerifier: String, redirectURI: String) -> Request<Credentials, AuthenticationError> {
        return self.tokenExchange(withParameters: [
            "code": code,
            "code_verifier": codeVerifier,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
            ])
    }
}
