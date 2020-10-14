// JWK+RSA.swift
//
// Copyright (c) 2020 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

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
        if #available(iOS 10.0, macOS 10.12, *) {
            return generateRSAPublicKey(from: encodedKey)
        }
        let tag = "com.auth0.tmp.RSAPublicKey"
        let keychain = A0SimpleKeychain()
        guard keychain.setRSAPublicKey(data: encodedKey, forKey: tag) else { return nil }
        return keychain.keyRefOfRSAKey(withTag: tag)?.takeRetainedValue()
    }

    private func encodeRSAPublicKey(modulus: [UInt8], exponent: [UInt8]) -> Data {
        var prefixedModulus: [UInt8] = [0x00] // To indicate that the number is not negative
        prefixedModulus.append(contentsOf: modulus)
        let encodedModulus = prefixedModulus.a0_derEncode(as: 2) // Integer
        let encodedExponent = exponent.a0_derEncode(as: 2) // Integer
        let encodedSequence = (encodedModulus + encodedExponent).a0_derEncode(as: 48) // Sequence
        return Data(encodedSequence)
    }

    @available(iOS 10.0, macOS 10.12, *)
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
