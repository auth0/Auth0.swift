import Foundation
import SimpleKeychain
import JWTDecode
#if WEB_AUTH_PLATFORM
import LocalAuthentication
#endif
#if canImport(Combine)
import Combine
#endif

/// Credentials management utility
public struct CredentialsManager {

    private let storage: CredentialsStorage
    private let storeKey: String
    private let authentication: Authentication
    private let dispatchQueue = DispatchQueue(label: "com.auth0.credentialsmanager.serial")
    private let dispatchGroup = DispatchGroup()
    #if WEB_AUTH_PLATFORM
    private var bioAuth: BioAuthentication?
    #endif

    /// Creates a new CredentialsManager instance
    ///
    /// - Parameters:
    ///   - authentication: Auth0 authentication instance
    ///   - storeKey: Key used to store user credentials in the keychain, defaults to "credentials"
    ///   - storage: The A0SimpleKeychain instance used to manage credentials storage. Defaults to a standard A0SimpleKeychain instance
    public init(authentication: Authentication, storeKey: String = "credentials", storage: CredentialsStorage = A0SimpleKeychain()) {
        self.storeKey = storeKey
        self.authentication = authentication
        self.storage = storage
    }

    /// Retrieve the user profile from keychain synchronously, without checking if the credentials are expired
    ///
    /// ```
    /// let user = credentialsManager.user
    /// ```
    /// - Important: Access to this property will not be protected by Biometric Authentication.
    public var user: UserInfo? {
        guard let credentials = retrieveCredentials(),
              let jwt = try? decode(jwt: credentials.idToken) else { return nil }

        return UserInfo(json: jwt.body)
    }

    #if WEB_AUTH_PLATFORM
    /// Enable Biometric Authentication for additional security during credentials retrieval
    ///
    /// - Parameters:
    ///   - title: main message to display when Touch ID is used
    ///   - cancelTitle: cancel message to display when Touch ID is used (iOS 10+)
    ///   - fallbackTitle: fallback message to display when Touch ID is used after a failed match
    ///   - evaluationPolicy: policy to be used for authentication policy evaluation
    public mutating func enableBiometrics(withTitle title: String, cancelTitle: String? = nil, fallbackTitle: String? = nil, evaluationPolicy: LAPolicy = LAPolicy.deviceOwnerAuthenticationWithBiometrics) {
        self.bioAuth = BioAuthentication(authContext: LAContext(), evaluationPolicy: evaluationPolicy, title: title, cancelTitle: cancelTitle, fallbackTitle: fallbackTitle)
    }
    #endif

    /// Store credentials instance in keychain
    ///
    /// - Parameter credentials: credentials instance to store
    /// - Returns: if credentials were stored
    public func store(credentials: Credentials) -> Bool {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: credentials, requiringSecureCoding: true) else {
            return false
        }
        return self.storage.setEntry(data, forKey: storeKey)
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
    /// - Parameters:
    ///   - headers: additional headers to add to a possible token revocation. The headers will be set via Request.headers.
    ///   - callback: callback with an error if the refresh token could not be revoked
    public func revoke(headers: [String: String] = [:], _ callback: @escaping (CredentialsManagerError?) -> Void) {
        guard let data = self.storage.getEntry(forKey: self.storeKey),
              let credentials = try? NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data),
              let refreshToken = credentials.refreshToken else {
                  _ = self.clear()
                  return callback(nil)
        }

        self.authentication
            .revoke(refreshToken: refreshToken)
            .headers(headers)
            .start { result in
                switch result {
                case .failure(let error):
                    callback(CredentialsManagerError(code: .revokeFailed, cause: error))
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
        guard let data = self.storage.getEntry(forKey: self.storeKey),
            let credentials = try? NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data) else { return false }
        return !self.hasExpired(credentials) && !self.willExpire(credentials, within: minTTL)
    }

