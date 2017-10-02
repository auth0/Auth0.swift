// SafariAuthenticationSession.swift
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

#if swift(>=3.2)
@available(iOS 11.0, *)
class SafariAuthenticationSession: AuthSession {

    typealias FinishSession = (Result<Credentials>) -> Void

    var authSession: SFAuthenticationSession?
    let authorizeURL: URL

    init(authorizeURL: URL, redirectURL: URL, state: String? = nil, handler: OAuth2Grant, finish: @escaping FinishSession, logger: Logger?) {
        self.authorizeURL = authorizeURL
        super.init(redirectURL: redirectURL, state: state, handler: handler, finish: finish, logger: logger)
        self.authSession = SFAuthenticationSession(url: self.authorizeURL, callbackURLScheme: self.redirectURL.absoluteString) { [unowned self] in
            guard $1 == nil, let callbackURL = $0 else {
                if case SFAuthenticationError.canceledLogin = $1! {
                    self.finish(.failure(error: WebAuthError.userCancelled))
                } else {
                    self.finish(.failure(error: $1!))
                }
                return TransactionStore.shared.clear()
            }
            _ = TransactionStore.shared.resume(callbackURL, options: [:])
        }
        self.authSession?.start()
    }
}
#endif
