// IDTokenValidatorMocks.swift
//
// Copyright (c) 2019 Auth0 (http://auth0.com)
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
import JWTDecode

@testable import Auth0

// MARK: - Signature Validator Mocks

struct MockSuccessfulIDTokenSignatureValidator: JWTAsyncValidator {
    func validate(_ jwt: JWT, callback: @escaping (LocalizedError?) -> Void) {
        callback(nil)
    }
}

struct MockUnsuccessfulIDTokenSignatureValidator: JWTAsyncValidator {
    enum ValidationError: LocalizedError {
        case errorCase
        
        var errorDescription: String? { return "Error message" }
    }
        
    func validate(_ jwt: JWT, callback: @escaping (LocalizedError?) -> Void) {
        callback(ValidationError.errorCase)
    }
}

// MARK: - Claims Validator Mocks

struct MockSuccessfulIDTokenClaimsValidator: JWTValidator {
    func validate(_ jwt: JWT) -> LocalizedError? {
        return nil
    }
}

struct MockSuccessfulIDTokenClaimValidator: JWTValidator {
    func validate(_ jwt: JWT) -> LocalizedError? {
        return nil
    }
}

class MockUnsuccessfulIDTokenClaimValidator: JWTValidator {
    enum ValidationError: LocalizedError {
        case errorCase1
        case errorCase2
        
        var errorDescription: String? { return "Error message" }
    }
    
    let errorCase: ValidationError
    
    init(errorCase: ValidationError = .errorCase1) {
        self.errorCase = errorCase
    }
    
    func validate(_ jwt: JWT) -> LocalizedError? {
        return errorCase
    }
}

class SpyUnsuccessfulIDTokenClaimValidator: MockUnsuccessfulIDTokenClaimValidator {
    var didExecuteValidation: Bool = false
    
    override func validate(_ jwt: JWT) -> LocalizedError? {
        didExecuteValidation = true
        
        return super.validate(jwt)
    }
}
