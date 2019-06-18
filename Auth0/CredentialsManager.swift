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
#if os(iOS)
import LocalAuthentication
#endif

/// Credentials management utility
public struct CredentialsManager {

    private let storage: A0SimpleKeychain
    private let storeKey: String
    private let authentication: Authentication
    #if os(iOS)
    private var bioAuth: BioAuthentication?
    #endif

    /// Creates a new CredentialsManager instance
    ///
    /// - Parameters:
    ///   - authentication: Auth0 authentication instance
    ///   - storeKey: Key used to store user credentials in the keychain, defaults to "credentials"
    ///   - storage: The A0SimpleKeychain instance used to manage credentials storage. Defaults to a standard A0SimpleKeychain instance
    public init(authentication: Authentication, storeKey: String = "credentials", storage: A0SimpleKeychain = A0SimpleKeychain()) {
        self.storeKey = storeKey
        self.authentication = authentication
        self.storage = storage
    }

    /// Enable Touch ID Authentication for additional security during credentials retrieval.
    ///
    /// - Parameters:
    ///   - title: main message to display in TouchID prompt
    ///   - cancelTitle: cancel message to display in TouchID prompt (iOS 10+)
    ///   - fallbackTitle: fallback message to display in TouchID prompt after a failed match
    #if os(iOS)
    @available(*, deprecated, message: "see enableBiometrics(withTitle title:, cancelTitle:, fallbackTitle:)")
    public mutating func enableTouchAuth(withTitle title: String, cancelTitle: String? = nil, fallbackTitle: String? = nil) {
        self.enableBiometrics(withTitle: title, cancelTitle: cancelTitle, fallbackTitle: fallbackTitle)
    }
    #endif

    /// Enable Biometric Authentication for additional security during credentials retrieval.
    ///
    /// - Parameters:
    ///   - title: main message to display when Touch ID is used
    ///   - cancelTitle: cancel message to display when Touch ID is used (iOS 10+)
    ///   - fallbackTitle: fallback message to display when Touch ID is used after a failed match
    #if os(iOS)
    public mutating func enableBiometrics(withTitle title: String, cancelTitle: String? = nil, fallbackTitle: String? = nil) {
        self.bioAuth = BioAuthentication(authContext: LAContext(), title: title, cancelTitle: cancelTitle, fallbackTitle: fallbackTitle)
    }
    #endif

    /// Store credentials instance in keychain
    ///
    /// - Parameter credentials: credentials instance to store
    /// - Returns: if credentials were stored
    public func store(credentials: Credentials) -> Bool {
        return self.storage.setData(NSKeyedArchiver.archivedData(withRootObject: credentials), forKey: storeKey)
    }

    /// Clear credentials stored in keychain
    ///
    /// - Returns: if credentials were removed
    public func clear() -> Bool {
        return self.storage.deleteEntry(forKey: storeKey)
    }

    /// Checks if a non-expired set of credentials are stored
    ///
    /// - Returns: if there are valid and non-expired credentials stored
    public func hasValid() -> Bool {
        guard
            let data = self.storage.data(forKey: self.storeKey),
            let credentials = NSKeyedUnarchiver.unarchiveObject(with: data) as? Credentials,
            credentials.accessToken != nil,
            let expiresIn = credentials.expiresIn
            else { return false }
        return expiresIn > Date() || credentials.refreshToken != nil
    }

    /// Retrieve credentials from keychain and yield new credentials using refreshToken if accessToken has expired
    /// otherwise the retrieved credentails will be returned as they have not expired. Renewed credentials will be 
    /// stored in the keychain.
    ///
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
    /// - Note: [Auth0 Refresh Tokens Docs](https://auth0.com/docs/tokens/refresh-token)
    #if os(iOS)
    public func credentials(withScope scope: String? = nil, callback: @escaping (CredentialsManagerError?, Credentials?) -> Void) {
        guard self.hasValid() else { return callback(.noCredentials, nil) }
        if let bioAuth = self.bioAuth {
            guard bioAuth.available else { return callback(.touchFailed(LAError(LAError.touchIDNotAvailable)), nil) }
            bioAuth.validateBiometric {
                guard $0 == nil else {
                    return callback(.touchFailed($0!), nil)
                }
                self.retrieveCredentials(withScope: scope, callback: callback)
            }
        } else {
            self.retrieveCredentials(withScope: scope, callback: callback)
        }
    }
    #else
    public func credentials(withScope scope: String? = nil, callback: @escaping (CredentialsManagerError?, Credentials?) -> Void) {
        guard self.hasValid() else { return callback(.noCredentials, nil) }
        self.retrieveCredentials(withScope: scope, callback: callback)
    }
    #endif

    private func retrieveCredentials(withScope scope: String? = nil, callback: @escaping (CredentialsManagerError?, Credentials?) -> Void) {
        guard
            let data = self.storage.data(forKey: self.storeKey),
            let credentials = NSKeyedUnarchiver.unarchiveObject(with: data) as? Credentials
            else { return callback(.noCredentials, nil) }
        guard let expiresIn = credentials.expiresIn else { return callback(.noCredentials, nil) }
        guard expiresIn < Date() else { return callback(nil, credentials) }
        guard let refreshToken = credentials.refreshToken else { return callback(.noRefreshToken, nil) }

        self.authentication.renew(withRefreshToken: refreshToken, scope: scope).start {
            switch $0 {
            case .success(let credentials):
                let newCredentials = Credentials(accessToken: credentials.accessToken,
                                                 tokenType: credentials.tokenType,
                                                 idToken: credentials.idToken,
                                                 refreshToken: refreshToken,
                                                 expiresIn: credentials.expiresIn,
                                                 scope: credentials.scope)
                _ = self.store(credentials: newCredentials)
                callback(nil, newCredentials)
            case .failure(let error):
                callback(.failedRefresh(error), nil)
            }
        }
    }
}
