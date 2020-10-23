// IDTokenSignatureValidator.swift
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

#if WEB_AUTH_PLATFORM
import Foundation
import JWTDecode

protocol IDTokenSignatureValidatorContext {
    var issuer: String { get }
    var audience: String { get }
    var jwksRequest: Request<JWKS, AuthenticationError> { get }
}

struct IDTokenSignatureValidator: JWTAsyncValidator {
    enum ValidationError: LocalizedError {
        case invalidAlgorithm(actual: String, expected: String)
        case missingPublicKey(kid: String)
        case invalidSignature

        var errorDescription: String? {
            switch self {
            case .invalidAlgorithm(let actual, let expected):
                return "Signature algorithm of \"\(actual)\" is not supported. Expected the ID token to be signed with \"\(expected)\""
            case .missingPublicKey(let kid): return "Could not find a public key for Key ID (kid) \"\(kid)\""
            case .invalidSignature: return "Invalid ID token signature"
            }
        }
    }

    private let context: IDTokenSignatureValidatorContext

    init(context: IDTokenSignatureValidatorContext) {
        self.context = context
    }

    func validate(_ jwt: JWT, callback: @escaping (LocalizedError?) -> Void) {
        if let error = validateAlg(jwt) { return callback(error) }
        if let error = validateKid(jwt) { return callback(error) }
        let algorithm = jwt.algorithm!
        let kid = jwt.kid!
        context
            .jwksRequest
            .start { result in
                switch result {
                case .success(let jwks):
                    guard let jwk = jwks.key(id: kid) else {
                        return callback(ValidationError.missingPublicKey(kid: kid))
                    }
                    algorithm.verify(jwt, using: jwk) ? callback(nil) : callback(ValidationError.invalidSignature)
                case .failure: callback(ValidationError.missingPublicKey(kid: kid))
            }
        }
    }

    private func validateAlg(_ jwt: JWT) -> LocalizedError? {
        let defaultAlgorithm = JWTAlgorithm.rs256.rawValue
        guard jwt.algorithm != nil else {
            let actualAlgorithm = jwt.header["alg"] as? String
            return ValidationError.invalidAlgorithm(actual: actualAlgorithm.debugDescription, expected: defaultAlgorithm)
        }
        return nil
    }

    private func validateKid(_ jwt: JWT) -> LocalizedError? {
        let kid = jwt.kid
        guard kid != nil else { return ValidationError.missingPublicKey(kid: kid.debugDescription) }
        return nil
    }
}
#endif
