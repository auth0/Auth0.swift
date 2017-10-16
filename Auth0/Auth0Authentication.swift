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
    let url: URL
    var telemetry: Telemetry
    var logger: Logger?

    let session: URLSession

    init(clientId: String, url: URL, session: URLSession = URLSession.shared, telemetry: Telemetry = Telemetry()) {
        self.clientId = clientId
        self.url = url
        self.session = session
        self.telemetry = telemetry
    }

    // swiftlint:disable:next function_parameter_count
    func login(usernameOrEmail username: String, password: String, multifactorCode: String?, connection: String, scope: String, parameters: [String: Any]) -> Request<Credentials, AuthenticationError> {
        let resourceOwner = URL(string: "/oauth/ro", relativeTo: self.url)!
        var payload: [String: Any] = [
            "username": username,
            "password": password,
            "connection": connection,
            "grant_type": "password",
            "scope": scope,
            "client_id": self.clientId
            ]
        payload["mfa_code"] = multifactorCode
        parameters.forEach { key, value in payload[key] = value }
        return Request(session: session, url: resourceOwner, method: "POST", handle: authenticationObject, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func login(usernameOrEmail username: String, password: String, realm: String, audience: String?, scope: String?) -> Request<Credentials, AuthenticationError> {
        let resourceOwner = URL(string: "/oauth/token", relativeTo: self.url)!
        var payload: [String: Any] = [
            "username": username,
            "password": password,
            "grant_type": "http://auth0.com/oauth/grant-type/password-realm",
            "client_id": self.clientId,
            "realm": realm
            ]
        payload["audience"] = audience
        payload["scope"] = scope
        return Request(session: session, url: resourceOwner, method: "POST", handle: authenticationObject, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func createUser(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: Any]? = nil) -> Request<DatabaseUser, AuthenticationError> {
        var payload: [String: Any] = [
            "email": email,
            "password": password,
            "connection": connection,
            "client_id": self.clientId
            ]
        payload["username"] = username
        payload["user_metadata"] = userMetadata

        let createUser = URL(string: "/dbconnections/signup", relativeTo: self.url)!
        return Request(session: session, url: createUser, method: "POST", handle: databaseUser, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func resetPassword(email: String, connection: String) -> Request<Void, AuthenticationError> {
        let payload = [
            "email": email,
            "connection": connection,
            "client_id": self.clientId
        ]
        let resetPassword = URL(string: "/dbconnections/change_password", relativeTo: self.url)!
        return Request(session: session, url: resetPassword, method: "POST", handle: noBody, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    // swiftlint:disable:next function_parameter_count
    func signUp(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: Any]?, scope: String, parameters: [String: Any]) -> ConcatRequest<DatabaseUser, Credentials, AuthenticationError> {
        let first = createUser(email: email, username: username, password: password, connection: connection, userMetadata: userMetadata)
        let second = login(usernameOrEmail: email, password: password, connection: connection, scope: scope, parameters: parameters)
        return ConcatRequest(first: first, second: second)
    }

    func startPasswordless(email: String, type: PasswordlessType, connection: String, parameters: [String: Any]) -> Request<Void, AuthenticationError> {
        var payload: [String: Any] = [
            "email": email,
            "connection": connection,
            "send": type.rawValue,
            "client_id": self.clientId
            ]
        if case .WebLink = type, !parameters.isEmpty {
            payload["authParams"] = parameters
        }

        let start = URL(string: "/passwordless/start", relativeTo: self.url)!
        return Request(session: session, url: start, method: "POST", handle: noBody, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func startPasswordless(phoneNumber: String, type: PasswordlessType, connection: String) -> Request<Void, AuthenticationError> {
        let payload: [String: Any] = [
            "phone_number": phoneNumber,
            "connection": connection,
            "send": type.rawValue,
            "client_id": self.clientId
            ]
        let start = URL(string: "/passwordless/start", relativeTo: self.url)!
        return Request(session: session, url: start, method: "POST", handle: noBody, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func tokenInfo(token: String) -> Request<Profile, AuthenticationError> {
        let payload: [String: Any] = ["id_token": token]
        let tokenInfo = URL(string: "/tokeninfo", relativeTo: self.url)!
        return Request(session: session, url: tokenInfo, method: "POST", handle: authenticationObject, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func userInfo(token: String) -> Request<Profile, AuthenticationError> {
        let userInfo = URL(string: "/userinfo", relativeTo: self.url)!
        return Request(session: session, url: userInfo, method: "GET", handle: authenticationObject, headers: ["Authorization": "Bearer \(token)"], logger: self.logger, telemetry: self.telemetry)
    }

    func userInfo(withAccessToken accessToken: String) -> Request<UserInfo, AuthenticationError> {
        let userInfo = URL(string: "/userinfo", relativeTo: self.url)!
        return Request(session: session, url: userInfo, method: "GET", handle: authenticationObject, headers: ["Authorization": "Bearer \(accessToken)"], logger: self.logger, telemetry: self.telemetry)
    }

    func loginSocial(token: String, connection: String, scope: String, parameters: [String: Any]) -> Request<Credentials, AuthenticationError> {
        var payload: [String: Any] = [
            "access_token": token,
            "connection": connection,
            "scope": scope,
            "client_id": self.clientId
            ]
        parameters.forEach { key, value in payload[key] = value }
        let accessToken = URL(string: "/oauth/access_token", relativeTo: self.url)!
        return Request(session: session, url: accessToken, method: "POST", handle: authenticationObject, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func tokenExchange(withParameters parameters: [String: Any]) -> Request<Credentials, AuthenticationError> {
        var payload: [String: Any] = [
            "client_id": self.clientId
            ]
        parameters.forEach { payload[$0] = $1 }
        let token = URL(string: "/oauth/token", relativeTo: self.url)!
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

    func renew(withRefreshToken refreshToken: String, scope: String? = nil) -> Request<Credentials, AuthenticationError> {
        var payload: [String: Any] = [
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
            "client_id": self.clientId
        ]
        payload["scope"] = scope
        let oauthToken = URL(string: "/oauth/token", relativeTo: self.url)!
        return Request(session: session, url: oauthToken, method: "POST", handle: authenticationObject, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func revoke(refreshToken: String) -> Request<Void, AuthenticationError> {
        let payload: [String: Any] = [
            "token": refreshToken,
            "client_id": self.clientId
        ]
        let oauthToken = URL(string: "/oauth/revoke", relativeTo: self.url)!
        return Request(session: session, url: oauthToken, method: "POST", handle: noBody, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    func delegation(withParameters parameters: [String : Any]) -> Request<[String : Any], AuthenticationError> {
        var payload: [String: Any] = [
            "client_id": self.clientId,
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer"
        ]
        parameters.forEach { payload[$0] = $1 }
        let delegation = URL(string: "/delegation", relativeTo: self.url)!
        return Request(session: session, url: delegation, method: "POST", handle: plainJson, payload: payload, logger: self.logger, telemetry: self.telemetry)
    }

    #if os(iOS)
    func webAuth(withConnection connection: String) -> WebAuth {
        var safari = SafariWebAuth(clientId: self.clientId, url: self.url, presenter: ControllerModalPresenter(), telemetry: self.telemetry)
        return safari
            .logging(enabled: self.logger != nil)
            .connection(connection)
    }
    #endif
}
