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
import JWTDecode
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif

@testable import Auth0

@available(iOS 10.0, macOS 10.12, *)
class IDTokenSignatureValidatorSpec: IDTokenValidatorBaseSpec {
    
    override func spec() {
        let domain = self.domain
        
        describe("signature validation") {
            let signatureValidator = IDTokenSignatureValidator(context: validatorContext)
            
            context("algorithm support") {
                it("should support RS256") {
                    stub(condition: isJWKSPath(domain)) { _ in jwksResponse() }
                    
                    let jwt = generateJWT(alg: "RS256")
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
                
                it("should support HS256") {
                    let jwtString = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE1MTYyMzkwMjJ9.tbDepxpstvGdW8TC3G8zg4B6rUYAOvfzdceoH48wgRQ"
                    let jwt = try! decode(jwt: jwtString)
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
                
                it("should not support other algorithms") {
                    let alg = "ES256"
                    let jwt = generateJWT(alg: alg)
                    let expectedError = IDTokenSignatureValidator.ValidationError.invalidAlgorithm(actual: alg, expected: "RS256")
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.errorDescription).to(equal(expectedError.errorDescription))
                            done()
                        }
                    }
                }
                
                it("should not support none") {
                    let alg = "none"
                    let jwt = generateJWT(alg: alg)
                    let expectedError = IDTokenSignatureValidator.ValidationError.invalidAlgorithm(actual: alg, expected: "RS256")
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.errorDescription).to(equal(expectedError.errorDescription))
                            done()
                        }
                    }
                }
            }
            
            context("kid validation") {
                let jwt = generateJWT()
                let expectedError = IDTokenSignatureValidator.ValidationError.missingPublicKey(kid: Kid)
                
                it("should fail if the jwk has no kid") {
                    stub(condition: isJWKSPath(domain)) { _ in jwksResponse(kid: nil) }
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.errorDescription).to(equal(expectedError.errorDescription))
                            done()
                        }
                    }
                }
                
                it("should fail if the jwk kid does not match the jwt kid") {
                    stub(condition: isJWKSPath(domain)) { _ in jwksResponse(kid: "abc123") }
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.errorDescription).to(equal(expectedError.errorDescription))
                            done()
                        }
                    }
                }
                
                it("should fail if the keys cannot be retrieved") {
                    stub(condition: isJWKSPath(domain)) { _ in jwksErrorResponse() }
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.errorDescription).to(equal(expectedError.errorDescription))
                            done()
                        }
                    }
                }
            }
        }
    }
    
}
