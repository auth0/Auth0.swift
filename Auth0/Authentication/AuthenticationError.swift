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
public class AuthenticationError: Auth0Error, CustomStringConvertible {

    /**
     Additional information about the error
     - seeAlso: `code` & `description` properties
     */
    public let info: [String: AnyObject]

    public required init(string: String? = nil, statusCode: Int = 0) {
        self.info = [
            "code": string != nil ? NonJSONError : EmptyBodyError,
            "description": string ?? "Empty response body",
            "statusCode": statusCode
        ]
    }

    public required init(info: [String: AnyObject]) {
        self.info = info
    }

    /**
     Auth0 error code if the server returned one or an internal library code (e.g.: when the server could not be reached)
     */
    public var code: String {
        let code = self.info["error"] ?? self.info["code"]
        return code as? String ?? UnknownError
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

        guard self.code == UnknownError else { return "Received error with code \(self.code)" }

        return "Failed with unknown error \(self.info)"
    }

}

extension AuthenticationError: FoundationErrorConvertible {
    static let FoundationDomain = "com.auth0.authentication"
    static let FoundationUserInfoKey = "com.auth0.authentication.error.info"
    
    public func newFoundationError() -> NSError {
        return NSError(domain: AuthenticationError.FoundationDomain, code: 1, userInfo: [
            NSLocalizedDescriptionKey: self.description,
            AuthenticationError.FoundationUserInfoKey: self,
            ])
    }
}