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

public let APIRequestErrorStatusCodeKey = "com.auth0.api.v2.status_code"
public let APIRequestErrorErrorKey = "com.auth0.api.v2.error"

public enum APIRequestErrorCode: Int {
    case Failed = 0, InvalidPayload = 1
}

func errorWithCode(code: APIRequestErrorCode, userInfo: [String: AnyObject]? = nil) -> NSError {
    return NSError(domain: "com.auth0.api", code: code.rawValue, userInfo: userInfo)
}

public class APIRequest<T>: NSObject {

    let request: Alamofire.Request
    let builder: (payload: AnyObject?) -> T?

    init(request: Alamofire.Request, builder: (payload: AnyObject?) -> T?) {
        self.request = request
        self.builder = builder
    }

    public func responseJSON(callback: (error: NSError?, payload:T?) -> ()) {
        self.request.responseJSON { _, resp, payload, err in
            switch (resp, payload, err) {
            case (_, nil, let error):
                callback(error: error, payload: nil)
            case (let response, _, nil) where response != nil && 200...299 ~= response!.statusCode:
                if let responseObject = self.builder(payload: payload) {
                    callback(error: nil, payload: responseObject)
                } else {
                    callback(error: errorWithCode(.InvalidPayload, userInfo: [NSLocalizedDescriptionKey: "Failed to obtain JSON from \(payload)"]), payload: nil)
                }
            case (let response, _, nil) where response != nil && 400...599 ~= response!.statusCode && payload != nil:
                let info = [
                    NSLocalizedDescriptionKey: "Request to \(self.request.request.URL) failed with status code \(response?.statusCode)",
                    APIRequestErrorErrorKey: payload!,
                    APIRequestErrorStatusCodeKey: response!.statusCode
                ]
                callback(error: errorWithCode(.Failed, userInfo: info), payload: nil)
            default:
                callback(error: errorWithCode(.Failed, userInfo: [NSLocalizedDescriptionKey: "Request to \(self.request.request.URL) failed"]), payload: nil)
            }
        }
    }
}
