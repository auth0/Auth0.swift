import Foundation
import CryptoKit
import Quick
import Nimble
import JWTDecode

@testable import Auth0

private let DPoPNonce = "auth0-nonce"
private let AccessToken = "access-token"
private let AccessTokenHash = Data(SHA256.hash(data: AccessToken.data(using: .utf8)!)).encodeBase64URLSafe()

class DPoPSpec: QuickSpec {
    override class func spec() {

        describe("DPoP") {

            var dpop: DPoP!

            beforeEach {
                dpop = DPoP(keychainIdentifier: DPoP.defaultKeychainIdentifier)
            }

            afterEach {
                try DPoP.clearKeypair()
                DPoP.resetNonce()
            }

            context("key pair existence") {

                it("should return true when a key pair exists") {
                    // Create a key pair
                    _ = try DPoP.keyStore(for: DPoP.defaultKeychainIdentifier).privateKey()

                    expect { try dpop.hasKeypair() } == true
                }

                it("should return false when no key pair exists") {
                    // Create a key pair
                    _ = try DPoP.keyStore(for: DPoP.defaultKeychainIdentifier).privateKey()

                    // Clear it
                    try DPoP.clearKeypair()

                    expect { try dpop.hasKeypair() } == false
                }

            }

            context("nonce handling") {

                let headersWithNonce = ["DPoP-Nonce": DPoPNonce]
                let headersWithoutNonce = ["Foo": "Bar"]

                it("should extract the nonce from the response") {
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                                 statusCode: 200,
                                                 httpVersion: nil,
                                                 headerFields: headersWithNonce)!

                    expect(DPoP.extractNonce(from: response)) == DPoPNonce
                }

                it("should return nil when no nonce is present in the response") {
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                                   statusCode: 200,
                                                   httpVersion: nil,
                                                   headerFields: headersWithoutNonce)!

                    expect(DPoP.extractNonce(from: response)).to(beNil())
                }

                it("should extract and store the nonce from the response") {
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                                 statusCode: 200,
                                                 httpVersion: nil,
                                                 headerFields: headersWithNonce)!
                    DPoP.storeNonce(from: response)

                    expect(DPoP.auth0Nonce) == DPoPNonce
                }

                it("should not clear the stored nonce if the next response does not contain a nonce") {
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                                   statusCode: 200,
                                                   httpVersion: nil,
                                                   headerFields: headersWithNonce)!
                    DPoP.storeNonce(from: response)

