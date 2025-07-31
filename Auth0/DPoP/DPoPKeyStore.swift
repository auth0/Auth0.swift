import Foundation
import CryptoKit

// MARK: Key Providers

typealias StoreFunction = (_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
typealias RetrieveFunction = (_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
typealias RemoveFunction = (_ query: CFDictionary) -> OSStatus

protocol DPoPKeyStore: Sendable {

    func hasPrivateKey() throws(DPoPError) -> Bool
    func privateKey() throws(DPoPError) -> DPoPPrivateKey
    func clear() throws(DPoPError)

}

extension DPoPKeyStore {

    var privateKeyIdentifier: String {
        return "com.auth0.sdk.dpop.privateKey"
    }

    static func withSerialQueueSync<T>(_ block: () throws -> T) throws(DPoPError) -> T {
        do {
            return try serialQueue.sync {
                return try block()
            }
        } catch let error as DPoPError {
            throw error
        } catch {
            throw DPoPError(code: .other, cause: error)
        }
    }

}

// MARK: Private Key Type

protocol DPoPPrivateKey {

    nonisolated var publicKey: P256.Signing.PublicKey { get }

    func signature(for data: Data) throws -> P256.Signing.ECDSASignature

}

extension P256.Signing.PublicKey {

    var jwsIdentifier: String {
        return "ES256"
    }

}

extension SecureEnclave.P256.Signing.PrivateKey: DPoPPrivateKey {

    public var description: String {
        return self.dataRepresentation.withUnsafeBytes { bytes in
            return "Key representation contains \(bytes.count) bytes."
        }
    }

}

extension P256.Signing.PrivateKey: SecKeyConvertible {

    public var description: String {
        return self.x963Representation.withUnsafeBytes { bytes in
            return "Key representation contains \(bytes.count) bytes."
        }
    }

}

// MARK: Secure Enclave Keys

protocol GenericPasswordConvertible: DPoPPrivateKey, CustomStringConvertible {

    /// Creates a key from a raw representation.
    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes

    /// A raw representation of the key.
    var rawRepresentation: Data { get }

}

extension SecureEnclave.P256.Signing.PrivateKey: @retroactive CustomStringConvertible {}

extension SecureEnclave.P256.Signing.PrivateKey: GenericPasswordConvertible {

    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(dataRepresentation: data.dataRepresentation)
    }

    var rawRepresentation: Data {
        return dataRepresentation  // Contiguous bytes repackaged as a Data instance.
    }

}

extension ContiguousBytes {

    /// A Data instance created safely from the contiguous bytes without making any copies.
    var dataRepresentation: Data {
        return self.withUnsafeBytes { bytes in
            let cfdata = CFDataCreateWithBytesNoCopy(nil,
                                                     bytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                                                     bytes.count,
                                                     kCFAllocatorNull)
            return ((cfdata as NSData?) as Data?) ?? Data(buffer: bytes.assumingMemoryBound(to: UInt8.self))
        }
    }

}

// MARK: Non-Secure Enclave Keys

protocol SecKeyConvertible: DPoPPrivateKey, CustomStringConvertible {

    /// Creates a key from an X9.63 representation.
    init<Bytes>(x963Representation: Bytes) throws where Bytes: ContiguousBytes

    /// An X9.63 representation of the key.
    var x963Representation: Data { get }

}

extension P256.Signing.PrivateKey: @retroactive CustomStringConvertible {}
