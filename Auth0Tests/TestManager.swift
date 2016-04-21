// TestManager.swift
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
import Alamofire

let ParameterPropertyKey = "com.auth0.parameter"

class TestManager: Alamofire.Manager {
    override func request(method: Alamofire.Method, _ URLString: URLStringConvertible, parameters: [String : AnyObject]?, encoding: ParameterEncoding, headers: [String : String]?) -> Request {
        let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: URLString.URLString)!)
        mutableURLRequest.HTTPMethod = method.rawValue

        if let headers = headers {
            for (headerField, headerValue) in headers {
                mutableURLRequest.setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }

        if let parameters = parameters {
            NSURLProtocol.setProperty(parameters, forKey: ParameterPropertyKey, inRequest: mutableURLRequest)
        }
        return super.request(encoding.encode(mutableURLRequest, parameters: parameters).0)
    }
}

extension NSURLRequest {
    var a0_payload: [String: AnyObject]? {
        return NSURLProtocol.propertyForKey(ParameterPropertyKey, inRequest: self) as? [String: AnyObject]
    }
}

extension NSMutableURLRequest {
    override var a0_payload: [String: AnyObject]? {
        get {
            return NSURLProtocol.propertyForKey(ParameterPropertyKey, inRequest: self) as? [String: AnyObject]
        }
        set(newValue) {
            if let parameters = newValue {
                NSURLProtocol.setProperty(parameters, forKey: ParameterPropertyKey, inRequest: self)
            }
        }
    }
}