                    let newResponse = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                                      statusCode: 200,
                                                      httpVersion: nil,
                                                      headerFields: headersWithoutNonce)!
                    DPoP.storeNonce(from: newResponse)

                    expect(DPoP.auth0Nonce) == DPoPNonce
                }

            }

            context("proof generation") {

                it("should generate a DPoP proof") {
                    let endpoint = "https://example.com/api/endpoint"
                    let method = "PATCH"
                    var request = URLRequest(url: URL(string: endpoint)!)
                    request.httpMethod = method
                    let proof = try dpop.generateProof(for: request)
                    let decodedProof = try decode(jwt: proof)

                    expect(decodedProof["htu"].string) == endpoint
                    expect(decodedProof["htm"].string) == method
                    expect(decodedProof["nonce"].rawValue).to(beNil())
                    expect(decodedProof["ath"].rawValue).to(beNil())
                }

                it("should generate a DPoP proof with a nonce claim") {
                    let endpoint = "https://example.com/api/endpoint"
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                                   statusCode: 200,
                                                   httpVersion: nil,
                                                   headerFields: ["DPoP-Nonce": DPoPNonce])!
                    DPoP.storeNonce(from: response)

                    let method = "PATCH"
                    var request = URLRequest(url: URL(string: endpoint)!)
                    request.httpMethod = method
                    let proof = try dpop.generateProof(for: request)
                    let decodedProof = try decode(jwt: proof)

                    expect(decodedProof["htu"].string) == endpoint
                    expect(decodedProof["htm"].string) == method
                    expect(decodedProof["nonce"].string) == DPoPNonce
                    expect(decodedProof["ath"].rawValue).to(beNil())
                }

                it("should generate a DPoP proof with an ath claim") {
                    let endpoint = "https://example.com/api/endpoint"
                    let method = "PATCH"
                    var request = URLRequest(url: URL(string: endpoint)!)
                    request.httpMethod = method
                    request.setValue(AccessToken, forHTTPHeaderField: "Authorization")
                    let proof = try dpop.generateProof(for: request)
                    let decodedProof = try decode(jwt: proof)

                    expect(decodedProof["htu"].string) == endpoint
                    expect(decodedProof["htm"].string) == method
                    expect(decodedProof["nonce"].rawValue).to(beNil())
                    expect(decodedProof["ath"].string) == AccessTokenHash
                }

                it("should generate a DPoP proof with nonce and ath claims") {
                    let endpoint = "https://example.com/api/endpoint"
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                                   statusCode: 200,
                                                   httpVersion: nil,
                                                   headerFields: ["DPoP-Nonce": DPoPNonce])!
                    DPoP.storeNonce(from: response)

                    let method = "PATCH"
                    var request = URLRequest(url: URL(string: endpoint)!)
                    request.httpMethod = method
                    request.setValue(AccessToken, forHTTPHeaderField: "Authorization")
                    let proof = try dpop.generateProof(for: request)
                    let decodedProof = try decode(jwt: proof)

                    expect(decodedProof["htu"].string) == endpoint
                    expect(decodedProof["htm"].string) == method
                    expect(decodedProof["nonce"].string) == DPoPNonce
                    expect(decodedProof["ath"].string) == AccessTokenHash
                }

            }

            context("retry logic") {

                let infoWithNonceError = ["error": "use_dpop_nonce", "description": "Nonce required"]
                let infoWithoutNonceError = ["error": "invalid_request", "description": "Invalid request"]

                it("should return true when the use_dpop_nonce error is present") {
                    let error = AuthenticationError(info: infoWithNonceError, statusCode: 400)
                    let shouldRetry = DPoP.shouldRetry(for: error, retryCount: 0)

                    expect(shouldRetry) == true
                }

                it("should return false after the max retries have been reached") {
                    let error = AuthenticationError(info: infoWithNonceError, statusCode: 400)
                    let shouldRetry = DPoP.shouldRetry(for: error, retryCount: 1)

                    expect(shouldRetry) == false
                }

                it("should return false when no use_dpop_nonce error is present") {
                    let error = AuthenticationError(info: infoWithoutNonceError, statusCode: 400)
                    let shouldRetry = DPoP.shouldRetry(for: error, retryCount: 0)

                    expect(shouldRetry) == false
                }

            }

            context("use_dpop_nonce error detection") {

                let headersWithNonceError = ["WWW-Authenticate": "DPoP error=use_dpop_nonce"]
                let headersWithoutNonceError = ["WWW-Authenticate": "DPoP error=invalid_request"]

                it("should return true when use_dpop_nonce error is present") {
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                                   statusCode: 401,
                                                   httpVersion: nil,
                                                   headerFields: headersWithNonceError)

                    expect(DPoP.isNonceRequired(by: response!)) == true
                }

                it("should return false when no use_dpop_nonce error is present") {
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                                   statusCode: 401,
                                                   httpVersion: nil,
                                                   headerFields: headersWithoutNonceError)

                    expect(DPoP.isNonceRequired(by: response!)) == false
                }

            }

            context("key store creation") {

                it("should use SecureEnclaveKeyStore when Secure Enclave is available") {
                    let keyStore = DPoP.keyStore(for: DPoP.defaultKeychainIdentifier, useSecureEnclave: true)
                    expect(keyStore).to(beAKindOf(SecureEnclaveKeyStore.self))
                }

                it("should use KeychainKeyStore when Secure Enclave is not available") {
                    let keyStore = DPoP.keyStore(for: DPoP.defaultKeychainIdentifier, useSecureEnclave: false)
                    expect(keyStore).to(beAKindOf(KeychainKeyStore.self))
                }

            }

            context("addHeaders") {

                let endpoint = "https://example.com/api/endpoint"

                beforeEach {
                    // Create a key pair
                    _ = try DPoP.keyStore(for: DPoP.defaultKeychainIdentifier).privateKey()
                }

                afterEach {
                    // Clear the key pair
                    try DPoP.clearKeypair()
                }

                context("with DPoP token type") {

                    it("should add Authorization and DPoP headers") {
                        var request = URLRequest(url: URL(string: endpoint)!)
                        request.httpMethod = "POST"

                        try DPoP.addHeaders(to: &request, accessToken: AccessToken, tokenType: "DPoP")

                        expect(request.value(forHTTPHeaderField: "Authorization")) == "DPoP \(AccessToken)"
                        expect(request.value(forHTTPHeaderField: "DPoP")).toNot(beNil())
                    }

                    it("should add Authorization and DPoP headers with case insensitive token type") {
                        var request = URLRequest(url: URL(string: endpoint)!)
                        request.httpMethod = "POST"

                        try DPoP.addHeaders(to: &request, accessToken: AccessToken, tokenType: "dpoP")

                        expect(request.value(forHTTPHeaderField: "Authorization")) == "dpoP \(AccessToken)"
                        expect(request.value(forHTTPHeaderField: "DPoP")).toNot(beNil())
                    }

                    it("should generate a valid DPoP proof") {
                        var request = URLRequest(url: URL(string: endpoint)!)
                        request.httpMethod = "PATCH"

                        try DPoP.addHeaders(to: &request, accessToken: AccessToken, tokenType: "DPoP")
                        let proof = request.value(forHTTPHeaderField: "DPoP")!
                        let decodedProof = try decode(jwt: proof)

                        expect(decodedProof["htu"].string) == endpoint
                        expect(decodedProof["htm"].string) == "PATCH"
                        expect(decodedProof["ath"].string) == AccessTokenHash
                        expect(decodedProof["nonce"].rawValue).to(beNil())
                    }

                    it("should include nonce in DPoP proof when provided") {
                        var request = URLRequest(url: URL(string: endpoint)!)
                        request.httpMethod = "POST"

                        try DPoP.addHeaders(to: &request, accessToken: AccessToken, tokenType: "DPoP", nonce: DPoPNonce)
                        let proof = request.value(forHTTPHeaderField: "DPoP")!
                        let decodedProof = try decode(jwt: proof)

                        expect(decodedProof["nonce"].string) == DPoPNonce
                    }

                }

                context("with Bearer token type") {

                    it("should only add Authorization header") {
                        var request = URLRequest(url: URL(string: endpoint)!)
                        request.httpMethod = "POST"

                        try DPoP.addHeaders(to: &request, accessToken: AccessToken, tokenType: "Bearer")

                        expect(request.value(forHTTPHeaderField: "Authorization")) == "Bearer \(AccessToken)"
                        expect(request.value(forHTTPHeaderField: "DPoP")).to(beNil())
                    }

                    it("should only add Authorization header with case insensitive Bearer") {
                        var request = URLRequest(url: URL(string: endpoint)!)
                        request.httpMethod = "POST"

                        try DPoP.addHeaders(to: &request, accessToken: AccessToken, tokenType: "bearer")

                        expect(request.value(forHTTPHeaderField: "Authorization")) == "bearer \(AccessToken)"
                        expect(request.value(forHTTPHeaderField: "DPoP")).to(beNil())
                    }

                }

                context("with custom token type") {

                    it("should only add Authorization header") {
                        var request = URLRequest(url: URL(string: endpoint)!)
                        request.httpMethod = "POST"

                        try DPoP.addHeaders(to: &request, accessToken: AccessToken, tokenType: "Custom")

                        expect(request.value(forHTTPHeaderField: "Authorization")) == "Custom \(AccessToken)"
                        expect(request.value(forHTTPHeaderField: "DPoP")).to(beNil())
                    }

                }

            }

            context("clearKeypair") {

                context("with default keychain identifier") {

                    it("should clear an existing key pair") {
                        let keyStore = DPoP.keyStore(for: DPoP.defaultKeychainIdentifier)

                        // Create a key pair first
                        _ = try keyStore.privateKey()

                        // Verify it exists
                        expect { try keyStore.hasPrivateKey() } == true

                        // Clear it
                        try DPoP.clearKeypair()

                        // Verify it's gone
                        expect { try keyStore.hasPrivateKey() } == false
                    }

                    it("should not throw when clearing a non-existent key pair") {
                        expect {
                            try DPoP.clearKeypair()
                        }.toNot(throwError())
                    }

                }

                context("with custom keychain identifier") {

                    let customIdentifier = "com.auth0.test.custom"

                    afterEach {
                        // Clean up key pair
                        try? DPoP.clearKeypair(for: customIdentifier)
                    }

                    it("should clear an existing key pair") {
                        let keyStore = DPoP.keyStore(for: customIdentifier)

                        // Create a key pair first
                        _ = try keyStore.privateKey()

                        // Verify it exists
                        expect { try keyStore.hasPrivateKey() } == true

                        // Clear it
                        try DPoP.clearKeypair(for: customIdentifier)

                        // Verify it's gone
                        expect { try keyStore.hasPrivateKey() } == false
                    }

                    it("should not throw when clearing a non-existent key pair") {
                        expect {
                            try DPoP.clearKeypair(for: customIdentifier)
                        }.toNot(throwError())
                    }

                    it("should not affect other keychain identifiers") {
                        let otherIdentifier = "com.auth0.test.other"
                        let keyStore1 = DPoP.keyStore(for: customIdentifier)
                        let keyStore2 = DPoP.keyStore(for: otherIdentifier)

                        // Create key pairs with both identifiers
                        _ = try keyStore1.privateKey()
                        _ = try keyStore2.privateKey()

                        // Verify both exist
                        expect { try keyStore1.hasPrivateKey() } == true
                        expect { try keyStore2.hasPrivateKey() } == true

                        // Clear only one
                        try DPoP.clearKeypair(for: customIdentifier)

                        // Verify that only the targeted one is gone
                        expect { try keyStore1.hasPrivateKey() } == false
                        expect { try keyStore2.hasPrivateKey() } == true

                        // Clean up
                        try DPoP.clearKeypair(for: otherIdentifier)
                    }

                }

                context("multiple clearKeypair calls") {

                    it("should be idempotent") {
                        let keyStore = DPoP.keyStore(for: DPoP.defaultKeychainIdentifier)

                        // Create a key pair
                        _ = try keyStore.privateKey()

                        // Clear it multiple times
                        try DPoP.clearKeypair()
                        try DPoP.clearKeypair()
                        try DPoP.clearKeypair()

                        // Should still be gone
                        expect { try keyStore.hasPrivateKey() } == false
                    }

                }

            }

        }

    }
}
