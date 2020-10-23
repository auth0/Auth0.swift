// A0SimpleKeychain+RSAPublicKey.swift
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

extension A0SimpleKeychain {
    func setRSAPublicKey(data: Data, forKey tag: String) -> Bool {
        let sizeInBits = data.count * MemoryLayout<UInt8>.size
        let query: [CFString: Any] = [kSecClass: kSecClassKey,
                                      kSecAttrKeyType: kSecAttrKeyTypeRSA,
                                      kSecAttrKeyClass: kSecAttrKeyClassPublic,
                                      kSecAttrAccessible: kSecAttrAccessibleAlways,
                                      kSecAttrKeySizeInBits: NSNumber(value: sizeInBits),
                                      kSecAttrApplicationTag: tag,
                                      kSecValueData: data]
        if hasRSAKey(withTag: tag) { deleteRSAKey(withTag: tag) }
        let result = SecItemAdd(query as CFDictionary, nil)
        return result == errSecSuccess
    }
}
#endif
