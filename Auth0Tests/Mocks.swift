import Foundation
import CryptoKit

@testable import Auth0

struct MockLogger: Logger {
    func trace(url: URL, source: String?) {}
    
    func trace(response: URLResponse, data: Data?) {}
    
    func trace(request: URLRequest, session: URLSession) {}
}

struct MockError: LocalizedError, CustomStringConvertible {
    private let message: String
    
    init(message: String = "foo") {
        self.message = message
    }
    
    var description: String {
        return self.message
    }
    
    var localizedDescription: String {
        return self.message
    }
    
    var errorDescription: String? {
        return self.message
    }
}

struct MockDPoPKeyStore: DPoPKeyStore, Sendable {
    private let key: DPoPPrivateKey
    private let shouldFail: Bool

    init(privateKey: DPoPPrivateKey = MockDPoPPrivateKey(), shouldFail: Bool = false) {
        self.key = privateKey
        self.shouldFail = shouldFail
    }

    func hasPrivateKey() throws(DPoPError) -> Bool {
        return true
    }

    func privateKey() throws(DPoPError) -> DPoPPrivateKey {
        if shouldFail {
            throw DPoPError(code: .unknown("Error"))
        }

        return key
    }

    func clear() throws(DPoPError) {}
}

struct MockDPoPPrivateKey: DPoPPrivateKey, Sendable {
    private static let privateKey = P256.Signing.PrivateKey()
    private let shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    var publicKey: P256.Signing.PublicKey {
        return Self.privateKey.publicKey
    }

    func signature(for data: Data) throws -> P256.Signing.ECDSASignature {
        if shouldFail {
            throw NSError(domain: "com.example", code: 1000)
        }

        return try Self.privateKey.signature(for: data)
    }
}
