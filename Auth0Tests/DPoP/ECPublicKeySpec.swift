import Foundation
import Quick
import Nimble
import CryptoKit

@testable import Auth0

private let testKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEOCUXMFPnavaVBC9/r8dsO5kZWiPN
iTku4tYZKhD3yHEcW3Gclp096dosDQXlZQU6u8qA4wJB06jo2berqfV77Q==
-----END PUBLIC KEY-----
"""

class ECPublicKeySpec: QuickSpec {
    override class func spec() {

        it("should initialize with a valid P256 public key") {
            let publicKey = try P256.Signing.PublicKey(pemRepresentation: testKey)
            let ecPublicKey = ECPublicKey(from: publicKey)

            expect(ecPublicKey.type) == "EC"
            expect(ecPublicKey.curve) == "P-256"
            expect(ecPublicKey.x) == "OCUXMFPnavaVBC9_r8dsO5kZWiPNiTku4tYZKhD3yHE"
            expect(ecPublicKey.y) == "HFtxnJadPenaLA0F5WUFOrvKgOMCQdOo6Nm3q6n1e-0"
        }

        it("should generate a valid thumbprint") {
            let publicKey = try P256.Signing.PublicKey(pemRepresentation: testKey)
            let ecPublicKey = ECPublicKey(from: publicKey)
            let thumbprint = ecPublicKey.thumbprint()

            expect(thumbprint) == "mdN2DwUAB_Q36BItzH1Hn9ekfGIqqZPOmyiVgcUgqz4"
        }

        it("should generate a JWK dictionary") {
            let publicKey = try P256.Signing.PublicKey(pemRepresentation: testKey)
            let ecPublicKey = ECPublicKey(from: publicKey)
            let jwk = ecPublicKey.jwk()

            expect(jwk["kty"] as? String) == "EC"
            expect(jwk["crv"] as? String) == "P-256"
            expect(jwk["x"] as? String) == "OCUXMFPnavaVBC9_r8dsO5kZWiPNiTku4tYZKhD3yHE"
            expect(jwk["y"] as? String) == "HFtxnJadPenaLA0F5WUFOrvKgOMCQdOo6Nm3q6n1e-0"
        }

    }
}
