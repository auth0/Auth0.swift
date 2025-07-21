import Foundation
import Quick
import Nimble
import CryptoKit

@testable import Auth0

private let serialQueueKey = DispatchSpecificKey<Void>()

class SecureEnclaveKeyStoreSpec: QuickSpec {
    override class func spec() {

        describe("SecureEnclaveKeyStore") {

            var keyStore: SecureEnclaveKeyStore!

            beforeSuite {
                serialQueue.setSpecific(key: serialQueueKey, value: ())
            }

            beforeEach {
                keyStore = SecureEnclaveKeyStore(keychainService: "com.auth0.test")
                try keyStore.clear()
            }

            context("hasPrivateKey") {

                it("should return false if no private key exists") {
                    expect { try keyStore.hasPrivateKey() } == false
                }

                it("should return true if a private key exists") {
                    _ = try keyStore.privateKey()

                    expect { try keyStore.hasPrivateKey() } == true
                }

                it("should throw an error if the key cannot be retrieved") {
                    let status = errSecUnimplemented
                    let errorMessage = "Unable to retrieve the private key representation from the Keychain. " +
                    "OSStatus: \(status)."
                    let expectedError = DPoPError(code: .keychainOperationFailed(errorMessage))

                    keyStore.retrieve = { _, _ in
                        return status // Simulate an error
                    }

                    expect { try keyStore.hasPrivateKey() }.to(throwError(expectedError))
                }

                it("should throw an error if retrieved data cannot be cast to a Data value") {
                    let errorMessage = "Unable to cast the retrieved private key representation to a Data value."
                    let expectedError = DPoPError(code: .unknown(errorMessage))

                    keyStore.retrieve = { _, result in
                        result?.pointee = .some(NSDate()) // Set an incorrect type
                        return errSecSuccess
                    }

                    expect { try keyStore.hasPrivateKey() }.to(throwError(expectedError))
                }

                it("should throw an error if the key cannot be recreated from the retrieved data") {
                    let errorMessage = "Unable to recreate a Secure Enclave private key from the retrieved data."
                    let expectedError = DPoPError(code: .secureEnclaveOperationFailed(errorMessage))

                    keyStore.retrieve = { _, result in
                        result?.pointee = .some(NSData()) // Set empty data
                        return errSecSuccess
                    }

                    expect { try keyStore.hasPrivateKey() }.to(throwError { (error: DPoPError) in
                        expect(error.code) == expectedError.code
                        expect(error.localizedDescription).to(beginWith(prefix: expectedError.localizedDescription))
                    })
                }

            }

            context("privateKey") {

                it("should create private keys on the secure enclave") {
                    let privateKey = try keyStore.privateKey()

                    expect(privateKey).to(beAKindOf(SecureEnclave.P256.Signing.PrivateKey.self))
                }

                it("should return the same private key if it already exists") {
                    let firstKey = try keyStore.privateKey() as! SecureEnclave.P256.Signing.PrivateKey
                    let secondKey = try keyStore.privateKey() as! SecureEnclave.P256.Signing.PrivateKey

                    expect(firstKey.rawRepresentation) == secondKey.rawRepresentation
                }

                it("should throw an error if the a new key cannot be created") {
                    let errorMessage = "Unable to create a new private key using the Secure Enclave."
                    let expectedError = DPoPError(code: .secureEnclaveOperationFailed(errorMessage))

                    keyStore.newPrivateKey = {
                        throw NSError(domain: "com.example", code: 1000)
                    }

                    expect { try keyStore.privateKey() }.to(throwError { (error: DPoPError) in
                        expect(error.code) == expectedError.code
                        expect(error.localizedDescription).to(beginWith(prefix: expectedError.localizedDescription))
                    })
                }

                it("should throw an error if the new key cannot be stored") {
                    let status = errSecUnimplemented
                    let errorMessage = "Unable to store private key representation in the Keychain. " +
                    "OSStatus: \(status)."
                    let expectedError = DPoPError(code: .keychainOperationFailed(errorMessage))

                    keyStore.store = { _, _ in
                        return status // Simulate an error
                    }

                    expect { try keyStore.privateKey() }.to(throwError(expectedError))
                }

                it("should run the private key creation and storage inside the shared serial queue") {
                    keyStore.newPrivateKey = {
                        expect(DispatchQueue.getSpecific(key: serialQueueKey)).toNot(beNil())
                        return try SecureEnclave.P256.Signing.PrivateKey()
                    }

                    keyStore.store = { _, _ in
                        expect(DispatchQueue.getSpecific(key: serialQueueKey)).toNot(beNil())
                        return errSecSuccess
                    }

                    _ = try keyStore.privateKey()
                }

            }

            context("clear") {

                it("should clear the private key") {
                    _ = try keyStore.privateKey() // Create the key
                    try keyStore.clear()

                    expect { try keyStore.hasPrivateKey() } == false
                }

                it("should not throw an error if the key is not found") {
                    expect { try keyStore.clear() }.toNot(throwError())
                }

                it("should throw an error if the key cannot be deleted") {
                    let status = errSecUnimplemented
                    let errorMessage = "Unable to delete the private key representation from the Keychain. " +
                    "OSStatus: \(status)."
                    let expectedError = DPoPError(code: .keychainOperationFailed(errorMessage))

                    keyStore.remove = { _ in
                        return status // Simulate an error
                    }

                    expect { try keyStore.clear() }.to(throwError(expectedError))
                }

                it("should run inside the shared serial queue") {
                    keyStore.remove = { _ in
                        expect(DispatchQueue.getSpecific(key: serialQueueKey)).toNot(beNil())
                        return errSecSuccess
                    }

                    try keyStore.clear()
                }

            }

        }

    }
}
