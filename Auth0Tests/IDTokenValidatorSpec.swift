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

@testable import Auth0

class IDTokenValidatorSpec: IDTokenValidatorBaseSpec {

    override func spec() {
        let validatorContext = self.validatorContext
        let mockSignatureValidator = MockIDTokenSignatureValidator()
        let mockClaimsValidator = MockIDTokenClaimsValidator()
        
        describe("sanity checks") {
            it("should fail to validate a nil id token") {
                waitUntil { done in
                    validate(idToken: nil,
                             context: validatorContext,
                             signatureValidator: mockSignatureValidator,
                             claimsValidator: mockClaimsValidator) { error in
                        expect(error).to(matchError(IDTokenDecodingError.missingToken))
                        done()
                    }
                }
            }
            
            context("id token decoding") {
                let expectedError = IDTokenDecodingError.cannotDecode
                
                it("should fail to decode an empty id token") {
                    waitUntil { done in
                        validate(idToken: "",
                                 context: validatorContext,
                                 signatureValidator: mockSignatureValidator,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).to(matchError(expectedError))
                            done()
                        }
                    }
                }
                
                it("should fail to decode a malformed id token") {
                    waitUntil { done in
                        validate(idToken: "a.b.c.d.e",
                                 context: validatorContext,
                                 signatureValidator: mockSignatureValidator,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).to(matchError(expectedError))
                            done()
                        }
                    }
                }
                
                it("should fail to decode an id token with an empty signature") {
                    waitUntil { done in
                        validate(idToken: "a.b.", // alg == none, not supported by us
                                 context: validatorContext,
                                 signatureValidator: mockSignatureValidator,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).to(matchError(expectedError))
                            done()
                        }
                    }

                }
                
                it("should fail to decode an id token with no signature") {
                    waitUntil { done in
                        validate(idToken: "a.b",
                                 context: validatorContext,
                                 signatureValidator: mockSignatureValidator,
                                 claimsValidator: mockClaimsValidator) { error in
                            expect(error).to(matchError(expectedError))
                            done()
                        }
                    }
                }
            }
        }
    }
    
}
