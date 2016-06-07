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

func authenticationObject<T: JSONObjectPayload>(response: Response, callback: Request<T, Authentication.Error>.Callback) {
    switch response.result {
    case .Success(let payload):
        if let dictionary = payload as? [String: AnyObject], let object = T(json: dictionary) {
            callback(.Success(result: object))
        } else {
            callback(.Failure(error: .InvalidResponse(response: response.data)))
        }
    case .Failure(let cause):
        callback(.Failure(error: authenticationError(response.data, cause: cause)))
    }
}

func databaseUser(response: Response, callback: Request<DatabaseUser, Authentication.Error>.Callback) {
    switch response.result {
    case .Success(let payload):
        if let dictionary = payload as? [String: AnyObject], let email = dictionary["email"] as? String {
            let username = dictionary["username"] as? String
            let verified = dictionary["email_verified"] as? Bool ?? false
            callback(.Success(result: (email: email, username: username, verified: verified)))
        } else {
            callback(.Failure(error: .InvalidResponse(response: response.data)))
        }
    case .Failure(let cause):
        callback(.Failure(error: authenticationError(response.data, cause: cause)))
    }
}

func noBody(response: Response, callback: Request<Void, Authentication.Error>.Callback) {
    switch response.result {
    case .Success:
        callback(.Success(result: ()))
    case .Failure(let cause):
        callback(.Failure(error: authenticationError(response.data, cause: cause)))
    }
}

private func authenticationError(data: NSData?, cause: Response.Error) -> Authentication.Error {
    switch cause {
    case .InvalidJSON(let data):
        return .InvalidResponse(response: data)
    case .ServerError(let status, let data) where (400...500).contains(status) && data != nil:
        if
            let json = try? NSJSONSerialization.JSONObjectWithData(data!, options: []),
            let payload = json as? [String: AnyObject] {
            return payloadError(payload, cause: cause)
        } else {
            return .RequestFailed(cause: cause)
        }
    default:
        return .RequestFailed(cause: cause)
    }
}

private func payloadError(payload: [String: AnyObject], cause: ErrorType) -> Authentication.Error {
    if let code = payload["error"] as? String, let description = payload["error_description"] as? String {
        return .Response(code: code, description: description, name: nil, extras: nil)
    }

    if let code = payload["code"] as? String, let description = payload["description"] as? String {
        let name = payload["name"] as? String
        var extras = payload
        ["code", "description", "name"].forEach { extras.removeValueForKey($0) }
        return .Response(code: code, description: description, name: name, extras: extras)
    }

    return .RequestFailed(cause: cause)
}
