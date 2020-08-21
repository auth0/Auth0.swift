// JWKSpec.swift
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

import Foundation
import Quick
import Nimble
import OHHTTPStubs

@testable import Auth0

class JWKSpec: QuickSpec {
    
    override func spec() {
        
        describe("public key generation") {
            
            let jwk = generateRSAJWK()
            
            if #available(iOS 10.0, macOS 10.12, *) {
                context("successful generation") {
                    it("should generate a RSA public key") {
                        let publicKey = JWK(keyType: "RSA",
                                            keyId: "NUZFNkFDNUVDNzIxMjAyQTU5RUEzQ0UyMEQ2Mjc5OUZFREFCQ0E2MA",
                                            usage: "sig",
                                            algorithm: JWTAlgorithm.rs256.rawValue,
                                            certUrl: nil,
                                            certThumbprint: nil,
                                            certChain: nil,
                                            rsaModulus: "42xFiJGFLj6e8PgJ-zDQE_KhXNscWFHmJylilVhpD0KUoNKict4IUBvmLYrKMiFLggBS-ttadXeJn7XMnsu6Dz8OzE6r9ELxjZK9sljwx-KWn3ojX8XB8c4LB4NLCEzcwAmE-1zEymJSRg7GJ1g5CHQ_uPeZgxPpEKg5XbrVjZO0KmKE2vCIEVFJIxXNIIu-yC4zR0dPLLEN0lPDZLwwYVRF5y9F_WzDX8fr2nGPQQHQdebBHe_ystvlNc1RdZvyM7BjN9z0l3CXTyR18bLNhJdRDU39NvS7IzGmnqL3WLAwZGtJ6rMhYCPsj-Dla4tUJCy6Yc4V7Gr8zBGQWmLKlQ",
                                            rsaExponent: "AQAB").rsaPublicKey
                        
                        expect(publicKey).notTo(beNil())
                        
                        let keyAttributes = SecKeyCopyAttributes(publicKey!) as! [String: Any]
                        
                        expect(keyAttributes[String(kSecAttrKeyType)] as? String).to(equal(String(kSecAttrKeyTypeRSA)))
                    }
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
                                                    rsaModulus: jwk.rsaModulus,
                                                    rsaExponent: jwk.rsaExponent)
                    
                    expect(jwkWithInvalidKeyType.rsaPublicKey).to(beNil())
                }
                
                it("should fail to generate a public key given an invalid algorithm") {
                    let jwkWithInvalidAlgorithm = JWK(keyType: jwk.keyType,
                                                      keyId: jwk.keyId,
                                                      usage: jwk.usage,
                                                      algorithm: "ES256",
                                                      certUrl: nil,
                                                      certThumbprint: nil,
                                                      certChain: nil,
                                                      rsaModulus: jwk.rsaModulus,
                                                      rsaExponent: jwk.rsaExponent)
                    
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
                                                      rsaModulus: jwk.rsaModulus,
                                                      rsaExponent: jwk.rsaExponent)
                    
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
                                                    rsaModulus: "###",
                                                    rsaExponent: jwk.rsaExponent)
                    
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
                                                     rsaModulus: jwk.rsaModulus,
                                                     rsaExponent: "###")
                    
                    expect(jwkWithInvalidExponent.rsaPublicKey).to(beNil())
                }
            }
        }
        
    }
    
}
