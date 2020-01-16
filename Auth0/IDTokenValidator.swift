// IDTokenValidator.swift
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

protocol JWTSignatureValidator {
    func validate(_ jwt: JWT, callback: @escaping (LocalizedError?) -> Void)
}

protocol JWTClaimValidator {
    func validate(_ jwt: JWT) -> LocalizedError?
}

struct IDTokenValidator {
    static let defaultLeeway: Int = 60 * 1000 // Default leeway is 60 seconds

    private let signatureValidator: JWTSignatureValidator
    private let claimsValidator: JWTClaimValidator
    private let context: IDTokenValidatorContext

    init(signatureValidator: JWTSignatureValidator,
         claimsValidator: JWTClaimValidator,
         context: IDTokenValidatorContext) {
        self.signatureValidator = signatureValidator
        self.claimsValidator = claimsValidator
        self.context = context
    }

    func validate(_ jwt: JWT, callback: @escaping (LocalizedError?) -> Void) {
        signatureValidator.validate(jwt) { error in
            if let error = error { return callback(error) }
            callback(self.claimsValidator.validate(jwt))
        }
    }
}

enum IDTokenDecodingError: LocalizedError {
    case missingToken
    case cannotDecode

    var errorDescription: String? {
        switch self {
        case .missingToken: return "ID token is required but missing"
        case .cannotDecode: return "ID token could not be decoded"
        }
    }
}

func validate(idToken: String?,
              context: IDTokenValidatorContext,
              signatureValidator: JWTSignatureValidator? = nil, // for testing
              claimsValidator: JWTClaimValidator? = nil,
              callback: @escaping (LocalizedError?) -> Void) {
    guard let idToken = idToken else { return callback(IDTokenDecodingError.missingToken) }
    guard let jwt = try? decode(jwt: idToken) else { return callback(IDTokenDecodingError.cannotDecode) }
    let validator = IDTokenValidator(signatureValidator: signatureValidator ?? IDTokenSignatureValidator(context: context),
                                     claimsValidator: claimsValidator ?? IDTokenClaimsValidator(validators: []),
                                     context: context)
    validator.validate(jwt, callback: callback)
}