    /// Retrieve credentials from keychain and yield new credentials using `refreshToken` if `accessToken` has expired
    /// otherwise the retrieved credentials will be returned as they have not expired. Renewed credentials will be
    /// stored in the keychain.
    ///
    /// ```
    /// credentialsManager.credentials { result in
    ///    switch result {
    ///    case .success(let credentials):
    ///        print("Obtained credentials: \(credentials)")
    ///    case .failure(let error):
    ///        print("Failed with \(error)")
    ///    }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - scope: scopes to request for the new tokens. By default is nil which will ask for the same ones requested during original Auth.
    ///   - minTTL: minimum time in seconds the access token must remain valid to avoid being renewed.
    ///   - parameters: additional parameters to add to a possible token refresh. The parameters will be set via Request.parameters.
    ///   - headers: additional headers to add to a possible token refresh. The headers will be set via Request.headers.
    ///   - callback: callback with the user's credentials or the cause of the error.
    /// - Important: This method only works for a refresh token obtained after auth with OAuth 2.0 API Authorization.
    /// - Note: [Auth0 Refresh Tokens Docs](https://auth0.com/docs/security/tokens/refresh-tokens)
    #if WEB_AUTH_PLATFORM
    public func credentials(withScope scope: String? = nil, minTTL: Int = 0, parameters: [String: Any] = [:], headers: [String: String] = [:], callback: @escaping (CredentialsManagerResult<Credentials>) -> Void) {
        if let bioAuth = self.bioAuth {
            guard bioAuth.available else {
                let error = CredentialsManagerError(code: .biometricsFailed,
                                                    cause: LAError(LAError.biometryNotAvailable))
                return callback(.failure(error))
            }
            bioAuth.validateBiometric {
                guard $0 == nil else {
                    return callback(.failure(CredentialsManagerError(code: .biometricsFailed, cause: $0!)))
                }
                self.retrieveCredentials(withScope: scope, minTTL: minTTL, parameters: parameters, headers: headers, callback: callback)
            }
        } else {
            self.retrieveCredentials(withScope: scope, minTTL: minTTL, parameters: parameters, headers: headers, callback: callback)
        }
    }
    #else
    public func credentials(withScope scope: String? = nil, minTTL: Int = 0, parameters: [String: Any] = [:], headers: [String: String] = [:], callback: @escaping (CredentialsManagerResult<Credentials>) -> Void) {
        self.retrieveCredentials(withScope: scope, minTTL: minTTL, parameters: parameters, headers: headers, callback: callback)
    }
    #endif

    private func retrieveCredentials() -> Credentials? {
        guard let data = self.storage.getEntry(forKey: self.storeKey),
              let credentials = try? NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data) else { return nil }

