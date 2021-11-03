// BaseAuthTransaction.swift
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

class BaseTransaction: NSObject, AuthTransaction {

    typealias FinishTransaction = (Result<Credentials>) -> Void

    var authSession: AuthSession?
    let state: String?
    let redirectURL: URL
    let handler: OAuth2Grant
    let logger: Logger?
    let callback: FinishTransaction

    init(redirectURL: URL,
         state: String? = nil,
         handler: OAuth2Grant,
         logger: Logger?,
         callback: @escaping FinishTransaction) {
        self.redirectURL = redirectURL
        self.state = state
        self.handler = handler
        self.logger = logger
        self.callback = callback
        super.init()
    }

    func cancel() {
        self.callback(Result.failure(WebAuthError.userCancelled))
        authSession?.cancel()
        authSession = nil
    }

    func resume(_ url: URL) -> Bool {
        self.logger?.trace(url: url, source: "iOS Safari")
        if self.handleURL(url) {
            authSession?.cancel()
            authSession = nil
            return true
        }
        return false
    }

    private func handleURL(_ url: URL) -> Bool {
        guard url.absoluteString.lowercased().hasPrefix(self.redirectURL.absoluteString.lowercased()) else { return false }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            self.callback(.failure(AuthenticationError(string: url.absoluteString, statusCode: 200)))
            return false
        }
        let items = self.handler.values(fromComponents: components)
        guard has(state: self.state, inItems: items) else { return false }
        if items["error"] != nil {
            self.callback(.failure(AuthenticationError(info: items, statusCode: 0)))
        } else {
            self.handler.credentials(from: items, callback: self.callback)
        }
        return true
    }

    private func has(state: String?, inItems items: [String: String]) -> Bool {
        return state == nil || items["state"] == state
    }

}
#endif
