// IDTokenValidatorBaseSpec.swift
//
// Copyright (c) 2020 Auth0 (http://auth0.com)
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
import Quick

@testable import Auth0

class IDTokenValidatorBaseSpec: QuickSpec {
    let domain = "tokens-test.auth0.com"
    let clientId = "e31f6f9827c187e8aebdb0839a0c963a"
    let nonce = "a1b2c3d4e5"
    let leeway = 60 * 1000 // 60 seconds
    let maxAge = 1000 // 1 second
    
    // Can't override the initWithInvocation: initializer, because NSInvocation is not available in Swift
    lazy var authentication = Auth0.authentication(clientId: clientId, domain: domain)
    lazy var validatorContext = IDTokenValidatorContext(issuer: "\(URL.a0_url(domain).absoluteString)/",
                                                        audience: clientId,
                                                        jwksRequest: authentication.jwks(),
                                                        leeway: leeway,
                                                        maxAge: maxAge,
                                                        nonce: nonce)
}
