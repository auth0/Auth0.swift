import Quick
import Nimble

@testable import Auth0

class ChallengeGeneratorSpec: QuickSpec {

    override func spec() {

        describe("test vector") {
            let seed: [UInt8] = [116, 24, 223, 180, 151, 153, 224, 37, 79, 250, 96, 125, 216, 173,
                                 187, 186, 22, 212, 37, 77, 105, 214, 191, 240, 91, 88, 5, 88, 83,
                                 132, 141, 121]
            let data = Data(bytes: seed, count: seed.count * MemoryLayout<UInt8>.size)
            let verifier = data.a0_encodeBase64URLSafe();
            
            let generator = ChallengeGenerator(verifier: verifier)

            it("should generate expected challenge") {
                expect(generator.challenge) == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
            }
        }

        var generator: ChallengeGenerator!

        beforeEach {
            generator = ChallengeGenerator()
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

    }
}
