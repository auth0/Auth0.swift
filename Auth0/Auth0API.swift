// Auth0API.swift
//
// Copyright (c) 2015 Auth0 (http://auth0.com)
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

/**
*   Auth0 API helper class for *Objective-C*. If you are using *Swift* just use *Auth0* struct or global functions
*/
public class Auth0API: NSObject {

    let token: String
    let api: API

    /**
    Creates a new helper with a jwt for Auth0 API.
    The Auth0 account domain will be obtained from `Info.plist` file entry with key `Auth0Domain`

    - parameter token: for Auth0 API v2

    - returns: new helper instance
    */
    public init(token: String) {
        self.token = token
        self.api = Auth0.sharedInstance.api
    }

    /**
    Creates a new helper with a jwt for Auth0 API and an account domain

    - parameter domain: of the Auth0 account
    - parameter token:  for Auth0 API v2

    - returns: new helper instance
    */
    public init(domain: String, token: String) {
        self.token = token
        self.api = Auth0(domain: domain).api
    }

    /**
    Updates a user calling `PATCH /users/:id`

    - parameter id:         of the user to update
    - parameter parameters: that hold the attributes of the user to update
    - parameter callback:   that will be called with the result of the request
    */
    @objc public func updateUser(id: String, parameters: [String: AnyObject], callback: (NSError?, [String: AnyObject]?) -> ()) {
        api
        .users(token)
        .update(id, parameters: parameters)
        .responseJSON(callback)
    }

    /**
    Finds a user calling `GET /users/:id`

    - parameter id:            of the user to find
    - parameter fields:        to be included/excluded from the response
    - parameter includeFields: that tells if the fields listed should be included or not in the response
    - parameter callback:      that will be called with the result of the request
    */
    @objc public func findUser(id: String, fields: [String]? = nil, includeFields: Bool = true, callback: (NSError?, [String: AnyObject]?) -> ()) {
        api
        .users(token)
        .find(id, fields: fields, includeFields: includeFields)
        .responseJSON(callback)
    }
}
