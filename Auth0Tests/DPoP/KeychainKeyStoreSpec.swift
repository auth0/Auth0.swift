import Foundation
import Quick
import Nimble
import CryptoKit

@testable import Auth0

private let serialQueueKey = DispatchSpecificKey<Void>()

class KeychainKeyStoreSpec: QuickSpec {
    override class func spec() {

        describe("KeychainKeyStore") {

            var keyStore: KeychainKeyStore!

            beforeSuite {
                serialQueue.setSpecific(key: serialQueueKey, value: ())
            }

            beforeEach {
                keyStore = KeychainKeyStore(keychainTag: "com.auth0.test")
                try keyStore.clear()
            }

            context("hasPrivateKey") {

                it("should return false if no private key exists") {
                    expect { try keyStore.hasPrivateKey() } == false
                }

                // Otherwise entitlements must be added to the test bundle
                // Adding entitlements requires code signing (even on CI)
                // And code signing on CI requires access to the Apple Developer Account
                #if !os(macOS)
                it("should return true if a private key exists") {
                    _ = try keyStore.privateKey()

                    expect { try keyStore.hasPrivateKey() } == true
                }
                #endif

                it("should throw an error if the key cannot be retrieved") {
                    let status = errSecUnimplemented
                    let errorMessage = "Unable to retrieve the private key from the Keychain. " +
                    "OSStatus: \(status)."
                    let expectedError = DPoPError(code: .keychainOperationFailed(errorMessage))

                    keyStore.retrieve = { _, _ in
                        return status // Simulate an error
                    }

                    expect { try keyStore.hasPrivateKey() }.to(throwError(expectedError))
                }

                it("should throw an error if the retrieved key is not a valid SecKey") {
                    let errorMessage = "The item retrieved from the Keychain is not a SecKey."
                    let expectedError = DPoPError(code: .unknown(errorMessage))

                    keyStore.retrieve = { _, result in
                        result?.pointee = NSDate() // Set an incorrect type
                        return errSecSuccess
                    }

                    expect { try keyStore.hasPrivateKey() }.to(throwError(expectedError))
                }

                // Otherwise entitlements must be added to the test bundle
                // Adding entitlements requires code signing (even on CI)
                // And code signing on CI requires access to the Apple Developer Account
                #if !os(macOS)
                it("should throw an error if the key cannot be exported") {
                    let message = "Unable to copy the external representation of the retrieved SecKey."
                    let expectedError = DPoPError(code: .secKeyOperationFailed(message))

                    _ = try keyStore.privateKey()

                    keyStore.exportSecKey = { _, errorRef in
                        let error = CFErrorCreate(nil, kCFErrorDomainOSStatus, CFIndex(errSecUnimplemented), nil)!
                        errorRef?.pointee = Unmanaged.passRetained(error) // Set an error
                        return nil
                    }

                    expect { try keyStore.hasPrivateKey() }.to(throwError { (error: DPoPError) in
                        expect(error.code) == expectedError.code
                        expect(error.localizedDescription).to(beginWith(expectedError.localizedDescription))
                        expect(error.cause).toNot(beNil())
                    })
                }

                it("should throw an error if the key cannot be recreated from the exported data") {
                    let errorMessage = "Unable to create a CryptoKit private key from the retrieved SecKey."
                    let expectedError = DPoPError(code: .cryptoKitOperationFailed(errorMessage))

                    _ = try keyStore.privateKey()

                    keyStore.exportSecKey = { _, errorRef in
                        return Data() as CFData? // Set empty data
                    }

                    expect { try keyStore.hasPrivateKey() }.to(throwError { (error: DPoPError) in
                        expect(error.code) == expectedError.code
                        expect(error.localizedDescription).to(beginWith(expectedError.localizedDescription))
                        expect(error.cause).toNot(beNil())
                    })
                }

                it("should run the private key storage inside the shared serial queue") {
                    keyStore.newPrivateKey = {
                        expect(DispatchQueue.getSpecific(key: serialQueueKey)).toNot(beNil())
                        return P256.Signing.PrivateKey()
                    }

                    keyStore.store = { attributes, result in
                        expect(DispatchQueue.getSpecific(key: serialQueueKey)).toNot(beNil())
                        return SecItemAdd(attributes, result)
                    }

                    keyStore.createSecKey = { keyData, attributes, error in
                        expect(DispatchQueue.getSpecific(key: serialQueueKey)).toNot(beNil())
                        return SecKeyCreateWithData(keyData, attributes, error)
                    }

                    _ = try keyStore.privateKey()
                }
                #endif

            }

            context("privateKey") {

                // Otherwise entitlements must be added to the test bundle
                // Adding entitlements requires code signing (even on CI)
                // And code signing on CI requires access to the Apple Developer Account
                #if !os(macOS)
                it("should create a new private key if none exists") {
                    let privateKey = try keyStore.privateKey()

                    expect(privateKey).to(beAKindOf(P256.Signing.PrivateKey.self))
                }

                it("should return the same private key if it already exists") {
                    let firstKey = try keyStore.privateKey()
                    let secondKey = try keyStore.privateKey()

                    expect(firstKey.publicKey.rawRepresentation) == secondKey.publicKey.rawRepresentation
                }
                #endif

                it("should throw an error if a new key cannot be created") {
                    let message = "Unable to create a SecKey representation from the private key."
                    let expectedError = DPoPError(code: .secKeyOperationFailed(message))

                    keyStore.createSecKey = { _, _, errorRef in
                        let error = CFErrorCreate(nil, kCFErrorDomainOSStatus, CFIndex(errSecUnimplemented), nil)!
                        errorRef?.pointee = Unmanaged.passRetained(error) // Set an error
                        return nil
                    }

                    expect { try keyStore.privateKey() }.to(throwError { (error: DPoPError) in
                        expect(error.code) == expectedError.code
                        expect(error.localizedDescription).to(beginWith(expectedError.localizedDescription))
                        expect(error.cause).toNot(beNil())
                    })
                }

                it("should throw an error if the new key cannot be stored") {
                    let status = errSecUnimplemented
                    let errorMessage = "Unable to store the private key in the Keychain. " +
                    "OSStatus: \(status)."
                    let expectedError = DPoPError(code: .keychainOperationFailed(errorMessage))

                    keyStore.store = { _, _ in
                        return status // Simulate an error
                    }

                    expect { try keyStore.privateKey() }.to(throwError(expectedError))
                }

            }

            context("clear") {

                // Otherwise entitlements must be added to the test bundle
                // Adding entitlements requires code signing (even on CI)
                // And code signing on CI requires access to the Apple Developer Account
                #if !os(macOS)
                it("should clear the private key") {
                    _ = try keyStore.privateKey()

                    expect { try keyStore.hasPrivateKey() } == true

                    try keyStore.clear()

                    expect { try keyStore.hasPrivateKey() } == false
                }
                #endif

                it("should not throw an error if the key is not found") {
                    expect { try keyStore.clear() }.toNot(throwError())
                }

                it("should throw an error if the key cannot be deleted") {
                    let status = errSecUnimplemented
                    let errorMessage = "Unable to delete the private key from the Keychain. OSStatus: \(status)."
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

            // Otherwise entitlements must be added to the test bundle
            // Adding entitlements requires code signing (even on CI)
            // And code signing on CI requires access to the Apple Developer Account
            #if !os(macOS)
            context("key description") {

                it("should provide a description of the P256 private key") {
                    let privateKey = try keyStore.privateKey()
                    let description = (privateKey as! P256.Signing.PrivateKey).description

                    expect(description).to(match("^Key representation contains \\d+ bytes\\.$"))
                }

            }
            #endif

        }

    }
}
