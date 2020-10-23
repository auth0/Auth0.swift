// CryptoExtensions.swift
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
import Security
#if SWIFT_PACKAGE
import Auth0ObjectiveC
#endif

@testable import Auth0

@available(iOS 10.0, macOS 10.12, *)
extension SecKey {
    func export() -> Data {
        return SecKeyCopyExternalRepresentation(self, nil)! as Data
    }
}

@available(iOS 10.0, macOS 10.12, *)
extension JWTAlgorithm {
    func sign(value: Data, key: SecKey = TestKeys.rsaPrivate) -> Data {
        switch self {
        case .rs256:
            let sha256 = A0SHA()
            let rsa = A0RSA(key: key)!
            
            return rsa.sign(sha256.hash(value))
        case .hs256: return value
        }
    }
}
