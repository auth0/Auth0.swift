// JWTAlgorithmSpec.swift
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
                
                if #available(iOS 10, OSX 10.12, tvOS 10, watchOS 3, *) {
                    it("should return false with an incorrect signature") {
                        let jwt = generateJWT(alg: alg, signature: "abc123")
                        
                        expect(JWTAlgorithm.rs256.verify(jwt, using: jwk)).to(beFalse())
                    }
                }
            }
            
            context("HS256") {
                let alg = "HS256"
                
                it("should return true with any signature") {
                    let jwt = generateJWT(alg: alg, signature: "abc123")
                    
                    expect(JWTAlgorithm.hs256.verify(jwt, using: jwk)).to(beTrue())
                }
                
                it("should return false with an empty signature") {
                    let jwt = generateJWT(alg: alg, signature: "")
                    
                    expect(JWTAlgorithm.hs256.verify(jwt, using: jwk)).to(beFalse())
                }
            }
        }
    }

}
