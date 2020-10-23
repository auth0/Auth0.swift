// ResponseType.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
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

///
///  List of supported response_types
///  ImplicitGrant
///  [.token]
///  [.idToken]
///  [.token, .idToken]
///
///  PKCE
///  [.code]
///  [.code, token]
///  [.code, idToken]
///  [.code, token, .idToken]
///
public struct ResponseType: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let token     = ResponseType(rawValue: 1 << 0)
    public static let idToken   = ResponseType(rawValue: 1 << 1)
    public static let code      = ResponseType(rawValue: 1 << 2)

    var label: String? {
        switch self.rawValue {
        case ResponseType.token.rawValue:
            return "token"
        case ResponseType.idToken.rawValue:
            return "id_token"
        case ResponseType.code.rawValue:
            return "code"
        default:
            return nil
        }
    }
}
#endif
