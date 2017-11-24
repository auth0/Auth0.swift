// ManagementError.swift
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
 *  Represents an error during a request to Auth0 Management API
 */
public class ManagementError: Auth0Error, CustomStringConvertible {

    /**
     Additional information about the error
     - seeAlso: `code` & `description` properties
     */
    public let info: [String: Any]

    /**
     Creates a Auth0 Management API error when the request's response is not JSON

     - parameter string:     string representation of the response (or nil)
     - parameter statusCode: response status code

     - returns: a newly created ManagementError
     */
    public required init(string: String? = nil, statusCode: Int = 0) {
        self.info = [
            "code": string != nil ? nonJSONError : emptyBodyError,
            "description": string ?? "Empty response body",
            "statusCode": statusCode
            ]
    }

    /**
     Creates a Auth0 Management API error from a JSON response

     - parameter info:          JSON response from Auth0
     - parameter statusCode:    Http Status Code of the Response

     - returns: a newly created ManagementError
     */
    public required init(info: [String: Any], statusCode: Int) {
        var values = info
        values["statusCode"] = statusCode
        self.info = values
    }

    /**
     Auth0 error code if the server returned one or an internal library code (e.g.: when the server could not be reached)
     */
    public var code: String { return self.info["code"] as? String ?? unknownError }

    /**
     Description of the error
     - important: You should avoid displaying description to the user, it's meant for debugging only.
     */
    public var description: String {
        if let string = self.info["description"] as? String {
            return string
        }
        return "Failed with unknown error \(self.info)"
    }

}

extension ManagementError: CustomNSError {

    public static let infoKey = "com.auth0.management.error.info"
    public static var errorDomain: String { return "com.auth0.management" }
    public var errorCode: Int { return 1 }
    public var errorUserInfo: [String: Any] {
        return [
            NSLocalizedDescriptionKey: self.description,
            ManagementError.infoKey: self
        ]
    }
}
