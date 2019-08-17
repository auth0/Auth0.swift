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
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

#if swift(>=3.2)
@available(iOS 11.0, *)
class SafariAuthenticationSession: AuthSession {

    private enum AuthenticationSession {

        @available(iOS 12.0, *)
        case authenticationServices(ASWebAuthenticationSession)

        case safariServices(SFAuthenticationSession)

        @available(iOS 12.0, *)
        init(_ session: ASWebAuthenticationSession) {
            self = .authenticationServices(session)
        }

        init(_ session: SFAuthenticationSession) {
            self = .safariServices(session)
        }

        func start() -> Bool {
            switch self {
            case .authenticationServices(let session):
                return session.start()
            case .safariServices(let session):
                return session.start()
            }
        }

        func cancel() {
            switch self {
            case .authenticationServices(let session):
                return session.cancel()
            case .safariServices(let session):
                return session.cancel()
            }
        }
    }

    private var authSession: AuthenticationSession?

    init(authorizeURL: URL, redirectURL: URL, state: String? = nil, handler: OAuth2Grant, finish: @escaping FinishSession, logger: Logger?) {
        super.init(redirectURL: redirectURL, state: state, handler: handler, finish: finish, logger: logger)
        #if canImport(AuthenticationServices)
        if #available(iOS 12.0, *) {
            let webAuthenticationSession = ASWebAuthenticationSession(url: authorizeURL, callbackURLScheme: self.redirectURL.absoluteString) { [unowned self] in
                guard $1 == nil, let callbackURL = $0 else {
                    let authError = $1 ?? WebAuthError.unknownError
                    if case ASWebAuthenticationSessionError.canceledLogin = authError {
                        self.finish(.failure(error: WebAuthError.userCancelled))
                    } else {
                        self.finish(.failure(error: authError))
                    }
                    return TransactionStore.shared.clear()
                }
                _ = TransactionStore.shared.resume(callbackURL, options: [:])
            }
            #if swift(>=5.1)
            if #available(iOS 13.0, *) {
                webAuthenticationSession.presentationContextProvider = self
            }
            #endif
            authSession = .init(webAuthenticationSession)
        } else {
            authSession = .init(SFAuthenticationSession(url: authorizeURL, callbackURLScheme: self.redirectURL.absoluteString) { [unowned self] in
                guard $1 == nil, let callbackURL = $0 else {
                    let authError = $1 ?? WebAuthError.unknownError
                    if case SFAuthenticationError.canceledLogin = authError {
                        self.finish(.failure(error: WebAuthError.userCancelled))
                    } else {
                        self.finish(.failure(error: authError))
                    }
                    return TransactionStore.shared.clear()
                }
                _ = TransactionStore.shared.resume(callbackURL, options: [:])
            })
        }
        #else
        authSession = .init(SFAuthenticationSession(url: authorizeURL, callbackURLScheme: self.redirectURL.absoluteString) { [unowned self] in
            guard $1 == nil, let callbackURL = $0 else {
                let authError = $1 ?? WebAuthError.unknownError
                if case SFAuthenticationError.canceledLogin = authError {
                    self.finish(.failure(error: WebAuthError.userCancelled))
                } else {
                    self.finish(.failure(error: authError))
                }
                return TransactionStore.shared.clear()
            }
            _ = TransactionStore.shared.resume(callbackURL, options: [:])
        })
        #endif
        _ = authSession?.start()
    }

    override func resume(_ url: URL, options: [A0URLOptionsKey: Any]) -> Bool {
        if super.resume(url, options: options) {
            authSession?.cancel()
            authSession = nil
            return true
        }
        return false
    }

    override func cancel() {
        super.cancel()
        authSession?.cancel()
        authSession = nil
    }
}

#if swift(>=5.1)
@available(iOS 13.0, *)
extension SafariAuthenticationSession: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.keyWindow ?? ASPresentationAnchor()
    }
}
#endif
#endif
