// _ObjectiveAuthenticationAPI.swift
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

@objc(A0AuthenticationAPI)
// swiftlint:disable:next type_name
public class _ObjectiveAuthenticationAPI: NSObject {

    private var authentication: Authentication

    @objc public override init () {
        self.authentication = Auth0.authentication()
    }

    @objc public convenience init(clientId: String, url: URL) {
        self.init(clientId: clientId, url: url, session: .shared)
    }

    @objc public init(clientId: String, url: URL, session: URLSession) {
        self.authentication = Auth0Authentication(clientId: clientId, url: url, session: session)
    }

    @objc(loginWithUsernameOrEmail:password:connection:scope:parameters:callback:)
    // swiftlint:disable:next function_parameter_count
    public func login(withUsernameOrEmail username: String, password: String, connection: String, scope: String, parameters: [String: Any]?, callback: @escaping (NSError?, Credentials?) -> Void) {
        self.authentication
            .login(usernameOrEmail: username, password: password, connection: connection, scope: scope, parameters: parameters ?? [:])
            .start(handleResult(callback: callback))
    }

    @objc(loginWithUsernameOrEmail:password:realm:audience:scope:parameters:callback:)
    // swiftlint:disable:next function_parameter_count
    public func login(withUsernameOrEmail username: String, password: String, realm: String, audience: String, scope: String, parameters: [String: Any]?, callback: @escaping (NSError?, Credentials?) -> Void) {
        self.authentication
            .login(usernameOrEmail: username, password: password, realm: realm, audience: audience, scope: scope, parameters: parameters ?? [:])
            .start(handleResult(callback: callback))
    }

    @objc(createUserWithEmail:username:password:connection:userMetadata:callback:)
    // swiftlint:disable:next function_parameter_count
    public func createUser(withEmail email: String, username: String?, password: String, connection: String, userMetadata: [String: Any]?, callback: @escaping (NSError?, [String: Any]?) -> Void) {
        self.authentication
            .createUser(email: email, username: username, password: password, connection: connection, userMetadata: userMetadata)
            .start { result in
                switch result {
                case .success(let user):
                    var info: [String: Any] = [
                        "email": user.email,
                        "verified": user.verified
                    ]
                    if let username = user.username {
                        info["username"] = username
                    }
                    callback(nil, info)
                case .failure(let cause):
                    callback(cause as NSError, nil)
                }
            }
    }

#if os(iOS) // TODO: Remove on next major (this method shouldn't be here)
    @objc(resumeAuthWithURL:options:)
    public static func resume(_ url: URL, options: [A0URLOptionsKey: Any]) -> Bool {
        return resumeAuth(url, options: options)
    }
#endif

    @objc(renewWithRefreshToken:scope:callback:)
    public func renew(WithRefreshToken refreshToken: String, scope: String, callback: @escaping (NSError?, Credentials?) -> Void) {
        self.authentication
            .renew(withRefreshToken: refreshToken, scope: scope)
            .start(handleResult(callback: callback))
    }

    @objc(resetPasswordWithEmail:connection:callback:)
    public func resetPassword(withEmail email: String, connection: String, callback: @escaping (NSError?) -> Void) {
        self.authentication
            .resetPassword(email: email, connection: connection)
            .start(handleResult(callback: callback))
    }

    @objc(signUpWithEmail:username:password:connection:userMetadata:scope:parameters:callback:)
    // swiftlint:disable:next function_parameter_count
    public func signUp(withEmail email: String, username: String?, password: String, connection: String, userMetadata: [String: Any]?, scope: String, parameters: [String: Any]?, callback: @escaping (NSError?, Credentials?) -> Void) {
        self.authentication
            .signUp(email: email, username: username, password: password, connection: connection, userMetadata: userMetadata, scope: scope, parameters: parameters ?? [:])
            .start(handleResult(callback: callback))
    }

    @objc(startPasswordlessWithCodeToEmail:connection:callback:)
    public func startPasswordlessCode(email: String, connection: String, callback: @escaping (NSError?) -> Void) {
        self.authentication
            .startPasswordless(email: email, type: .Code, connection: connection)
            .start(handleResult(callback: callback))
    }

    @objc(startPasswordlessWithLinkToEmail:connection:callback:)
    public func startPasswordlessLink(email: String, connection: String, callback: @escaping (NSError?) -> Void) {
        self.authentication
            .startPasswordless(email: email, type: .iOSLink, connection: connection)
            .start(handleResult(callback: callback))
    }

    @objc(startPasswordlessWithCodeToPhoneNumber:connection:callback:)
    public func startPasswordlessCode(phoneNumber: String, connection: String, callback: @escaping (NSError?) -> Void) {
        self.authentication
            .startPasswordless(phoneNumber: phoneNumber, type: .Code, connection: connection)
            .start(handleResult(callback: callback))
    }

    @objc(startPasswordlessWithLinkToPhoneNumber:connection:callback:)
    public func startPasswordlessLink(phoneNumber: String, connection: String, callback: @escaping  (NSError?) -> Void) {
        self.authentication
            .startPasswordless(phoneNumber: phoneNumber, type: .iOSLink, connection: connection)
            .start(handleResult(callback: callback))
    }

    @objc(tokenInfoFromToken:callback:)
    @available(*, deprecated, message: "see userInfoWithToken:callback:")
    public func tokenInfo(fromToken token: String, callback: @escaping (NSError?, Profile?) -> Void) {
        self.authentication.tokenInfo(token: token).start(handleResult(callback: callback))
    }

    @objc(userInfoWithToken:callback:)
    public func userInfo(withToken token: String, callback: @escaping (NSError?, Profile?) -> Void) {
        self.authentication.userInfo(token: token).start(handleResult(callback: callback))
    }

    @objc(loginSocialWithToken:connection:scope:parameters:callback:)
    public func loginSocial(withToken token: String, connection: String, scope: String, parameters: [String: Any]?, callback: @escaping (NSError?, Credentials?) -> Void) {

        self.authentication
            .loginSocial(token: token, connection: connection, scope: scope, parameters: parameters ?? [:])
            .start(handleResult(callback: callback))
    }

    /**
     Avoid Auth0.swift sending its version on every request to Auth0 API.
     By default we collect our libraries and SDKs versions to help us during support and evaluate usage.

     - parameter enabled: if Auth0.swift should send it's version on every request.
     */
    public func setTelemetryEnabled(enabled: Bool) {
        self.authentication.tracking(enabled: enabled)
    }
}

private func handleResult<T>(callback: @escaping (NSError?, T?) -> Void) -> (Result<T>) -> Void {
    return { result in
        switch result {
        case .success(let payload):
            callback(nil, payload)
        case .failure(let cause):
            callback(cause as NSError, nil)
        }
    }
}

private func handleResult(callback: @escaping (NSError?) -> Void) -> (Result<Void>) -> Void {
    return { result in
        if case .failure(let cause) = result {
            callback(cause as NSError)
            return
        }
        callback(nil)
    }
}
