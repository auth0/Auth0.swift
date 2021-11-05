import Quick
import Nimble

#if SWIFT_PACKAGE
import Auth0

@testable import Auth0ObjectiveC
#else
@testable import Auth0
#endif

class ChallengeGeneratorSpec: QuickSpec {

    override func spec() {

        describe("test vector") {
            let seed: [UInt8] = [116, 24, 223, 180, 151, 153, 224, 37, 79, 250, 96, 125, 216, 173,
                                 187, 186, 22, 212, 37, 77, 105, 214, 191, 240, 91, 88, 5, 88, 83,
                                 132, 141, 121]
            let verifier = Data(bytes: seed, count: seed.count * MemoryLayout<UInt8>.size)

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
