import Foundation
import Quick
import Nimble

@testable import Auth0

class JWTAlgorithmSpec: QuickSpec {

    override func spec() {
        let jwk = generateRSAJWK()
        
        describe("signature validation") {
            context("RS256") {
                let alg = "RS256"
                
                it("should return true with a correct RS256 signature") {
                    let jwt = generateJWT(alg: alg)
                    
                    expect(JWTAlgorithm.rs256.verify(jwt, using: jwk)).to(beTrue())
                }
                
                it("should return false with an empty signature") {
                    let jwt = generateJWT(alg: alg, signature: "")
                    
                    expect(JWTAlgorithm.rs256.verify(jwt, using: jwk)).to(beFalse())
                }
                
                it("should return false with an incorrect signature") {
                    let jwt = generateJWT(alg: alg, signature: "abc123")
                    
                    expect(JWTAlgorithm.rs256.verify(jwt, using: jwk)).to(beFalse())
                }
            }
        }
    }

}
