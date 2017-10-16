// AuthSession.swift
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

class AuthSession: NSObject, AuthTransaction {

    typealias FinishSession = (Result<Credentials>) -> Void

    let redirectURL: URL
    let state: String?
    let finish: FinishSession
    let handler: OAuth2Grant
    let logger: Logger?

    init(redirectURL: URL, state: String? = nil, handler: OAuth2Grant, finish: @escaping FinishSession, logger: Logger?) {
        self.redirectURL = redirectURL
        self.state = state
        self.finish = finish
        self.handler = handler
        self.logger = logger
        super.init()
    }

    /**
     Tries to resume (and complete) the OAuth2 session from the received URL

     - parameter url:     url received in application's AppDelegate
     - parameter options: a dictionary of launch options received from application's AppDelegate

     - returns: `true` if the url completed (successfuly or not) this session, `false` otherwise
     */
    func resume(_ url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        self.logger?.trace(url: url, source: "iOS Safari")
        guard url.absoluteString.lowercased().hasPrefix(self.redirectURL.absoluteString.lowercased()) else { return false }

        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            else {
                self.finish(.failure(error: AuthenticationError(string: url.absoluteString, statusCode: 200)))
                return false
            }
        var items = self.handler.values(fromComponents: components)
        guard has(state: self.state, inItems: items) else { return false }
        if items["error"] != nil {
            self.finish(.failure(error: AuthenticationError(info: items, statusCode: 0)))
        } else {
            self.handler.credentials(from: items, callback: self.finish)
        }
        return true
    }

    func cancel() {
        self.finish(Result.failure(error: WebAuthError.userCancelled))
    }

    private func has(state: String?, inItems items: [String: String]) -> Bool {
        return state == nil || items["state"] == state
    }
}
