// IDTokenValidatorSpec.swift
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
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif

@testable import Auth0

@available(iOS 10.0, macOS 10.12, *)
class IDTokenValidatorSpec: IDTokenValidatorBaseSpec {

    override func spec() {
        let domain = self.domain
        let validatorContext = self.validatorContext
        let mockSignatureValidator = MockSuccessfulIDTokenSignatureValidator()
        let mockClaimsValidator = MockSuccessfulIDTokenClaimsValidator()
        
        describe("top level validation api") {
            
            context("sanity checks") {
                it("should fail to validate a nil id token") {
                    let expectedError = IDTokenDecodingError.missingToken
                    
                    waitUntil { done in
                        validate(idToken: nil,
                                 with: validatorContext,
                                 signatureValidator: mockSignatureValidator,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.errorDescription).to(equal(expectedError.errorDescription))
                            done()
                        }
                    }
                }
            }
            
            context("id token decoding") {
                let expectedError = IDTokenDecodingError.cannotDecode
                
                it("should fail to decode an empty id token") {
                    waitUntil { done in
                        validate(idToken: "",
                                 with: validatorContext,
                                 signatureValidator: mockSignatureValidator,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.errorDescription).to(equal(expectedError.errorDescription))
                            done()
                        }
                    }
                }
                
                it("should fail to decode a malformed id token") {
                    waitUntil { done in
                        validate(idToken: "a.b.c.d.e",
                                 with: validatorContext,
                                 signatureValidator: mockSignatureValidator,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.errorDescription).to(equal(expectedError.errorDescription))
                            done()
                        }
                    }
                }
                
