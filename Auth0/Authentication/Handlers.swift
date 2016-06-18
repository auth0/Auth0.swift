// Handlers.swift
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

func authenticationObject<T: JSONObjectPayload>(response: Response<AuthenticationError>, callback: Request<T, AuthenticationError>.Callback) {
    do {
        if let dictionary = try response.result() as? [String: AnyObject], let object = T(json: dictionary) {
            callback(.Success(result: object))
        } else {
            callback(.Failure(error: AuthenticationError(string: string(response.data))))
        }

    } catch let error {
        callback(.Failure(error: error))
    }
}

func databaseUser(response: Response<AuthenticationError>, callback: Request<DatabaseUser, AuthenticationError>.Callback) {
    do {
        if let dictionary = try response.result() as? [String: AnyObject], let email = dictionary["email"] as? String {
            let username = dictionary["username"] as? String
            let verified = dictionary["email_verified"] as? Bool ?? false
            callback(.Success(result: (email: email, username: username, verified: verified)))
        } else {
            callback(.Failure(error: AuthenticationError(string: string(response.data))))
        }

    } catch let error {
        callback(.Failure(error: error))
    }
}

func noBody(response: Response<AuthenticationError>, callback: Request<Void, AuthenticationError>.Callback) {
    do {
        let _ = try response.result()
        callback(.Success(result: ()))
    } catch let error {
        callback(.Failure(error: error))
    }
}