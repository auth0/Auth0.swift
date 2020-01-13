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
            
            let jwk = generateRSAJWK(from: TestKeys.rsaPublic)
            
            if #available(iOS 10, OSX 10.12, tvOS 10, watchOS 3, *) {
                context("successful generation") {
                    it("should generate a RSA public key") {
                        let publicKey = jwk.rsaPublicKey!
                        let keyAttributes = SecKeyCopyAttributes(publicKey) as! [String: Any]
                        
                        expect(keyAttributes[String(kSecAttrKeyType)] as? String).to(equal(String(kSecAttrKeyTypeRSA)))
                    }
                }
            }
            
            context("unsuccessful generation") {
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
