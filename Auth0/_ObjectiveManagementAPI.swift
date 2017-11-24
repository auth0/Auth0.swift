// _ObjectiveManagementAPI.swift
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

@objc(A0ManagementAPI)
// swiftlint:disable:next type_name
public class _ObjectiveManagementAPI: NSObject {

    private var users: Users

    @objc public init(token: String) {
        self.users = Auth0.users(token: token)
    }

    @objc public convenience init(token: String, url: URL) {
        self.init(token: token, url: url, session: URLSession.shared)
    }

    @objc public init(token: String, url: URL, session: URLSession) {
        self.users = Management(token: token, url: url, session: session)
    }

    @objc(patchUserWithIdentifier:userMetadata:callback:)
    public func patchUser(identifier: String, userMetadata: [String: Any], callback: @escaping (NSError?, [String: Any]?) -> Void) {
        self.users
            .patch(identifier, attributes: UserPatchAttributes().userMetadata(userMetadata))
            .start { result in
                switch result {
                case .success(let payload):
                    callback(nil, payload)
                case .failure(let cause):
                    callback(cause as NSError, nil)
                }
        }
    }

    @objc(linkUserWithIdentifier:withUserUsingToken:callback:)
    public func linkUser(identifier: String, withUserUsingToken token: String, callback: @escaping (NSError?, [[String: Any]]?) -> Void) {
        self.users
            .link(identifier, withOtherUserToken: token)
            .start { result in
                switch result {
                case .success(let payload):
                    callback(nil, payload)
                case .failure(let cause):
                    callback(cause as NSError, nil)
                }
        }
    }

    @objc(unlinkUserWithIdentifier:provider:fromUserId:callback:)
    public func unlink(identifier: String, provider: String, fromUserId userId: String, callback: @escaping (NSError?, [[String: Any]]?) -> Void) {
        self.users
            .unlink(identityId: identifier, provider: provider, fromUserId: userId)
            .start { result in
                switch result {
                case .success(let payload):
                    callback(nil, payload)
                case .failure(let cause):
                    callback(cause as NSError, nil)
                }
        }
    }

    /**
     Avoid Auth0.swift sending its version on every request to Auth0 API.
     By default we collect our libraries and SDKs versions to help us during support and evaluate usage.

     - parameter enabled: if Auth0.swift should send it's version on every request.
     */
    @objc public func setTelemetry(enabled: Bool) {
        self.users.tracking(enabled: enabled)
    }
}
