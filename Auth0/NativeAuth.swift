// NativeAuth.swift
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

public protocol AuthProvider {
    func login(withConnection connection: String, scope: String, parameters: [String: Any]) -> NativeAuthTransaction
}

public struct NativeAuthCredentials {
    let token: String
    let extras: [String: Any]

    public init(token: String, extras: [String: Any]) {
        self.token = token
        self.extras = extras
    }
}

public protocol NativeAuthTransaction: AuthTransaction {
    var scope: String { get }
    var connection: String { get }
    var parameters: [String: Any] { get }

    typealias Callback = (Result<NativeAuthCredentials>) -> ()
    func auth(callback: @escaping Callback) -> ()
}

public extension NativeAuthTransaction {

    var state: String? {
        return self.connection
    }

    public func start(callback: @escaping (Result<Credentials>) -> ()) {
        TransactionStore.sharedInstance.store(self)
        self.auth { result in
            switch result {
            case .success(let nativeAuthCredentials):
                self.socialAuthentication(nativeAuthCredentials, callback: callback)
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
    }

    private func socialAuthentication(_ nativeAuthCredentials: NativeAuthCredentials, callback: @escaping (Result<Credentials>) -> ()) {
        var parameters: [String: Any] = self.parameters
        nativeAuthCredentials.extras.forEach { key, value in parameters[key] = value }

        authentication().loginSocial(token: nativeAuthCredentials.token, connection: connection, scope: scope, parameters: parameters)
            .start { callback($0) }
    }

}
