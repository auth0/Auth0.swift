// TouchAuthentication.swift
//
// Copyright (c) 2017 Auth0 (http://auth0.com)
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
import LocalAuthentication

public struct TouchAuthentication {

    private let authContext: LAContext

    public init(authContext: LAContext) {
        self.authContext = authContext
    }

    public var available: Bool {
        return self.authContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    public func requireTouch(withTitle title: String, cancelTitle: String? = nil, callback: @escaping (Error?) -> Void) {
        if #available(iOS 10, *) {
            self.authContext.localizedCancelTitle = cancelTitle
        }
        self.authContext.localizedFallbackTitle = ""

        self.authContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: title) {
            guard $1 == nil else {
                return callback($1)
            }
            guard $0 else { return callback(LAError(LAError.authenticationFailed))}
            callback(nil)
        }
    }
}
