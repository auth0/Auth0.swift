// ASTransaction.swift
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
import AuthenticationServices

final class ASTransaction: BaseTransaction {

    init(authorizeURL: URL,
         redirectURL: URL,
         state: String? = nil,
         handler: OAuth2Grant,
         logger: Logger?,
         ephemeralSession: Bool,
         callback: @escaping FinishTransaction) {
        super.init(redirectURL: redirectURL,
                   state: state,
                   handler: handler,
                   logger: logger,
                   callback: callback)

        let authSession = ASWebAuthenticationSession(url: authorizeURL,
                                                     callbackURLScheme: self.redirectURL.scheme) { [weak self] in
            guard $1 == nil, let callbackURL = $0 else {
                let authError = $1 ?? WebAuthError.unknownError
                if case ASWebAuthenticationSessionError.canceledLogin = authError {
                    self?.callback(.failure(WebAuthError.userCancelled))
                } else {
                    self?.callback(.failure(authError))
                }
                return TransactionStore.shared.clear()
            }
            _ = TransactionStore.shared.resume(callbackURL)
        }

        if #available(iOS 13.0, *) {
            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = ephemeralSession
        }

        self.authSession = authSession
        authSession.start()
    }

}

extension ASWebAuthenticationSession: AuthSession {}
#endif
