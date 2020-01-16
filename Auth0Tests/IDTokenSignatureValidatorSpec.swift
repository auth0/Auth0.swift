// IDTokenSignatureValidatorSpec.swift
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
import Quick
import Nimble
import OHHTTPStubs

@testable import Auth0

class IDTokenSignatureValidatorSpec: IDTokenValidatorBaseSpec {
    
    override func spec() {
        let domain = self.domain
        
        describe("signature validation") {
            let signatureValidator = IDTokenSignatureValidator(context: validatorContext)
            
            context("algorithm support") {
                beforeEach {
                    stub(condition: isJWKSPath(domain)) { _ in jwksResponse() }
                }
                
                it("should support RS256") {
                    let jwt = generateJWT(alg: "RS256")
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }

                it("should not support other algorithms") {
                    let jwt = generateJWT(alg: "AES256")
                                        
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            let expectedError = IDTokenSignatureValidator.ValidationError.invalidAlgorithm(actual: "", expected: "")
                            
                            expect(error).to(matchError(expectedError))
                            done()
                        }
                    }
                }
            }
            
            context("kid validation") {
                let jwt = generateJWT()
                let expectedError = IDTokenSignatureValidator.ValidationError.missingPublicKey(kid: "")
                
                it("should fail if the kid is not present") {
                    stub(condition: isJWKSPath(domain)) { _ in jwksResponse(kid: nil) }
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            done()
                        }
                    }
                }
                
                it("should fail if the kid does not match") {
                    stub(condition: isJWKSPath(domain)) { _ in jwksResponse(kid: "abc123") }
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            done()
                        }
                    }
                }
                
                it("should fail if the keys cannot be retrieved") {
                    stub(condition: isJWKSPath(domain)) { _ in jwksErrorResponse() }
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            done()
                        }
                    }
                }
            }
        }
    }
    
}
