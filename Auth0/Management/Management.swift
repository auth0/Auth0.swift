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
     Types of errors that can be returned by Management API

     - Response:        the request was not successful and Auth0 returned an error response with the reeason it failed
     - InvalidResponse: the response returned by Auth0 was not valid
     - RequestFailed:   the request failed
     */
    public enum Error: ErrorType {
        case Response(error: String, description: String, code: String, statusCode: Int)
        case InvalidResponse(response: NSData?)
        case RequestFailed(cause: ErrorType)
    }


    /**
     Auth0 Users API v2

     - returns: Users API endpoints
     */
    public func users() -> Users { return Users(management: self) }

    func managementObject(response: Response, callback: Request<Object, Error>.Callback) {
        switch response.result {
        case .Success(let payload):
            if let dictionary = payload as? Object {
                callback(.Success(result: dictionary))
            } else {
                callback(.Failure(error: .InvalidResponse(response: response.data)))
            }
        case .Failure(let cause):
            callback(.Failure(error: managementError(response.data, cause: cause)))
        }
    }

    func managementObjects(response: Response, callback: Request<[Object], Error>.Callback) {
        switch response.result {
        case .Success(let payload):
            if let list = payload as? [Object] {
                callback(.Success(result: list))
            } else {
                callback(.Failure(error: .InvalidResponse(response: response.data)))
            }
        case .Failure(let cause):
            callback(.Failure(error: managementError(response.data, cause: cause)))
        }
    }

    private func managementError(data: NSData?, cause: Response.Error) -> Error {
        switch cause {
        case .InvalidJSON(let data):
            return .InvalidResponse(response: data)
        case .ServerError(let status, let data) where (400...500).contains(status) && data != nil:
            if
                let json = try? NSJSONSerialization.JSONObjectWithData(data!, options: []),
                let payload = json as? [String: AnyObject], let error = payload["error"] as? String, let message = payload["description"] as? String, let code = payload["code"] as? String {
                return .Response(error: error, description: message, code: code, statusCode: status)
            } else {
                return .RequestFailed(cause: cause)
            }
        default:
            return .RequestFailed(cause: cause)
        }
    }
}
