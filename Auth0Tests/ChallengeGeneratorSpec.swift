import Foundation
import Quick
import Nimble

@testable import Auth0

class ChallengeGeneratorSpec: QuickSpec {

    override class func spec() {

        describe("test vector") {
            let seed: [UInt8] = [116, 24, 223, 180, 151, 153, 224, 37, 79, 250, 96, 125, 216, 173,
                                 187, 186, 22, 212, 37, 77, 105, 214, 191, 240, 91, 88, 5, 88, 83,
                                 132, 141, 121]
            let data = Data(bytes: seed, count: seed.count * MemoryLayout<UInt8>.size)
            let verifier = data.encodeBase64URLSafe()

            let generator = ChallengeGenerator(verifier: verifier)

            it("should convert verifier to base 64 url-safe") {
                expect(generator.verifier) == "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
            }

            it("should generate challenge") {
                expect(generator.challenge) == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
            }
        }

        var generator: ChallengeGenerator!

        beforeEach {
            generator = try! ChallengeGenerator()
        }

        it("should always return SHA 256 method") {
            expect(generator.method) == "S256"
        }

        it("should always generate the same challenge") {
            let challenge = generator.challenge
            expect(generator.challenge) == challenge
        }

        it("should return verifier as base64 url-safe") {
            expect(generator.verifier.count) == 43
            expect(generator.verifier).to(beURLSafeBase64())
        }

        it("should return challenge as base64 url-safe") {
            expect(generator.challenge).to(beURLSafeBase64())
        }

        it("should return a different verifier for a different generator") {
            let anotherGenerator = try! ChallengeGenerator()
            expect(generator.verifier).toNot(equal(anotherGenerator.verifier))
        }

        it("should return a different challenge for different generator") {
            let anotherGenerator = try! ChallengeGenerator()
            expect(generator.challenge).toNot(equal(anotherGenerator.challenge))
        }

        describe("when secure random bytes are not available") {

            it("should throw instead of using a predictable verifier") {
                expect { try ChallengeGenerator(randomBytes: { _ in nil }) }
                    .to(throwError(ChallengeGeneratorError.randomBytesUnavailable))
            }

            it("should throw when the system returns fewer bytes than requested") {
                expect { try ChallengeGenerator(randomBytes: { _ in Data(count: 16) }) }
                    .to(throwError(ChallengeGeneratorError.randomBytesUnavailable))
            }

            it("should ask for 32 bytes") {
                var requested: Int?
                _ = try? ChallengeGenerator(randomBytes: { count in
                    requested = count
                    return nil
                })
                expect(requested) == 32
            }

            it("should build the verifier from the bytes it is given") {
                let bytes = Data(repeating: 0xAB, count: 32)
                let fromBytes = try! ChallengeGenerator(randomBytes: { _ in bytes })
                expect(fromBytes.verifier) == "q6urq6urq6urq6urq6urq6urq6urq6urq6urq6urq6s"
                expect(fromBytes.challenge) == ChallengeGenerator(verifier: fromBytes.verifier).challenge
            }
        }
    }
}
