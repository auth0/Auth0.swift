// NSError+Management.swift
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

private let domain = "com.auth0.management"
private let errorKey = "com.auth0.management.error.error"
private let descriptionKey = "com.auth0.management.error.description"
private let codeKey = "com.auth0.management.error.code"
private let statusCodeKey = "com.auth0.management.error.statusCode"
private let responseDataKey = "com.auth0.management.error.responseData"
private let causeKey = "com.auth0.management.error.cause"

@objc(A0ManagementErrorCode)
public enum _ManagementErrorCode: Int {
    case ErrorResponse = 0
    case InvalidResponse = 1
    case RequestFailed = 2
}

extension Management.Error {
    var foundationError: NSError {
        var userInfo: [NSObject: AnyObject]
        var errorCode: _ManagementErrorCode

        switch self {
        case .Response(let error, let description, let code, let statusCode):
            errorCode = .ErrorResponse
            userInfo = [
                codeKey: code,
                errorKey: error,
                statusCodeKey: statusCode,
                descriptionKey: description,
                NSLocalizedDescriptionKey: description
            ]
        case .InvalidResponse(let data):
            errorCode = .InvalidResponse
            userInfo = [ NSLocalizedDescriptionKey: "Invalid JSON response from Auth0 server"]
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
        }

        return NSError(
            domain: domain,
            code: errorCode.rawValue,
            userInfo: userInfo
        )

    }
}

public extension NSError {

    func a0_managementError() -> Bool {
        return self.domain == domain
    }

    func a0_managementErrorWithCode(code: Int) -> Bool {
        return self.a0_authenticationError() && self.code == code
    }

    func a0_managementErrorCode() -> String? {
        return self.userInfo[codeKey] as? String
    }

    func a0_managementDescription() -> String? {
        return self.userInfo[descriptionKey] as? String
    }
    
}