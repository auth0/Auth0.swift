import Foundation
import Quick
import Nimble

@testable import Auth0

class ClaimValidatorsSpec: IDTokenValidatorBaseSpec {
    
    override func spec() {
        
        describe("claims validation") {
            
            let jwt = generateJWT()
            
            context("successful validation") {
                it("should return nil if no claim validator returns an error") {
                    let claimsValidators: [JWTValidator] = [MockSuccessfulIDTokenClaimValidator(),
                                                            MockSuccessfulIDTokenClaimValidator(),
                                                            MockSuccessfulIDTokenClaimValidator()]
                    let claimsValidator = IDTokenClaimsValidator(validators: claimsValidators)
                    
                    expect(claimsValidator.validate(jwt)).to(beNil())
                }
            }
            
            context("unsuccessful validation") {
                it("should return an error if a validation fails") {
                    let claimsValidators: [JWTValidator] = [MockSuccessfulIDTokenClaimValidator(),
                                                            MockSuccessfulIDTokenClaimValidator(),
                                                            MockSuccessfulIDTokenClaimValidator(),
                                                            MockUnsuccessfulIDTokenClaimValidator()]
                    let claimsValidator = IDTokenClaimsValidator(validators: claimsValidators)
                    
                    expect(claimsValidator.validate(jwt)).toNot(beNil())
                }
                
                it("should return the error from the first failed validation") {
                    let claimsValidators: [JWTValidator] = [MockSuccessfulIDTokenClaimValidator(),
                                                            MockUnsuccessfulIDTokenClaimValidator(errorCase: .errorCase2),
                                                            MockSuccessfulIDTokenClaimValidator(),
                                                            MockUnsuccessfulIDTokenClaimValidator(errorCase: .errorCase1)]
                    let claimsValidator = IDTokenClaimsValidator(validators: claimsValidators)
                    let expectedError = MockUnsuccessfulIDTokenClaimValidator.ValidationError.errorCase2
                    
                    expect(claimsValidator.validate(jwt)).to(matchError(expectedError))
                }
                
                it("should not execute further validations past the one that failed") {
                    let firstSpyClaimValidator = SpyUnsuccessfulIDTokenClaimValidator()
                    let secondSpyClaimValidator = SpyUnsuccessfulIDTokenClaimValidator()
                    let claimsValidators: [JWTValidator] = [MockSuccessfulIDTokenClaimValidator(),
                                                            firstSpyClaimValidator,
                                                            secondSpyClaimValidator,
                                                            MockSuccessfulIDTokenClaimValidator()]
                    let claimsValidator = IDTokenClaimsValidator(validators: claimsValidators)
                    
                    _ = claimsValidator.validate(jwt)
                    
                    expect(firstSpyClaimValidator.didExecuteValidation).to(beTrue())
                    expect(secondSpyClaimValidator.didExecuteValidation).to(beFalse())
                }
            }
            
        }
        
        describe("iss validation") {
            
            var issValidator: IDTokenIssValidator!
            let expectedIss = URL.httpsURL(from: domain).absoluteString
            
            beforeEach {
                issValidator = IDTokenIssValidator(issuer: expectedIss)
            }
            
            context("missing iss") {
                it("should return nil if iss is present") {
                    let jwt = generateJWT(iss: expectedIss)
                    
                    expect(issValidator.validate(jwt)).to(beNil())
                }
                
                it("should return an error if iss is missing") {
                    let jwt = generateJWT(iss: nil)
                    let expectedError = IDTokenIssValidator.ValidationError.missingIss
                    let result = issValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
            context("mismatched iss") {
                it("should return an error if iss does not match the domain url") {
                    let iss = "https://samples.auth0.com/"
                    let jwt = generateJWT(iss: iss)
                    let expectedError = IDTokenIssValidator.ValidationError.mismatchedIss(actual: iss,
                                                                                          expected: expectedIss)
                    let result = issValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
        }
        
        describe("sub validation") {
            
            var subValidator: IDTokenSubValidator!
            
            beforeEach {
                subValidator = IDTokenSubValidator()
            }
            
            context("missing sub") {
                it("should return nil if sub is present") {
                    let jwt = generateJWT(sub: "user123")
                    
                    expect(subValidator.validate(jwt)).to(beNil())
                }
                
                it("should return an error if sub is missing") {
                    let jwt = generateJWT(sub: nil)
                    let expectedError = IDTokenSubValidator.ValidationError.missingSub
                    let result = subValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
        }
        
        describe("aud validation") {
            
            var audValidator: IDTokenAudValidator!
            let expectedAud = self.clientId
            
            beforeEach {
                audValidator = IDTokenAudValidator(audience: expectedAud)
            }
            
            context("missing aud") {
                it("should return nil if aud is present") {
                    let jwt = generateJWT(aud: [expectedAud])
                    
                    expect(audValidator.validate(jwt)).to(beNil())
                }
                
                it("should return an error if aud is missing") {
                    let jwt = generateJWT(aud: nil)
                    let expectedError = IDTokenAudValidator.ValidationError.missingAud
                    let result = audValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
            context("mismatched aud (string)") {
                it("should return an error if aud does not match the client id") {
                    let aud = "891fdf19ef753d822b2ef2dfd5d959eb"
                    let jwt = generateJWT(aud: [aud])
                    let expectedError = IDTokenAudValidator.ValidationError.mismatchedAudString(actual: aud,
                                                                                                expected: expectedAud)
                    let result = audValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
            context("mismatched aud (array)") {
                it("should return an error if aud does not match the client id") {
                    let aud = ["891fdf19ef753d822b2ef2dfd5d959eb",
                               "3cf22ab1358d8099c6fe59da79b0027b",
                               "0af84213b28a5aee38e693e2e37447cc"]
                    let jwt = generateJWT(aud: aud)
                    let expectedError = IDTokenAudValidator.ValidationError.mismatchedAudArray(actual: aud,
                                                                                               expected: expectedAud)
                    let result = audValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
        }
        
        describe("exp validation") {
            
            var expValidator: IDTokenExpValidator!
            let leeway = 1000 // 1 second
            let currentTime = Date()
            let expectedExp = currentTime.addingTimeInterval(10000) // 10 seconds
            
            beforeEach {
                expValidator = IDTokenExpValidator(baseTime: currentTime, leeway: leeway)
            }
            
            context("missing exp") {
                it("should return nil if exp is present") {
                    let jwt = generateJWT(exp: expectedExp)
                    
                    expect(expValidator.validate(jwt)).to(beNil())
                }
                
                it("should return an error if exp is missing") {
                    let jwt = generateJWT(exp: nil)
                    let expectedError = IDTokenExpValidator.ValidationError.missingExp
                    let result = expValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
            context("incorrect exp") {
                it("should return an error if exp + leeway is in the present") {
                    let expectedExp = currentTime.addingTimeInterval(-Double(leeway))
                    let jwt = generateJWT(exp: expectedExp)
                    let currentTimeEpoch = currentTime.timeIntervalSince1970
                    let expEpoch = expectedExp.timeIntervalSince1970 + Double(leeway)
                    let expectedError = IDTokenExpValidator.ValidationError.pastExp(baseTime: currentTimeEpoch,
                                                                                    expirationTime: expEpoch)
                    let result = expValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
                
                it("should return an error if exp + leeway is in the past") {
                    let expectedExp = currentTime.addingTimeInterval(-10000) // -10 seconds
                    let jwt = generateJWT(exp: expectedExp)
                    let currentTimeEpoch = currentTime.timeIntervalSince1970
                    let expEpoch = expectedExp.timeIntervalSince1970 + Double(leeway)
                    let expectedError = IDTokenExpValidator.ValidationError.pastExp(baseTime: currentTimeEpoch,
                                                                                    expirationTime: expEpoch)
                    let result = expValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
        }
        
        describe("iat validation") {
            
            var iatValidator: IDTokenIatValidator!
            
            beforeEach {
                iatValidator = IDTokenIatValidator()
            }
            
            context("missing iat") {
                it("should return nil if iat is present") {
                    let jwt = generateJWT(iat: Date())
                    
                    expect(iatValidator.validate(jwt)).to(beNil())
                }
                
                it("should return an error if iat is missing") {
                    let jwt = generateJWT(iat: nil)
                    let expectedError = IDTokenIatValidator.ValidationError.missingIat
                    let result = iatValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
        }
        
        describe("nonce validation") {
            
            var nonceValidator: IDTokenNonceValidator!
            let expectedNonce = "a1b2c3d4e5"
            
            beforeEach {
                nonceValidator = IDTokenNonceValidator(nonce: expectedNonce)
            }
            
            context("missing nonce") {
                it("should return nil if nonce is present") {
                    let jwt = generateJWT(nonce: expectedNonce)
                    
                    expect(nonceValidator.validate(jwt)).to(beNil())
                }
                
                it("should return an error if nonce is missing") {
                    let jwt = generateJWT(nonce: nil)
                    let expectedError = IDTokenNonceValidator.ValidationError.missingNonce
                    let result = nonceValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
            context("mismatched nonce") {
                it("should return an error if nonce does not match the request nonce") {
                    let nonce = "abc123"
                    let jwt = generateJWT(nonce: nonce)
                    let expectedError = IDTokenNonceValidator.ValidationError.mismatchedNonce(actual: nonce,
                                                                                              expected: expectedNonce)
                    let result = nonceValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
        }
        
        describe("azp validation") {
            
            var azpValidator: IDTokenAzpValidator!
            let expectedAzp = self.clientId
            let aud = ["891fdf19ef753d822b2ef2dfd5d959eb",
                       "3cf22ab1358d8099c6fe59da79b0027b",
                       "0af84213b28a5aee38e693e2e37447cc"]
            
            beforeEach {
                azpValidator = IDTokenAzpValidator(authorizedParty: expectedAzp)
            }
            
            context("missing azp") {
                it("should return nil if azp is present") {
                    let jwt = generateJWT(aud: aud, azp: expectedAzp)
                    
                    expect(azpValidator.validate(jwt)).to(beNil())
                }
                
                it("should return an error if azp is missing") {
                    let jwt = generateJWT(aud: aud, azp: nil)
                    let expectedError = IDTokenAzpValidator.ValidationError.missingAzp
                    let result = azpValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
            context("mismatched azp") {
                it("should return an error if azp does not match the client id") {
                    let azp = "abc123"
                    let jwt = generateJWT(aud: aud, azp: azp)
                    let expectedError = IDTokenAzpValidator.ValidationError.mismatchedAzp(actual: azp,
                                                                                          expected: expectedAzp)
                    let result = azpValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
        }
        
        describe("auth time validation") {
            
            var authTimeValidator: IDTokenAuthTimeValidator!
            let leeway = 1000 // 1 second
            let maxAge = 1000 // 1 second
            let currentTime = Date()
            let expectedAuthTime = currentTime.addingTimeInterval(-10000) // -10 seconds
            
            beforeEach {
                authTimeValidator = IDTokenAuthTimeValidator(baseTime: currentTime, leeway: leeway, maxAge: maxAge)
            }
            
            context("auth time request") {
                it("should return nil if max age is present and auth time was requested") {
                    let jwt = generateJWT(maxAge: maxAge, authTime: expectedAuthTime)
                    
                    expect(authTimeValidator.validate(jwt)).to(beNil())
                }
                
                it("should return an error if max age is present and auth time was not requested") {
                    let jwt = generateJWT(maxAge: maxAge, authTime: nil)
                    let expectedError = IDTokenAuthTimeValidator.ValidationError.missingAuthTime
                    let result = authTimeValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
            context("incorrect auth time") {
                it("should return an error if last auth time + max age + leeway is in the present") {
                    let expectedAuthTime = currentTime
                        .addingTimeInterval(-Double(maxAge))
                        .addingTimeInterval(-Double(leeway))
                    let jwt = generateJWT(maxAge: maxAge, authTime: expectedAuthTime)
                    let currentTimeEpoch = currentTime.timeIntervalSince1970
                    let authTimeEpoch = expectedAuthTime.timeIntervalSince1970 + Double(leeway) + Double(maxAge)
                    let expectedError = IDTokenAuthTimeValidator.ValidationError.pastLastAuth(baseTime: currentTimeEpoch,
                                                                                              lastAuthTime: authTimeEpoch)
                    let result = authTimeValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
                
                it("should return an error if last auth time + max age + leeway is in the future") {
                    let expectedAuthTime = currentTime.addingTimeInterval(10000) // 10 seconds
                    let jwt = generateJWT(maxAge: maxAge, authTime: expectedAuthTime)
                    let currentTimeEpoch = currentTime.timeIntervalSince1970
                    let authTimeEpoch = expectedAuthTime.timeIntervalSince1970 + Double(leeway) + Double(maxAge)
                    let expectedError = IDTokenAuthTimeValidator.ValidationError.pastLastAuth(baseTime: currentTimeEpoch,
                                                                                              lastAuthTime: authTimeEpoch)
                    let result = authTimeValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
        }

        describe("organization validation") {
            
            var organizationValidator: IDTokenOrgIdValidator!
            let expectedOrganization = "abc1234"
            
            beforeEach {
                organizationValidator = IDTokenOrgIdValidator(organization: expectedOrganization)
            }
            
            context("missing org_id") {
                it("should return nil if org_id is present") {
                    let jwt = generateJWT(organization: expectedOrganization)
                    
                    expect(organizationValidator.validate(jwt)).to(beNil())
                }
                
                it("should return an error if org_id is missing") {
                    let jwt = generateJWT(organization: nil)
                    let expectedError = IDTokenOrgIdValidator.ValidationError.missingOrgId
                    let result = organizationValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
            context("mismatched org_id") {
                it("should return an error if org_id does not match the request organization") {
                    let organization = "xyz6789"
                    let jwt = generateJWT(organization: organization)
                    let expectedError = IDTokenOrgIdValidator.ValidationError.mismatchedOrgId(actual: organization,
                                                                                              expected: expectedOrganization)
                    let result = organizationValidator.validate(jwt)
                    
                    expect(result).to(matchError(expectedError))
                    expect(result?.localizedDescription).to(equal(expectedError.localizedDescription))
                }
            }
            
        }
        
    }
    
}
