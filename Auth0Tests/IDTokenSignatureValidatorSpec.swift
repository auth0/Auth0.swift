import Foundation
import Quick
import Nimble
import JWTDecode

@testable import Auth0

class IDTokenSignatureValidatorSpec: IDTokenValidatorBaseSpec {
    
    override class func spec() {
        let domain = self.domain

        beforeEach {
            URLProtocol.registerClass(StubURLProtocol.self)
        }

        afterEach {
            NetworkStub.clearStubs()
            URLProtocol.unregisterClass(StubURLProtocol.self)
        }

        describe("signature validation") {
            let signatureValidator = IDTokenSignatureValidator(context: validatorContext)
            
            context("algorithm support") {
                it("should support RS256") {
                    NetworkStub.addStub(condition: { $0.isJWKSPath(domain) }, response: jwksResponse())
                    
                    let jwt = generateJWT(alg: "RS256")
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
                
                it("should not support other algorithms") {
                    let alg = "HS256"
                    let jwt = generateJWT(alg: alg)
                    let expectedError = IDTokenSignatureValidator.ValidationError.invalidAlgorithm(actual: alg, expected: "RS256")
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.localizedDescription).to(equal(expectedError.localizedDescription))
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
                            expect(error?.localizedDescription).to(equal(expectedError.localizedDescription))
                            done()
                        }
                    }
                }

                it("should fail with an incorrect signature") {
                    NetworkStub.addStub(condition: { $0.isJWKSPath(domain) }, response: jwksResponse())
                    
                    let jwt = generateJWT(alg: "RS256", signature: "foo")
                    let expectedError = IDTokenSignatureValidator.ValidationError.invalidSignature
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.localizedDescription).to(equal(expectedError.localizedDescription))
                            done()
                        }
                    }
                }
            }
            
            context("kid validation") {
                let jwt = generateJWT()
                let expectedError = IDTokenSignatureValidator.ValidationError.missingPublicKey(kid: Kid)
                
                it("should fail if the jwk has no kid") {
                    NetworkStub.addStub(condition: { $0.isJWKSPath(domain) }, response: jwksResponse(kid: nil))
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.localizedDescription).to(equal(expectedError.localizedDescription))
                            done()
                        }
                    }
                }
                
                it("should fail if the jwk kid does not match the jwt kid") {
                    NetworkStub.addStub(condition: { $0.isJWKSPath(domain) }, response: jwksResponse(kid: "abc123"))
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.localizedDescription).to(equal(expectedError.localizedDescription))
                            done()
                        }
                    }
                }
                
                it("should fail if the keys cannot be retrieved") {
                    NetworkStub.addStub(condition: { $0.isJWKSPath(domain) }, response: apiFailureResponse())
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.localizedDescription).to(equal(expectedError.localizedDescription))
                            done()
                        }
                    }
                }
            }
        }
    }
    
}
