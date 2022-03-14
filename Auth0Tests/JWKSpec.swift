import Foundation
import Quick
import Nimble

@testable import Auth0

class JWKSpec: QuickSpec {
    
    override func spec() {
        
        describe("public key generation") {
            
            let jwk = generateRSAJWK()
            
            context("successful generation") {
                it("should generate a RSA public key") {
                    let publicKey = JWK(keyType: "RSA",
                                        keyId: "NUZFNkFDNUVDNzIxMjAyQTU5RUEzQ0UyMEQ2Mjc5OUZFREFCQ0E2MA",
                                        usage: "sig",
                                        algorithm: JWTAlgorithm.rs256.rawValue,
                                        certUrl: nil,
                                        certThumbprint: nil,
                                        certChain: nil,
                                        modulus: "42xFiJGFLj6e8PgJ-zDQE_KhXNscWFHmJylilVhpD0KUoNKict4IUBvmLYrKMiFLggBS-ttadXeJn7XMnsu6Dz8OzE6r9ELxjZK9sljwx-KWn3ojX8XB8c4LB4NLCEzcwAmE-1zEymJSRg7GJ1g5CHQ_uPeZgxPpEKg5XbrVjZO0KmKE2vCIEVFJIxXNIIu-yC4zR0dPLLEN0lPDZLwwYVRF5y9F_WzDX8fr2nGPQQHQdebBHe_ystvlNc1RdZvyM7BjN9z0l3CXTyR18bLNhJdRDU39NvS7IzGmnqL3WLAwZGtJ6rMhYCPsj-Dla4tUJCy6Yc4V7Gr8zBGQWmLKlQ",
                                        exponent: "AQAB").rsaPublicKey
                    
                    expect(publicKey).notTo(beNil())
                    
                    let keyAttributes = SecKeyCopyAttributes(publicKey!) as! [String: Any]
                    
                    expect(keyAttributes[String(kSecAttrKeyType)] as? String).to(equal(String(kSecAttrKeyTypeRSA)))
                }
            }
            
            context("unsuccessful generation") {
                it("should fail to generate a public key given an invalid key type") {
                    let jwkWithInvalidKeyType = JWK(keyType: "ECDSA",
                                                    keyId: jwk.keyId,
                                                    usage: jwk.usage,
                                                    algorithm: jwk.algorithm,
                                                    certUrl: nil,
                                                    certThumbprint: nil,
                                                    certChain: nil,
                                                    modulus: jwk.modulus,
                                                    exponent: jwk.exponent)
                    
                    expect(jwkWithInvalidKeyType.rsaPublicKey).to(beNil())
                }
                
                it("should fail to generate a public key given an invalid algorithm") {
                    let jwkWithInvalidAlgorithm = JWK(keyType: jwk.keyType,
                                                      keyId: jwk.keyId,
                                                      usage: jwk.usage,
                                                      algorithm: "HS256",
                                                      certUrl: nil,
                                                      certThumbprint: nil,
                                                      certChain: nil,
                                                      modulus: jwk.modulus,
                                                      exponent: jwk.exponent)
                    
                    expect(jwkWithInvalidAlgorithm.rsaPublicKey).to(beNil())
                }
                
                it("should fail to generate a public key given an unsupported usage") {
                    let jwkWithUnsupportedUsage = JWK(keyType: jwk.keyType,
                                                      keyId: jwk.keyId,
                                                      usage: "enc",
                                                      algorithm: jwk.algorithm,
                                                      certUrl: nil,
                                                      certThumbprint: nil,
                                                      certChain: nil,
                                                      modulus: jwk.modulus,
                                                      exponent: jwk.exponent)
                    
                    expect(jwkWithUnsupportedUsage.rsaPublicKey).to(beNil())
                }
                
                it("should fail to generate a public key given an invalid modulus") {
                    let jwkWithInvalidModulus = JWK(keyType: jwk.keyType,
                                                    keyId: jwk.keyId,
                                                    usage: jwk.usage,
                                                    algorithm: jwk.algorithm,
                                                    certUrl: nil,
                                                    certThumbprint: nil,
                                                    certChain: nil,
                                                    modulus: "###",
                                                    exponent: jwk.exponent)
                    
                    expect(jwkWithInvalidModulus.rsaPublicKey).to(beNil())
                }
                
                it("should fail to generate a public key given an invalid exponent") {
                    let jwkWithInvalidExponent = JWK(keyType: jwk.keyType,
                                                     keyId: jwk.keyId,
                                                     usage: jwk.usage,
                                                     algorithm: jwk.algorithm,
                                                     certUrl: nil,
                                                     certThumbprint: nil,
                                                     certChain: nil,
                                                     modulus: jwk.modulus,
                                                     exponent: "###")
                    
                    expect(jwkWithInvalidExponent.rsaPublicKey).to(beNil())
                }
            }
        }
        
    }
    
}
