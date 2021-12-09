import Foundation
import Quick
import Nimble
import JWTDecode
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif

@testable import Auth0

class IDTokenSignatureValidatorSpec: IDTokenValidatorBaseSpec {
    
    override func spec() {
        let domain = self.domain

        beforeEach {
            stub(condition: isHost(domain)) { _ in catchAllResponse() }.name = "YOU SHALL NOT PASS!"
        }

        afterEach {
            HTTPStubs.removeAllStubs()
        }

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
                    stub(condition: isJWKSPath(domain)) { _ in jwksResponse() }
                    
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
                    stub(condition: isJWKSPath(domain)) { _ in jwksResponse(kid: nil) }
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.localizedDescription).to(equal(expectedError.localizedDescription))
                            done()
                        }
                    }
                }
                
                it("should fail if the jwk kid does not match the jwt kid") {
                    stub(condition: isJWKSPath(domain)) { _ in jwksResponse(kid: "abc123") }
                    
                    waitUntil { done in
                        signatureValidator.validate(jwt) { error in
                            expect(error).to(matchError(expectedError))
                            expect(error?.localizedDescription).to(equal(expectedError.localizedDescription))
                            done()
                        }
                    }
                }
                
                it("should fail if the keys cannot be retrieved") {
                    stub(condition: isJWKSPath(domain)) { _ in apiFailureResponse() }
                    
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
