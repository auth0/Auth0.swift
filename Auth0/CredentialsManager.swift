// CredentialsManager.swift
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
import SimpleKeychain

/// Credentials management utility
public struct CredentialsManager {

    private let storage = A0SimpleKeychain()
    private let storeKey = "credentials"
    private let authentication: Authentication

    /// Creates a new CredentialsManager instance
    ///
    /// - Parameters:
    ///   - authentication: Auth0 authentication instance
    public init(authentication: Authentication) {
        self.authentication = authentication
    }

    /// Store credentials instance in keychain
    ///
    /// - Parameter credentials: credentials instance to store
    /// - Returns: Bool outcome of success
    public func store(credentials: Credentials) -> Bool {
        return self.storage.setData(NSKeyedArchiver.archivedData(withRootObject: credentials), forKey: storeKey)
    }

    /// Retrieve credentials from keychain and yield new credentials if the accessToken has expired
    /// otherwise the retrieved credentails will be returned as they have not expired.
    ///
    /// - seeAlso: [Auth0 Refresh Tokens Docs](https://auth0.com/docs/tokens/refresh-token)
    ///
    /// ```
    /// credentialsManager.credentials {
    ///    guard $0 == nil else { return }
    ///    print($1)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - scope: scopes to request for the new tokens. By default is nil which will ask for the same ones requested during original Auth
    ///   - callback: callback with the user's credentials or the cause of the error.
    /// - Important: This method only works for a refresh token obtained after auth with OAuth 2.0 API Authorization.
    public func credentials(withScope scope: String? = nil, callback: @escaping (CredentialsManagerError?, Credentials?) -> Void) {
        guard
            let data = self.storage.data(forKey:self.storeKey),
            let credentials = NSKeyedUnarchiver.unarchiveObject(with: data) as? Credentials
            else { return callback(.noCredentials, nil) }
        guard let refreshToken = credentials.refreshToken else { return callback(.noRefreshToken, nil) }
        guard let expiresIn = credentials.expiresIn else { return callback(.noExpiresIn, nil) }
        guard expiresIn < Date() else { return callback(nil, credentials) }

        self.authentication.renew(withRefreshToken: refreshToken, scope: scope).start {
            switch $0 {
            case .success(let credentials):
                callback(nil, credentials)
            case .failure(let error):
                callback(.renewFailed(error), nil)
            }
        }
    }
}
