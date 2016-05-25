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
public class _ObjectiveManagementAPI: NSObject {

    private let management: Management

    public convenience init(token: String, url: NSURL) {
        self.init(token: token, url: url, session: NSURLSession.sharedSession())
    }

    public init(token: String, url: NSURL, session: NSURLSession) {
        self.management = Management(token: token, url: url, session: session)
    }

    @objc(patchUserWithIdentifier:userMetadata:callback:)
    public func patchUser(identifier: String, userMetadata: [String: AnyObject], callback: (NSError?, [String: AnyObject]?) -> ()) {
        self.management
            .users()
            .patch(identifier, attributes: UserPatchAttributes().userMetadata(userMetadata))
            .start { result in
                switch result {
                case .Success(let payload):
                    callback(nil, payload)
                case .Failure(let cause):
                    callback(cause.foundationError, nil)
                }
        }
    }

    @objc(linkUserWithIdentifier:withUserUsingToken:callback:)
    public func linkUser(identifier: String, withUserUsingToken token: String, callback: (NSError?, [[String: AnyObject]]?) -> ()) {
        self.management
            .users()
            .link(identifier, withOtherUserToken: token)
            .start { result in
                switch result {
                case .Success(let payload):
                    callback(nil, payload)
                case .Failure(let cause):
                    callback(cause.foundationError, nil)
                }
        }
    }

}