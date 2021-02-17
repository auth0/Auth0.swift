// JWTAlgorithm.swift
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
import JWTDecode
#if SWIFT_PACKAGE
import Auth0ObjectiveC
#endif

enum JWTAlgorithm: String {
    case rs256 = "RS256"
    case hs256 = "HS256"

    var shouldVerify: Bool {
        switch self {
        case .rs256: return true
        case .hs256: return false
        }
    }

    func verify(_ jwt: JWT, using jwk: JWK) -> Bool {
        let separator = "."
        let parts = jwt.string.components(separatedBy: separator).dropLast().joined(separator: separator)
        guard let data = parts.data(using: .utf8),
            let signature = jwt.signature?.a0_decodeBase64URLSafe(),
            !signature.isEmpty else { return false }
        switch self {
        case .rs256:
            guard let publicKey = jwk.rsaPublicKey, let rsa = A0RSA(key: publicKey) else { return false }
            let sha256 = A0SHA()
            return rsa.verify(sha256.hash(data), signature: signature)
        case .hs256: return true
        }
    }
}
#endif
