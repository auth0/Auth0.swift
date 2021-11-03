// BioAuthentication.swift
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

#if WEB_AUTH_PLATFORM
import Foundation
import LocalAuthentication

struct BioAuthentication {

    private let authContext: LAContext
    private let evaluationPolicy: LAPolicy

    let title: String
    var fallbackTitle: String? {
        get { return self.authContext.localizedFallbackTitle }
        set { self.authContext.localizedFallbackTitle = newValue }
    }

    var cancelTitle: String? {
        get { return self.authContext.localizedCancelTitle }
        set { self.authContext.localizedCancelTitle = newValue }
    }

    var available: Bool {
        return self.authContext.canEvaluatePolicy(evaluationPolicy, error: nil)
    }

    init(authContext: LAContext, evaluationPolicy: LAPolicy, title: String, cancelTitle: String? = nil, fallbackTitle: String? = nil) {
        self.authContext = authContext
        self.evaluationPolicy = evaluationPolicy
        self.title = title
        self.cancelTitle = cancelTitle
        self.fallbackTitle = fallbackTitle
    }

    func validateBiometric(callback: @escaping (Error?) -> Void) {
        self.authContext.evaluatePolicy(evaluationPolicy, localizedReason: self.title) {
            guard $1 == nil else { return callback($1) }
            callback($0 ? nil : LAError(LAError.authenticationFailed))
        }
    }

}
#endif
