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
import JWTDecode
#if WEB_AUTH_PLATFORM
import LocalAuthentication
#endif

/// Credentials management utility
public struct CredentialsManager {

    private let storage: A0SimpleKeychain
    private let storeKey: String
    private let authentication: Authentication
    #if WEB_AUTH_PLATFORM
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
    #if WEB_AUTH_PLATFORM
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
    #if WEB_AUTH_PLATFORM
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

    /// Calls the revoke token endpoint to revoke the refresh token and, if successful, the credentials are cleared. Otherwise,
    /// the credentials are not cleared and an error is raised through the callback.
    ///
    /// If no refresh token is available the endpoint is not called, the credentials are cleared, and the callback is invoked without an error.
    ///
    /// - Parameter callback: callback with an error if the refresh token could not be revoked
    public func revoke(_ callback: @escaping (CredentialsManagerError?) -> Void) {
        guard
            let data = self.storage.data(forKey: self.storeKey),
            let credentials = NSKeyedUnarchiver.unarchiveObject(with: data) as? Credentials,
            let refreshToken = credentials.refreshToken else {
                _ = self.clear()
                return callback(nil)
        }

        self.authentication
            .revoke(refreshToken: refreshToken)
            .start { result in
                switch result {
                case .failure(let error):
                    callback(CredentialsManagerError.revokeFailed(error))
                case .success:
                    _ = self.clear()
                    callback(nil)
                }
            }
    }

    /// Checks if a non-expired set of credentials are stored
    ///
    /// - Parameter minTTL: minimum lifetime in seconds the access token must have left.
    /// - Returns: if there are valid and non-expired credentials stored.
    public func hasValid(minTTL: Int = 0) -> Bool {
        guard let data = self.storage.data(forKey: self.storeKey),
            let credentials = NSKeyedUnarchiver.unarchiveObject(with: data) as? Credentials,
            credentials.accessToken != nil else { return false }
        return (!self.hasExpired(credentials) && !self.willExpire(credentials, within: minTTL)) || credentials.refreshToken != nil
    }

    /// Retrieve credentials from keychain and yield new credentials using `refreshToken` if `accessToken` has expired
    /// otherwise the retrieved credentails will be returned as they have not expired. Renewed credentials will be
    /// stored in the keychain.
    ///
    /// ```
    /// credentialsManager.credentials {
    ///    guard $0 == nil else { return }
    ///    print($1)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - scope: scopes to request for the new tokens. By default is nil which will ask for the same ones requested during original Auth.
    ///   - minTTL: minimum time in seconds the access token must remain valid to avoid being renewed.
    ///   - callback: callback with the user's credentials or the cause of the error.
    /// - Important: This method only works for a refresh token obtained after auth with OAuth 2.0 API Authorization.
    /// - Note: [Auth0 Refresh Tokens Docs](https://auth0.com/docs/tokens/concepts/refresh-tokens)
    #if WEB_AUTH_PLATFORM
    public func credentials(withScope scope: String? = nil, minTTL: Int = 0, callback: @escaping (CredentialsManagerError?, Credentials?) -> Void) {
        guard self.hasValid(minTTL: minTTL) else { return callback(.noCredentials, nil) }
        if #available(iOS 9.0, macOS 10.15, *), let bioAuth = self.bioAuth {
            guard bioAuth.available else { return callback(.touchFailed(LAError(LAError.touchIDNotAvailable)), nil) }
            bioAuth.validateBiometric {
                guard $0 == nil else {
                    return callback(.touchFailed($0!), nil)
                }
                self.retrieveCredentials(withScope: scope, minTTL: minTTL, callback: callback)
            }
        } else {
            self.retrieveCredentials(withScope: scope, minTTL: minTTL, callback: callback)
        }
    }
    #else
    public func credentials(withScope scope: String? = nil, minTTL: Int = 0, callback: @escaping (CredentialsManagerError?, Credentials?) -> Void) {
        guard self.hasValid(minTTL: minTTL) else { return callback(.noCredentials, nil) }
        self.retrieveCredentials(withScope: scope, minTTL: minTTL, callback: callback)
    }
    #endif

    private func retrieveCredentials(withScope scope: String?, minTTL: Int, callback: @escaping (CredentialsManagerError?, Credentials?) -> Void) {
        guard let data = self.storage.data(forKey: self.storeKey),
            let credentials = NSKeyedUnarchiver.unarchiveObject(with: data) as? Credentials else { return callback(.noCredentials, nil) }
        guard let expiresIn = credentials.expiresIn else { return callback(.noCredentials, nil) }
        guard self.hasExpired(credentials) ||
            self.willExpire(credentials, within: minTTL) ||
            self.hasScopeChanged(credentials, from: scope) else { return callback(nil, credentials) }
        guard let refreshToken = credentials.refreshToken else { return callback(.noRefreshToken, nil) }

        self.authentication.renew(withRefreshToken: refreshToken, scope: scope).start {
            switch $0 {
            case .success(let credentials):
                let newCredentials = Credentials(accessToken: credentials.accessToken,
                                                 tokenType: credentials.tokenType,
                                                 idToken: credentials.idToken,
                                                 refreshToken: credentials.refreshToken ?? refreshToken,
                                                 expiresIn: credentials.expiresIn,
                                                 scope: credentials.scope)
                if self.willExpire(newCredentials, within: minTTL) {
                    let accessTokenLifetime = Int(expiresIn.timeIntervalSinceNow)
                    // TODO: On the next major add a new case to CredentialsManagerError
                    let error = NSError(domain: "The lifetime of the renewed Access Token (\(accessTokenLifetime)s) is less than minTTL requested (\(minTTL)s). Increase the 'Token Expiration' setting of your Auth0 API in the dashboard or request a lower minTTL",
                        code: -99999,
                        userInfo: nil)
                    callback(.failedRefresh(error), nil)
                } else {
                    _ = self.store(credentials: newCredentials)
                    callback(nil, newCredentials)
                }
            case .failure(let error):
                callback(.failedRefresh(error), nil)
            }
        }
    }

    func willExpire(_ credentials: Credentials, within ttl: Int) -> Bool {
        if let expiresIn = credentials.expiresIn {
            return expiresIn < Date(timeIntervalSinceNow: TimeInterval(ttl))
        }

        return false
    }

    func hasExpired(_ credentials: Credentials) -> Bool {
        if let expiresIn = credentials.expiresIn {
            if expiresIn < Date() { return true }
        }

        if let token = credentials.idToken, let jwt = try? decode(jwt: token) {
            return jwt.expired
        }

        return false
    }

    func hasScopeChanged(_ credentials: Credentials, from scope: String?) -> Bool {
        if let newScope = scope, let lastScope = credentials.scope {
            let newScopeList = newScope.lowercased().split(separator: " ").sorted()
            let lastScopeList = lastScope.lowercased().split(separator: " ").sorted()

            return newScopeList != lastScopeList
        }

        return false
    }

}