                it("should fail to decode an id token with an empty signature") {
                    waitUntil { done in
                        validate(idToken: "a.b.", // alg == none, not supported by us
                                 with: validatorContext,
                                 signatureValidator: mockSignatureValidator,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.errorDescription).to(equal(expectedError.errorDescription))
                            done()
                        }
                    }

                }
                
                it("should fail to decode an id token with no signature") {
                    waitUntil { done in
                        validate(idToken: "a.b",
                                 with: validatorContext,
                                 signatureValidator: mockSignatureValidator,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.errorDescription).to(equal(expectedError.errorDescription))
                            done()
                        }
                    }
                }
            }
            
            context("signature validation") {
                beforeEach {
                    stub(condition: isJWKSPath(domain)) { _ in jwksResponse() }
                }
                
                it("should validate a token signed with RS256") {
                    let jwt = generateJWT(alg: "RS256")
                    
                    waitUntil { done in
                        validate(idToken: jwt.string,
                                 with: validatorContext,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
                
                it("should validate a token signed with HS256") {
                    let jwt = generateJWT(alg: "HS256")
                    
                    waitUntil { done in
                        validate(idToken: jwt.string,
                                 with: validatorContext,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
                
                it("should not validate a token signed with an unsupported algorithm") {
                    let jwt = generateJWT(alg: "ES256")
                    
                    waitUntil { done in
                        validate(idToken: jwt.string,
                                 with: validatorContext,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).toNot(beNil())
                            done()
                        }
                    }
                }
                
                it("should not validate an unsigned token") {
                    let jwt = generateJWT(alg: "none")
                    
                    waitUntil { done in
                        validate(idToken: jwt.string,
                                 with: validatorContext,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).toNot(beNil())
                            done()
                        }
                    }
                }
            }
            
            context("claims validation") {
                let aud = ["e31f6f9827c187e8aebdb0839a0c963a"]
                
                it("should validate a token with default claims") {
                    let jwt = generateJWT(aud: aud, azp: nil, nonce: nil, maxAge: nil, authTime: nil)
                    let context = IDTokenValidatorContext(issuer: validatorContext.issuer,
                                                          audience: aud[0],
                                                          jwksRequest: validatorContext.jwksRequest,
                                                          leeway: validatorContext.leeway,
                                                          maxAge: nil,
                                                          nonce: nil,
                                                          organization: nil)
                    
                    waitUntil { done in
                        validate(idToken: jwt.string,
                                 with: context,
                                 signatureValidator: mockSignatureValidator) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
                
                it("should validate a token with azp") {
                    let azp = "0af84213b28a5aee38e693e2e37447cc"
                    let aud = ["891fdf19ef753d822b2ef2dfd5d959eb", "3cf22ab1358d8099c6fe59da79b0027b", azp]
                    let jwt = generateJWT(aud: aud, azp: azp, nonce: nil, maxAge: nil, authTime: nil)
                    let context = IDTokenValidatorContext(issuer: validatorContext.issuer,
                                                          audience: aud[2],
                                                          jwksRequest: validatorContext.jwksRequest,
                                                          leeway: validatorContext.leeway,
                                                          maxAge: nil,
                                                          nonce: nil,
                                                          organization: nil)
                    
                    waitUntil { done in
                        validate(idToken: jwt.string,
                                 with: context,
                                 signatureValidator: mockSignatureValidator) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
                
                it("should validate a token with nonce") {
                    let nonce = "a1b2c3d4e5"
                    let jwt = generateJWT(aud: aud, azp: nil, nonce: nonce, maxAge: nil, authTime: nil)
                    let context = IDTokenValidatorContext(issuer: validatorContext.issuer,
                                                          audience: aud[0],
                                                          jwksRequest: validatorContext.jwksRequest,
                                                          leeway: validatorContext.leeway,
                                                          maxAge: nil,
                                                          nonce: nonce,
                                                          organization: nil)
                    
                    waitUntil { done in
                        validate(idToken: jwt.string,
                                 with: context,
                                 signatureValidator: mockSignatureValidator) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }

                it("should validate a token with auth time") {
                    let oneSecond = 1_000
                    let authTime = Date()

                    let jwt = generateJWT(
                        aud: aud,
                        azp: nil,
                        nonce: nil,
                        maxAge: oneSecond,
                        authTime: authTime
                    )

                    let context = IDTokenValidatorContext(
                        issuer: validatorContext.issuer,
                        audience: aud[0],
                        jwksRequest: validatorContext.jwksRequest,
                        leeway: oneSecond,
                        maxAge: oneSecond,
                        nonce: nil,
                        organization: nil
                    )

                    waitUntil { done in
                        validate(
                            idToken: jwt.string,
                            with: context,
                            signatureValidator: mockSignatureValidator
                        ) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }

                it("should validate a token with an organization") {
                    let organization = "abc1234"
                    let jwt = generateJWT(aud: aud, azp: nil, nonce: nil, maxAge: nil, authTime: nil, organization: organization)
                    let context = IDTokenValidatorContext(issuer: validatorContext.issuer,
                                                          audience: aud[0],
                                                          jwksRequest: validatorContext.jwksRequest,
                                                          leeway: validatorContext.leeway,
                                                          maxAge: nil,
                                                          nonce: nil,
                                                          organization: organization)
                    
                    waitUntil { done in
                        validate(idToken: jwt.string,
                                 with: context,
                                 signatureValidator: mockSignatureValidator) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
            }
            
        }
        
        describe("id token validator") {
            
            let jwt = generateJWT()
            
            context("threading") {
                it("should execute the signature validator on a worker thread") {
                    let spySignatureValidator = SpyThreadingIDTokenSignatureValidator()
                    let validator = IDTokenValidator(signatureValidator: spySignatureValidator,
                                                     claimsValidator: mockClaimsValidator,
                                                     context: validatorContext)
                    waitUntil { done in
                        validator.validate(jwt) { _ in
                            expect(spySignatureValidator.didExecuteInWorkerThread).to(beTrue())
                            done()
                        }
                    }
                }
                
                it("should execute the claims validator on a worker thread") {
                    let spyClaimsValidator = SpyThreadingIDTokenClaimsValidator()
                    let validator = IDTokenValidator(signatureValidator: mockSignatureValidator,
                                                     claimsValidator: spyClaimsValidator,
                                                     context: validatorContext)
                    waitUntil { done in
                        validator.validate(jwt) { _ in
                            expect(spyClaimsValidator.didExecuteInWorkerThread).to(beTrue())
                            done()
                        }
                    }
                }
                
                it("should call the result callback on the main thread") {
                    let validator = IDTokenValidator(signatureValidator: mockSignatureValidator,
                                                     claimsValidator: mockClaimsValidator,
                                                     context: validatorContext)
                    
                    waitUntil { done in
                        validator.validate(jwt) { _ in
                            expect(Thread.isMainThread).to(beTrue())
                            done()
                        }
                    }
                }
            }
            
            context("validation") {
                it("should pass the validation when the signature validation passes and the claims validation passes") {
                    let validator = IDTokenValidator(signatureValidator: mockSignatureValidator,
                                                     claimsValidator: mockClaimsValidator,
                                                     context: validatorContext)
                    
                    waitUntil { done in
                        validator.validate(jwt) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
                
                it("should fail the validation when the signature validation passes and the claims validation fails") {
                    let expectedError = MockUnsuccessfulIDTokenClaimValidator.ValidationError.errorCase1
                    let validator = IDTokenValidator(signatureValidator: mockSignatureValidator,
                                                     claimsValidator: MockUnsuccessfulIDTokenClaimValidator(),
                                                     context: validatorContext)
                    
                    waitUntil { done in
                        validator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            done()
                        }
                    }
                }
                
                it("should fail the validation when the signature validation fails") {
                    let expectedError = MockUnsuccessfulIDTokenSignatureValidator.ValidationError.errorCase
                    let validator = IDTokenValidator(signatureValidator: MockUnsuccessfulIDTokenSignatureValidator(),
                                                     claimsValidator: mockClaimsValidator,
                                                     context: validatorContext)
                    
                    waitUntil { done in
                        validator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            done()
                        }
                    }
                }
                
                it("should not execute the claims validation when the signature validation fails") {
                    let expectedError = MockUnsuccessfulIDTokenSignatureValidator.ValidationError.errorCase
                    let spyClaimsValidator = SpyUnsuccessfulIDTokenClaimValidator()
                    let validator = IDTokenValidator(signatureValidator: MockUnsuccessfulIDTokenSignatureValidator(),
                                                     claimsValidator: spyClaimsValidator,
                                                     context: validatorContext)
                    
                    waitUntil { done in
                        validator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(spyClaimsValidator.didExecuteValidation).to(beFalse())
                            done()
                        }
                    }
                }
            }

        }
    }

}
