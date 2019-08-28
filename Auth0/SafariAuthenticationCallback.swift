// SafariAuthenticationCallback.swift
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

import UIKit
import SafariServices
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

#if swift(>=3.2)
@available(iOS 11.0, *)
class SafariAuthenticationSessionCallback: NSObject, AuthTransaction {

    var state: String?
    var callback: (Bool) -> Void = { _ in }

    private var authSession: NSObject?

    init(url: URL, schemeURL: String, callback: @escaping (Bool) -> Void) {
        super.init()
        self.callback = callback
        #if canImport(AuthenticationServices)
        if #available(iOS 12.0, *) {
            let authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: schemeURL) { [unowned self] url, _ in
                self.callback(url != nil)
                TransactionStore.shared.clear()
            }
            #if swift(>=5.1)
            if #available(iOS 13.0, *) {
                authSession.presentationContextProvider = self
            }
            #endif
            self.authSession = authSession
            authSession.start()
        } else {
            let authSession = SFAuthenticationSession(url: url, callbackURLScheme: schemeURL) { [unowned self] url, _ in
                self.callback(url != nil)
                TransactionStore.shared.clear()
            }
            self.authSession = authSession
            authSession.start()
        }
        #else
        let authSession = SFAuthenticationSession(url: url, callbackURLScheme: schemeURL) { [unowned self] url, _ in
            self.callback(url != nil)
            TransactionStore.shared.clear()
        }
        self.authSession = authSession
        authSession.start()
        #endif
    }

    func resume(_ url: URL, options: [A0URLOptionsKey: Any]) -> Bool {
        self.callback(true)
        return true
    }

    func cancel() {
        self.callback(false)
    }
}
#endif

#if swift(>=5.1)
@available(iOS 13.0, *)
extension SafariAuthenticationSessionCallback: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.keyWindow ?? ASPresentationAnchor()
    }
}
#endif
