// NSError+Authentication.swift
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

private let domain = "com.auth0.authentication"
private let codeKey = "com.auth0.authentication.error.code"
private let descriptionKey = "com.auth0.authentication.error.description"
private let responseDataKey = "com.auth0.authentication.error.responseData"
private let causeKey = "com.auth0.authentication.error.cause"
private let nameKey = "com.auth0.authentication.error.name"
private let extrasKey = "com.auth0.authentication.error.extras"

@objc(A0AuthenticationErrorCode)
public enum _AuthenticationErrorCode: Int {
    case ErrorResponse = 0
    case InvalidResponse = 1
    case RequestFailed = 2
    case Cancelled = 3
}

extension Authentication.Error {
    var foundationError: NSError {
        var userInfo: [NSObject: AnyObject]
        var errorCode: _AuthenticationErrorCode

        switch self {
        case .Response(let code, let description, let name, let extras):
            errorCode = .ErrorResponse
            userInfo = [
                codeKey: code,
                descriptionKey: description,
                NSLocalizedDescriptionKey: description
            ]
            userInfo[nameKey] = name
            userInfo[extrasKey] = extras
        case .InvalidResponse(let data):
            errorCode = .InvalidResponse
            userInfo = [ NSLocalizedDescriptionKey: "Invalid response from Auth0 server"]
            if let data = data {
                userInfo[responseDataKey] = data
            }
        case .RequestFailed(let cause):
            errorCode = .RequestFailed
            let error = cause as NSError
            userInfo = [
                NSLocalizedDescriptionKey: error.localizedDescription,
                causeKey: error
            ]
        case .Cancelled:
            errorCode = .Cancelled
            userInfo = [ NSLocalizedDescriptionKey: "User cancelled OAuth2 auth session"]
        }

        return NSError(
            domain: domain,
            code: errorCode.rawValue,
            userInfo: userInfo
        )

    }
}

public extension NSError {

    func a0_authenticationError() -> Bool {
        return self.domain == domain
    }

    func a0_authenticationErrorWithCode(code: Int) -> Bool {
        return self.a0_authenticationError() && self.code == code
    }

    func a0_authenticationErrorCode() -> String? {
        return self.userInfo[codeKey] as? String
    }

    func a0_authenticationErrorDescription() -> String? {
        return self.userInfo[descriptionKey] as? String
    }

}