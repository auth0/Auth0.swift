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
                dpop = DPoP()
            }

            afterEach {
                try DPoP.clearKeypair()
                DPoP.resetNonce()
            }

            context("keypair existence") {

                it("should return true when a keypair exists") {
                    try DPoP.createKeypair()

                    expect { try dpop.hasKeypair() } == true
                }

                it("should return false when no keypair exists") {
                    try DPoP.createKeypair()
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
                    let isNonceRequired = DPoP.isNonceRequired(by: response!)

                    expect(isNonceRequired) == true
                }

                it("should return false when no use_dpop_nonce error is present") {
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                                   statusCode: 401,
                                                   httpVersion: nil,
                                                   headerFields: headersWithoutNonceError)
                    let isNonceRequired = DPoP.isNonceRequired(by: response!)

                    expect(isNonceRequired) == false
                }

            }

            context("key store creation") {

                it("should use SecureEnclaveKeyStore when Secure Enclave is available") {
                    let keyStore = DPoP.keyStore(for: DPoP.testKeyTag, useSecureEncave: true)
                    expect(keyStore).to(beAKindOf(SecureEnclaveKeyStore.self))
                }

                it("should use KeychainKeyStore when Secure Enclave is not available") {
                    let keyStore = DPoP.keyStore(for: DPoP.testKeyTag, useSecureEncave: false)
                    expect(keyStore).to(beAKindOf(KeychainKeyStore.self))
                }

            }

        }
    }
}

extension DPoP {

    static var testKeyTag: String {
        return "test_dpop_key"
    }

    static func createKeypair() throws {
        try serialQueue.sync {
            _ = try DPoP.keyStore(for: testKeyTag).privateKey()
        }
    }

    static func clearKeypair() throws {
        try serialQueue.sync {
            _ = try DPoP.keyStore(for: testKeyTag).clear()
        }
    }

    init() {
        self.init(keychainTag: DPoP.testKeyTag)
    }

}
