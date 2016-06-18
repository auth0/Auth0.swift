// AuthenticationError.swift
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
 *  Represents an error during a request to Auth0 Authentication API
 */
public struct AuthenticationError: ErrorType, CustomStringConvertible {

    static let UnknownCode = "a0.internal_error.unknown"
    static let NonJSONError = "a0.internal_error.plain"
    static let EmptyBodyError = "a0.internal_error.empty"

    /**
     Additional information about the error
     - seeAlso: `code` & `description` properties
     */
    public let info: [String: AnyObject]

    init(string: String? = nil, statusCode: Int = 0) {
        self.init(info: [
            "code": string != nil ? AuthenticationError.NonJSONError : AuthenticationError.EmptyBodyError,
            "description": string ?? "Empty response body",
            "statusCode": statusCode
        ])
    }

    init(info: [String: AnyObject]) {
        self.info = info
    }

    /**
     Auth0 error code if the server returned one or an internal library code (e.g.: when the server could not be reached)
     */
    public var code: String {
        let code = self.info["error"] ?? self.info["code"]
        return code as? String ?? AuthenticationError.UnknownCode
    }

    /**
     Description of the error
     - important: You should avoid displaying description to the user, it's meant for debugging only.
     */
    public var description: String {
        let description = self.info["description"] ?? self.info["error_description"]
        if let string = description as? String {
            return string
        }

        guard self.code == AuthenticationError.UnknownCode else { return "Received error with code \(self.code)" }

        return "Failed with unknown error \(self.info)"
    }
}