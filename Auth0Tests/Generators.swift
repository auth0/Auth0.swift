// Generators.swift
//
// Copyright (c) 2019 Auth0 (http://auth0.com)
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

import Foundation
import JWTDecode

@testable import Auth0

// MARK: - Constants

fileprivate let defaultKid = "key123"

// MARK: - Keys

enum TestKeys {
    static let rsaPrivate: SecKey = {
        let query: [String: Any] = [String(kSecAttrKeyType): kSecAttrKeyTypeRSA,
                                    String(kSecAttrKeySizeInBits): 2048]
        
        return SecKeyCreateRandomKey(query as CFDictionary, nil)!
    }()
    
    static let rsaPublic: SecKey = {
        return SecKeyCopyPublicKey(rsaPrivate)!
    }()
}

// MARK: - JWT

private func encodeJWTPart(from dict: [String: Any]) -> String {
    let json = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions())
    
    return json.a0_encodeBase64URLSafe()!
}

private func generateJWTHeader(alg: String?, kid: String?) -> String {
    var headerDict: [String: Any] = [:]
    
    if let alg = alg {
        headerDict["alg"] = alg
    }
    
    if let kid = kid {
        headerDict["kid"] = kid
    }
    
    return encodeJWTPart(from: headerDict)
}

private func generateJWTBody(iss: String?,
                             sub: String?,
                             aud: [String]?,
                             exp: Date?,
                             iat: Date?,
                             azp: String?,
                             nonce: String?,
                             maxAge: Int?,
                             authTime: Date?) -> String {
    var bodyDict: [String: Any] = [:]
    
    if let iss = iss {
        bodyDict["iss"] = iss
    }
    
    if let sub = sub {
        bodyDict["sub"] = sub
    }
    
    if let aud = aud {
        bodyDict["aud"] = aud.count == 1 ? aud[0] : aud
    }
    
    if let exp = exp {
        bodyDict["exp"] = exp.timeIntervalSince1970
    }
    
    if let iat = iat {
        bodyDict["iat"] = iat.timeIntervalSince1970
    }
    
    if let azp = azp {
        bodyDict["azp"] = azp
    }
    
    if let maxAge = maxAge {
        bodyDict["max_age"] = maxAge
    }
    
    if let authTime = authTime {
        bodyDict["auth_time"] = authTime.timeIntervalSince1970
    }
    
    if let nonce = nonce {
        bodyDict["nonce"] = nonce
    }
    
    return encodeJWTPart(from: bodyDict)
}

func generateJWT(alg: String? = JWTAlgorithm.rs256.rawValue,
                 kid: String? = defaultKid,
                 iss: String? = "https://tokens-test.auth0.com/",
                 sub: String? = "auth0|123456789",
                 aud: [String]? = ["tokens-test-123"],
                 exp: Date? = Date().addingTimeInterval(86400000), // 1 day in milliseconds
                 iat: Date? = Date().addingTimeInterval(-3600000), // 1 hour in milliseconds
                 azp: String? = nil,
                 nonce: String? = "a1b2c3d4e5",
                 maxAge: Int? = nil,
                 authTime: Date? = nil,
                 signature: String? = nil) -> JWT {
    let header = generateJWTHeader(alg: alg, kid: kid)
    let body = generateJWTBody(iss: iss,
                               sub: sub,
                               aud: aud,
                               exp: exp,
                               iat: iat,
                               azp: azp,
                               nonce: nonce,
                               maxAge: maxAge,
                               authTime: authTime)
    
    let signableParts = "\(header).\(body)"
    var signaturePart = ""
    
    if let signature = signature {
        signaturePart = signature
    }
    else if let alg = alg, let algorithm = JWTAlgorithm(rawValue: alg) {
        signaturePart = algorithm.sign(value: signableParts.data(using: .utf8)!).a0_encodeBase64URLSafe()!
    }
    
    return try! decode(jwt: "\(signableParts).\(signaturePart)")
}

// MARK: - JWK

// This method calculates the length of a given DER triplet.
// It starts at the triplet's base address, then proceeds from there.
// It returns a pointer to the end of the triplet plus its length.
private func calculateLength(from bytes: UnsafePointer<UInt8>) -> (UnsafePointer<UInt8>, Int) {
    guard bytes.pointee > 0x7f else { return (bytes + 1, Int(bytes.pointee)) }

    let count = Int(bytes.pointee & 0x7f)
    let length = (1...count).reduce(0) { ($0 << 8) + Int(bytes[$1]) }
    let pointer = bytes + (1 + count)
    
    return (pointer, length)
}

// This method extracts the data portion from a given DER triplet.
// It starts at the triplet's base address, then proceeds from there.
// It returns a pointer to the end of the triplet plus its data.
private func extractData(from bytes: UnsafePointer<UInt8>) -> (UnsafePointer<UInt8>, Data)? {
    guard bytes.pointee == 0x02 else { return nil } // Checks that this is an INTEGER triplet (either the modulus or the exponent)
    
    let (valueBytes, valueLength) = calculateLength(from: bytes + 1)
    let data = Data(bytes: valueBytes, count: valueLength)
    let pointer = valueBytes + valueLength
    
    return (pointer, data)
}

func generateRSAJWK(from publicKey: SecKey = TestKeys.rsaPublic, keyId: String = defaultKid) -> JWK {
    let asn = { (bytes: UnsafePointer<UInt8>) -> JWK? in
        guard bytes.pointee == 0x30 else { return nil } // Checks that this is a SEQUENCE triplet
        
        let (modulusBytes, totalLength) = calculateLength(from: bytes + 1)
        
        guard totalLength > 0, let (exponentBytes, modulus) = extractData(from: modulusBytes) else { return nil }
        guard let (end, exponent) = extractData(from: exponentBytes) else { return nil }
        guard abs(end.distance(to: modulusBytes)) == totalLength else { return nil }
        
        let encodedModulus = modulus.a0_encodeBase64URLSafe()
        let encodedExponent = exponent.a0_encodeBase64URLSafe()
        
        return JWK(keyType: "RSA",
                   keyId: keyId,
                   usage: "sig",
                   algorithm: JWTAlgorithm.rs256.rawValue,
                   certUrl: nil,
                   certThumbprint: nil,
                   certChain: nil,
                   rsaModulus: encodedModulus,
                   rsaExponent: encodedExponent)
    }
    
    return publicKey.export().withUnsafeBytes { unsafeRawBufferPointer in
        return asn(unsafeRawBufferPointer.bindMemory(to: UInt8.self).baseAddress!)!
    }
}
