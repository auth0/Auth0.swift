// ChallengeGeneratorSpec.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
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

import Quick
import Nimble

@testable import Auth0

class ChallengeGeneratorSpec: QuickSpec {

    override func spec() {

        describe("test vector") {
            let seed: [UInt8] = [116, 24, 223, 180, 151, 153, 224, 37, 79, 250, 96, 125, 216, 173,
                                 187, 186, 22, 212, 37, 77, 105, 214, 191, 240, 91, 88, 5, 88, 83,
                                 132, 141, 121]
            let verifier = NSData(bytes: seed, length: seed.count * sizeof(UInt8))

            let generator = A0SHA256ChallengeGenerator(verifier: verifier)

            it("should convert verifier to base 64 url-safe") {
                expect(generator.verifier) == "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
            }

            it("should generate challenge") {
                expect(generator.challenge) == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
            }
        }

        var generator: A0SHA256ChallengeGenerator!

        beforeEach {
            generator = A0SHA256ChallengeGenerator()
        }

        it("should always return SHA 256 method") {
            expect(generator.method) == "S256"
        }

        it("should always generate the same challenge") {
            let challenge = generator.challenge
            expect(generator.challenge) == challenge
        }

        it("should return verifier as base64 url-safe") {
            expect(generator.verifier).to(beURLSafeBase64())
        }

        it("should return challenge as base64 url-safe") {
            expect(generator.challenge).to(beURLSafeBase64())
        }

    }
}

func beURLSafeBase64() -> MatcherFunc<String> {
    return MatcherFunc { expression, failureMessage in
        failureMessage.postfixMessage = "be url safe base64"
        let set = NSMutableCharacterSet()
        set.formUnionWithCharacterSet(.alphanumericCharacterSet())
        set.addCharactersInString("-_/")
        set.invert()
        if let actual = try expression.evaluate() where actual.rangeOfCharacterFromSet(set) == nil {
            return true
        }
        return false
    }
}
