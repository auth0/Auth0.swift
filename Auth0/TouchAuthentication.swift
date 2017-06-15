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

struct TouchAuthentication {

    private let authContext: LAContext

    let title: String
    var fallbackTitle: String? {
        get { return self.authContext.localizedFallbackTitle }
        set { self.authContext.localizedFallbackTitle = newValue }
    }

    @available(iOS 10.0, *)
    var cancelTitle: String? {
        get { return self.authContext.localizedCancelTitle }
        set { self.authContext.localizedCancelTitle = newValue }
    }

    var available: Bool {
        return self.authContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    init(authContext: LAContext, title: String, cancelTitle: String? = nil, fallbackTitle: String? = nil) {
        self.authContext = authContext
        self.title = title
        if #available(iOS 10, *) { self.cancelTitle = cancelTitle }
        self.fallbackTitle = fallbackTitle
    }

    func requireTouch(callback: @escaping (Error?) -> Void) {
        self.authContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: self.title) {
            guard $1 == nil else { return callback($1) }
            callback($0 ? nil : LAError(LAError.authenticationFailed))
        }
    }
}
