#if WEB_AUTH_PLATFORM
import Foundation
import SimpleKeychain

extension JWK {
    var rsaPublicKey: SecKey? {
        if let usage = usage, usage != "sig" { return nil }
        guard keyType == "RSA",
            algorithm == JWTAlgorithm.rs256.rawValue,
            let modulus = rsaModulus?.a0_decodeBase64URLSafe(),
            let exponent = rsaExponent?.a0_decodeBase64URLSafe() else { return nil }
        let encodedKey = encodeRSAPublicKey(modulus: [UInt8](modulus), exponent: [UInt8](exponent))
        return generateRSAPublicKey(from: encodedKey)
    }

    private func encodeRSAPublicKey(modulus: [UInt8], exponent: [UInt8]) -> Data {
        var prefixedModulus: [UInt8] = [0x00] // To indicate that the number is not negative
        prefixedModulus.append(contentsOf: modulus)
        let encodedModulus = prefixedModulus.a0_derEncode(as: 2) // Integer
        let encodedExponent = exponent.a0_derEncode(as: 2) // Integer
        let encodedSequence = (encodedModulus + encodedExponent).a0_derEncode(as: 48) // Sequence
        return Data(encodedSequence)
    }

    private func generateRSAPublicKey(from derEncodedData: Data) -> SecKey? {
        let sizeInBits = derEncodedData.count * MemoryLayout<UInt8>.size
        let attributes: [CFString: Any] = [kSecAttrKeyType: kSecAttrKeyTypeRSA,
                                           kSecAttrKeyClass: kSecAttrKeyClassPublic,
                                           kSecAttrKeySizeInBits: NSNumber(value: sizeInBits),
                                           kSecAttrIsPermanent: false]
        return SecKeyCreateWithData(derEncodedData as CFData, attributes as CFDictionary, nil)
    }
}
#endif
