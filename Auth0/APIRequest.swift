// APIRequest.swift
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
import Alamofire

/// Key of the status code to be included in `NSError`'s userInfo
public let APIRequestErrorStatusCodeKey = "com.auth0.api.v2.status_code"
/// Key of the response error object to be included in `NSError`'s userInfo
public let APIRequestErrorErrorKey = "com.auth0.api.v2.error"

/**
Auth0.swift error codes

- Failed:         the request failed
- InvalidPayload: couldn't convert request body to JSON
*/
public enum APIRequestErrorCode: Int {
    case Failed = 0, InvalidPayload = 1
}

func errorWithCode(code: APIRequestErrorCode, userInfo: [String: AnyObject]? = nil) -> NSError {
    return NSError(domain: "com.auth0.api", code: code.rawValue, userInfo: userInfo)
}

/**
*  Auth0 API request object
*/
public struct APIRequest<T> {

    var error: NSError?
    var request: Alamofire.Request?
    var builder: ((payload: AnyObject?) -> T?)?

    init(request: Alamofire.Request, builder: (payload: AnyObject?) -> T?) {
        self.request = request
        self.builder = builder
    }

    init(error: NSError) {
        self.error = error
        self.request = nil
        self.builder = nil
    }

    /**
    Register a new callback for the request's JSON response

    :param: callback to be called when a response is received or an error occurs. It can yield the error that caused the request to fail or server's JSON response if it's successful
    */
    public func responseJSON(callback: (error: NSError?, payload:T?) -> ()) {
        switch(request, error) {
        case let (.None, .Some(error)):
            callback(error: error, payload: nil)
        case let (.Some(request), .None):
            request.responseJSON { _, resp, payload, err in
                switch (resp, payload, err) {
                case (_, nil, let error):
                    callback(error: error, payload: nil)
                case (let response, _, nil) where response != nil && 200...299 ~= response!.statusCode:
                    if let responseObject = self.builder?(payload: payload) {
                        callback(error: nil, payload: responseObject)
                    } else {
                        callback(error: errorWithCode(.InvalidPayload, userInfo: [NSLocalizedDescriptionKey: "Failed to obtain JSON from \(payload)"]), payload: nil)
                    }
                case (let response, _, nil) where response != nil && 400...599 ~= response!.statusCode && payload != nil:
                    let info = [
                        NSLocalizedDescriptionKey: "Request to \(request.request.URL) failed with status code \(response?.statusCode)",
                        APIRequestErrorErrorKey: payload!,
                        APIRequestErrorStatusCodeKey: response!.statusCode
                    ]
                    callback(error: errorWithCode(.Failed, userInfo: info), payload: nil)
                default:
                    callback(error: errorWithCode(.Failed, userInfo: [NSLocalizedDescriptionKey: "Request to \(request.request.URL) failed"]), payload: nil)
                }
            }
        default:
            callback(error: errorWithCode(.Failed, userInfo: [NSLocalizedDescriptionKey: "Request failed with no clear reason."]), payload: nil)
        }
    }
}
