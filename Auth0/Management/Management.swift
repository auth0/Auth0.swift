// Management.swift
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

/**
 *  Auth0 Management API
 */
public struct Management {
    public let token: String
    public let url: NSURL

    let session: NSURLSession

    init(token: String, url: NSURL, session: NSURLSession = .sharedSession()) {
        self.token = token
        self.url = url
        self.session = session
    }

    public typealias Object = [String: AnyObject]

    /**
     Auth0 Users API v2

     - returns: Users API endpoints
     */
    public func users() -> Users { return Users(management: self) }

    func managementObject(response: Response<ManagementError>, callback: Request<Object, ManagementError>.Callback) {
        do {
            if let dictionary = try response.result() as? Object {
                callback(.Success(result: dictionary))
            } else {
                callback(.Failure(error: ManagementError(string: string(response.data))))
            }
        } catch let error {
            callback(.Failure(error: error))
        }
    }

    func managementObjects(response: Response<ManagementError>, callback: Request<[Object], ManagementError>.Callback) {
        do {
            if let list = try response.result() as? [Object] {
                callback(.Success(result: list))
            } else {
                callback(.Failure(error: ManagementError(string: string(response.data))))
            }
        } catch let error {
            callback(.Failure(error: error))
        }
    }

    var defaultHeaders: [String: String] {
        return [
            "Authorization": "Bearer \(token)"
        ]
    }
}
