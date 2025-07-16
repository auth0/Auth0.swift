import Foundation
import Quick
import Nimble
import CryptoKit
import JWTDecode

@testable import Auth0

class DPoPProofGeneratorSpec: QuickSpec {
    override class func spec() {

        describe("DPoPProofGenerator") {

            var keyStore: DPoPKeyStore!
            var proofGenerator: DPoPProofGenerator!

            beforeEach {
                keyStore = MockDPoPKeyStore()
                proofGenerator = DPoPProofGenerator(keyStore: keyStore)
            }

            it("should generate a valid DPoP proof with all claims") {
                let url = URL(string: "https://example.com/api/endpoint")!
                let method = "POST"
                let nonce = "nonce"
                let accessToken = "access-token"
                let proof = try proofGenerator.generate(url: url,
                                                        method: method,
                                                        nonce: nonce,
                                                        accessToken: accessToken)
                let decodedProof = try decode(jwt: proof)

                expect(decodedProof.header["typ"] as? String) == "dpop+jwt"
                expect(decodedProof.header["alg"] as? String) == "ES256"
                expect(decodedProof.header["jwk"] as? [String: String]).toNot(beEmpty())

                let privateKey = try keyStore.privateKey()
                let publicKey = ECPublicKey(from: privateKey.publicKey)

                expect((decodedProof.header["jwk"] as? [String: String])?["crv"]) == publicKey.curve
                expect((decodedProof.header["jwk"] as? [String: String])?["kty"]) == publicKey.type
                expect((decodedProof.header["jwk"] as? [String: String])?["y"]) == publicKey.y
                expect((decodedProof.header["jwk"] as? [String: String])?["x"]) == publicKey.x

                let accessTokenHash = Data(SHA256.hash(data: accessToken.data(using: .utf8)!))

                expect(decodedProof["htm"].string) == method
                expect(decodedProof["htu"].string) == url.absoluteString
                expect(decodedProof["nonce"].string) == nonce
                expect(decodedProof["ath"].string) == accessTokenHash.encodeBase64URLSafe()
                expect(UUID(uuidString: decodedProof["jti"].string ?? "")).toNot(beNil())
                expect(decodedProof["iat"].date).to((beCloseTo(Date(), within: 5)))

                let signableParts = decodedProof.string.split(separator: ".").dropLast().joined(separator: ".")
                let signableData = signableParts.data(using: .utf8)!
                let signature = try privateKey.signature(for: signableData)

                expect(privateKey.publicKey.isValidSignature(signature, for: signableData)) == true
            }

            it("should generate a DPoP proof without a nonce") {
                let proof = try proofGenerator.generate(url: URL(string: "https://example.com/api/endpoint")!,
                                                        method: "POST",
                                                        nonce: nil,
                                                        accessToken: "access-token")
                let decodedProof = try decode(jwt: proof)

                expect(decodedProof.header["typ"] as? String).toNot(beNil())
                expect(decodedProof.header["alg"] as? String).toNot(beNil())
                expect(decodedProof.header["jwk"] as? [String: String]).toNot(beNil())
                expect(decodedProof["htm"].string).toNot(beNil())
                expect(decodedProof["htu"].string).toNot(beNil())
                expect(decodedProof["nonce"].string).to(beNil()) // Not present
                expect(decodedProof["ath"].string).toNot(beNil())
                expect(decodedProof["jti"].string).toNot(beNil())
                expect(decodedProof["iat"].date).toNot(beNil())
            }

            it("should generate a DPoP proof without an access token") {
                let proof = try proofGenerator.generate(url: URL(string: "https://example.com/api/endpoint")!,
                                                        method: "POST",
                                                        nonce: "nonce",
                                                        accessToken: nil)
                let decodedProof = try decode(jwt: proof)

                expect(decodedProof.header["typ"] as? String).toNot(beNil())
                expect(decodedProof.header["alg"] as? String).toNot(beNil())
                expect(decodedProof.header["jwk"] as? [String: String]).toNot(beNil())
                expect(decodedProof["htm"].string).toNot(beNil())
                expect(decodedProof["htu"].string).toNot(beNil())
                expect(decodedProof["nonce"].string).toNot(beNil())
                expect(decodedProof["ath"].string).to(beNil()) // Not present
                expect(decodedProof["jti"].string).toNot(beNil())
                expect(decodedProof["iat"].date).toNot(beNil())
            }

            it("should remove any query parameters and fragments from the URL") {
                let endpoint = "https://example.com/api/endpoint?param1=value1&param2=value2#fragment"
                let proof = try proofGenerator.generate(url: URL(string: endpoint)!,
                                                        method: "POST",
                                                        nonce: nil,
                                                        accessToken: nil)
                let decodedProof = try decode(jwt: proof)

                expect(decodedProof["htu"].string) == "https://example.com/api/endpoint"
            }

            it("should throw an error if the keystore fails") {
                keyStore = MockDPoPKeyStore(shouldFail: true)
                proofGenerator = DPoPProofGenerator(keyStore: keyStore)

                let url = URL(string: "https://example.com/resource")!
                let method = "POST"

                expect {
                    try proofGenerator.generate(url: url, method: method, nonce: nil, accessToken: nil)
                }.to(throwError())
            }

            it("should throw an error if the signing fails") {
                keyStore = MockDPoPKeyStore(privateKey: MockDPoPPrivateKey(shouldFail: true))
                proofGenerator = DPoPProofGenerator(keyStore: keyStore)

                let url = URL(string: "https://example.com/resource")!
                let method = "POST"

                expect {
                    try proofGenerator.generate(url: url, method: method, nonce: nil, accessToken: nil)
                }.to(throwError())
            }

        }

    }
}