        return credentials
    }

    private func retrieveCredentials(withScope scope: String?, minTTL: Int, parameters: [String: Any], headers: [String: String], callback: @escaping (CredentialsManagerResult<Credentials>) -> Void) {
        self.dispatchQueue.async {
            self.dispatchGroup.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                guard let credentials = retrieveCredentials() else {
                    self.dispatchGroup.leave()
                    return callback(.failure(.noCredentials))
                }
                guard self.hasExpired(credentials) ||
                        self.willExpire(credentials, within: minTTL) ||
                        self.hasScopeChanged(credentials, from: scope) else {
                            self.dispatchGroup.leave()
                            return callback(.success(credentials))
                        }
                guard let refreshToken = credentials.refreshToken else {
                    self.dispatchGroup.leave()
                    return callback(.failure(.noRefreshToken))
                }
                self.authentication
                    .renew(withRefreshToken: refreshToken, scope: scope)
                    .parameters(parameters)
                    .headers(headers)
                    .start { result in
                        switch result {
                        case .success(let credentials):
                            let newCredentials = Credentials(accessToken: credentials.accessToken,
                                                             tokenType: credentials.tokenType,
                                                             idToken: credentials.idToken,
                                                             refreshToken: credentials.refreshToken ?? refreshToken,
                                                             expiresIn: credentials.expiresIn,
                                                             scope: credentials.scope)
                            if self.willExpire(newCredentials, within: minTTL) {
                                let tokenLifetime = Int(credentials.expiresIn.timeIntervalSinceNow)
                                let error = CredentialsManagerError(code: .largeMinTTL(minTTL: minTTL, lifetime: tokenLifetime))
                                self.dispatchGroup.leave()
                                callback(.failure(error))
                            } else {
                                _ = self.store(credentials: newCredentials)
                                self.dispatchGroup.leave()
                                callback(.success(newCredentials))
                            }
                        case .failure(let error):
                            self.dispatchGroup.leave()
                            callback(.failure(CredentialsManagerError(code: .refreshFailed, cause: error)))
                        }
                    }
            }

            self.dispatchGroup.wait()
        }
    }

    func willExpire(_ credentials: Credentials, within ttl: Int) -> Bool {
        return credentials.expiresIn < Date(timeIntervalSinceNow: TimeInterval(ttl))
    }

    func hasExpired(_ credentials: Credentials) -> Bool {
        return credentials.expiresIn < Date()
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

// MARK: - Combine

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
public extension CredentialsManager {

    /// Calls the revoke token endpoint to revoke the refresh token and, if successful, the credentials are cleared. Otherwise,
    /// the credentials are not cleared and the subscription completes with an error.
    ///
    /// If no refresh token is available the endpoint is not called, the credentials are cleared, and the subscription completes
    /// without an error.
    ///
    /// - Parameter headers: additional headers to add to a possible token revocation. The headers will be set via Request.headers.
    /// - Returns: a type-erased publisher.
    func revoke(headers: [String: String] = [:]) -> AnyPublisher<Void, CredentialsManagerError> {
        return Deferred {
            Future { callback in
                return self.revoke(headers: headers) { error in
                    if let error = error { return callback(.failure(error)) }
                    callback(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }

    /// Retrieve credentials from the keychain and yield new credentials using `refreshToken` if `accessToken` has expired,
    /// otherwise the subscription will complete with the retrieved credentials as they have not expired. Renewed credentials will
    /// be stored in the keychain.
    ///
    /// ```
    /// credentialsManager
    ///     .credentials()
    ///     .sink(receiveCompletion: { completion in
    ///         if case .failure(let error) = completion {
    ///             print("Failed with \(error)")
    ///         }
    ///     }, receiveValue: { credentials in
    ///         print("Obtained credentials: \(credentials)")
    ///     })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// - Parameters:
    ///   - scope: scopes to request for the new tokens. By default is nil which will ask for the same ones requested during original Auth.
    ///   - minTTL: minimum time in seconds the access token must remain valid to avoid being renewed.
    ///   - parameters: additional parameters to add to a possible token refresh. The parameters will be set via Request.parameters.
    ///   - headers: additional headers to add to a possible token refresh. The headers will be set via Request.headers.
    /// - Returns: a type-erased publisher.
    /// - Important: This method only works for a refresh token obtained after auth with OAuth 2.0 API Authorization.
    /// - Note: [Auth0 Refresh Tokens Docs](https://auth0.com/docs/security/tokens/refresh-tokens)
    func credentials(withScope scope: String? = nil, minTTL: Int = 0, parameters: [String: Any] = [:], headers: [String: String] = [:]) -> AnyPublisher<Credentials, CredentialsManagerError> {
        return Deferred {
            Future { callback in
                return self.credentials(withScope: scope,
                                        minTTL: minTTL,
                                        parameters: parameters,
                                        headers: headers,
                                        callback: callback)
            }
        }.eraseToAnyPublisher()
    }

}

// MARK: - Async/Await

#if compiler(>=5.5) && canImport(_Concurrency)
public extension CredentialsManager {

    /// Calls the revoke token endpoint to revoke the refresh token and, if successful, the credentials are cleared. Otherwise,
    /// the credentials are not cleared and an error is thrown.
    ///
    /// If no refresh token is available the endpoint is not called, the credentials are cleared, and no error is thrown.
    ///
    /// - Parameter headers: additional headers to add to a possible token revocation. The headers will be set via Request.headers.
    /// - Throws: An error of type `CredentialsManagerError`.
    #if compiler(>=5.5.2)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func revoke(headers: [String: String] = [:]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.revoke(headers: headers) { error in
                if let error = error { return continuation.resume(throwing: error) }
                continuation.resume(returning: ())
            }
        }
    }
    #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func revoke(headers: [String: String] = [:]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.revoke(headers: headers) { error in
                if let error = error { return continuation.resume(throwing: error) }
                continuation.resume(returning: ())
            }
        }
    }
    #endif

    /// Retrieve credentials from the keychain and yield new credentials using `refreshToken` if `accessToken` has expired,
    /// otherwise return the retrieved credentials as they have not expired. Renewed credentials will
    /// be stored in the keychain.
    ///
    /// ```
    /// let credentials = try await credentialsManager.credentials()
    /// ```
    ///
    /// - Parameters:
    ///   - scope: scopes to request for the new tokens. By default is nil which will ask for the same ones requested during original Auth.
    ///   - minTTL: minimum time in seconds the access token must remain valid to avoid being renewed.
    ///   - parameters: additional parameters to add to a possible token refresh. The parameters will be set via Request.parameters.
    ///   - headers: additional headers to add to a possible token refresh. The headers will be set via Request.headers.
    /// - Returns: the user's credentials.
    /// - Throws: An error of type `CredentialsManagerError`.
    /// - Important: This method only works for a refresh token obtained after auth with OAuth 2.0 API Authorization.
    /// - Note: [Auth0 Refresh Tokens Docs](https://auth0.com/docs/security/tokens/refresh-tokens)
    #if compiler(>=5.5.2)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func credentials(withScope scope: String? = nil, minTTL: Int = 0, parameters: [String: Any] = [:], headers: [String: String] = [:]) async throws -> Credentials {
        return try await withCheckedThrowingContinuation { continuation in
            self.credentials(withScope: scope,
                             minTTL: minTTL,
                             parameters: parameters,
                             headers: headers,
                             callback: continuation.resume)
        }
    }
    #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func credentials(withScope scope: String? = nil, minTTL: Int = 0, parameters: [String: Any] = [:], headers: [String: String] = [:]) async throws -> Credentials {
        return try await withCheckedThrowingContinuation { continuation in
            self.credentials(withScope: scope,
                             minTTL: minTTL,
                             parameters: parameters,
                             headers: headers,
                             callback: continuation.resume)
        }
    }
    #endif

}
#endif
