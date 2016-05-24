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
public class _ObjectiveAuthenticationAPI: NSObject {

    private let authentication: Authentication

    public convenience init(clientId: String, url: NSURL) {
        self.init(clientId: clientId, url: url, session: NSURLSession.sharedSession())
    }

    public init(clientId: String, url: NSURL, session: NSURLSession) {
        self.authentication = Authentication(clientId: clientId, url: url, session: session)
    }

    @objc(loginWithUsername:password:connection:scope:parameters:callback:)
    public func login(username: String, password: String, connection: String, scope: String, parameters: [String: AnyObject]?, callback: (NSError?, Credentials?) -> ()) {
        self.authentication
            .login(username, password: password, connection: connection, scope: scope, parameters: parameters ?? [:])
            .start(handleResult(callback))
    }

    @objc(createUserWithEmail:username:password:connection:userMetadata:callback:)
    public func createUser(email: String, username: String?, password: String, connection: String, userMetadata: [String: AnyObject]?, callback: (NSError?, [String: AnyObject]?) -> ()) {
        self.authentication
            .createUser(email, username: username, password: password, connection: connection, userMetadata: userMetadata)
            .start { result in
                switch result {
                case .Success(let user):
                    var info: [String: AnyObject] = [
                        "email": user.email,
                        "verified": user.verified,
                    ]
                    if let username = user.username {
                        info["username"] = username
                    }
                    callback(nil, info)
                case .Failure(let cause):
                    callback(cause.foundationError, nil)
                }
            }
    }

    @objc(resetPasswordWithEmail:connection:callback:)
    public func resetPassword(email: String, connection: String, callback: NSError? -> ()) {
        self.authentication
            .resetPassword(email, connection: connection)
            .start(handleResult(callback))
    }

    @objc(signUpWithEmail:username:password:connection:userMetadata:scope:parameters:callback:)
    public func signUp(email: String, username: String?, password: String, connection: String, userMetadata: [String: AnyObject]?, scope: String, parameters: [String: AnyObject]?, callback: (NSError?, Credentials?) -> ()) {
        self.authentication
            .signUp(email, username: username, password: password, connection: connection, userMetadata: userMetadata, scope: scope, parameters: parameters ?? [:])
            .start(handleResult(callback))
    }

    @objc(startPasswordlessWithCodeToEmail:connection:callback:)
    public func startPasswordlessCode(email email: String, connection: String, callback: NSError? -> ()) {
        self.authentication
            .startPasswordless(email: email, type: .Code, connection: connection)
            .start(handleResult(callback))
    }

    @objc(startPasswordlessWithLinkToEmail:connection:callback:)
    public func startPasswordlessLink(email email: String, connection: String, callback: NSError? -> ()) {
        self.authentication
            .startPasswordless(email: email, type: .iOSLink, connection: connection)
            .start(handleResult(callback))
    }

    @objc(startPasswordlessWithCodeToPhoneNumber:connection:callback:)
    public func startPasswordlessCode(phoneNumber phoneNumber: String, connection: String, callback: NSError? -> ()) {
        self.authentication
            .startPasswordless(phoneNumber: phoneNumber, type: .Code, connection: connection)
            .start(handleResult(callback))
    }

    @objc(startPasswordlessWithLinkToPhoneNumber:connection:callback:)
    public func startPasswordlessLink(phoneNumber phoneNumber: String, connection: String, callback: NSError? -> ()) {
        self.authentication
            .startPasswordless(phoneNumber: phoneNumber, type: .iOSLink, connection: connection)
            .start(handleResult(callback))
    }

    @objc(tokenInfoFromToken:callback:)
    public func tokenInfo(token: String, callback: (NSError?, UserProfile?) -> ()) {
        self.authentication.tokenInfo(token).start(handleResult(callback))
    }

    @objc(userInfoWithToken:callback:)
    public func userInfo(token: String, callback: (NSError?, UserProfile?) -> ()) {
        self.authentication.userInfo(token).start(handleResult(callback))
    }

    @objc(loginSocialWithToken:connection:scope:parameters:callback:)
    public func loginSocial(token: String, connection: String, scope: String, parameters: [String: AnyObject]?, callback: (NSError?, Credentials?) -> ()) {

        self.authentication
            .loginSocial(token, connection: connection, scope: scope, parameters: parameters ?? [:])
            .start(handleResult(callback))
    }

}

private func handleResult<T>(callback: (NSError?, T?) -> ()) -> Result<T, Authentication.Error> -> () {
    return { result in
        switch result {
        case .Success(let payload):
            callback(nil, payload)
        case .Failure(let cause):
            callback(cause.foundationError, nil)
        }
    }
}

private func handleResult(callback: (NSError?) -> ()) -> Result<Void, Authentication.Error> -> () {
    return { result in
        if case .Failure(let cause) = result {
            callback(cause.foundationError)
            return
        }
        callback(nil)
    }
}