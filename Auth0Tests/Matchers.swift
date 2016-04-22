// Matchers.swift
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
import OHHTTPStubs
import Nimble
import Auth0

func hasAllOf(parameters: [String: String]) -> OHHTTPStubsTestBlock {
    return { request in
        guard let payload = request.a0_payload else { return false }
        return parameters.filter { (key, _) in payload.contains { (name, _) in  key == name } }.reduce(true, combine: { (initial, entry) -> Bool in
            return initial && payload[entry.0] as? String == entry.1
        })
    }
}

func hasNoneOf(parameters: [String: String]) -> OHHTTPStubsTestBlock {
    return !hasAllOf(parameters)
}

func isResourceOwner(domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/oauth/ro")
}


func haveError(code code: String, description: String) -> MatcherFunc<Authentication.Result> {
    return MatcherFunc { expression, failureMessage in
        failureMessage.postfixMessage = "an error response with code <\(code)> and description <\(description)>"
        if let actual = try expression.evaluate(), case .Failure(let cause) = actual, case .Response(let actualCode, let actualDescription) = cause {
            return code == actualCode && description == actualDescription
        }
        return false
    }
}

func haveCredentials(accessToken: String? = nil, _ idToken: String? = nil) -> MatcherFunc<Authentication.Result> {
    return MatcherFunc { expression, failureMessage in
        var message = "a successful authentication result"
        if let accessToken = accessToken {
            message = message.stringByAppendingString(" <access_token: \(accessToken)>")
        }
        if let idToken = idToken {
            message = message.stringByAppendingString(" <id_token: \(idToken)>")
        }
        failureMessage.postfixMessage = message
        if let actual = try expression.evaluate(), case .Success(let credentials) = actual {
            return (accessToken == nil || credentials.accessToken == accessToken) && (idToken == nil || credentials.idToken == idToken)
        }
        return false
    }
}