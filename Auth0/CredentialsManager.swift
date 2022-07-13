// swiftlint:disable file_length

import Foundation
import SimpleKeychain
import JWTDecode
#if WEB_AUTH_PLATFORM
import LocalAuthentication
#endif
#if canImport(Combine)
import Combine
#endif

/// Credentials management utility for securely storing and retrieving the user's credentials from the Keychain.
///
/// - See: ``CredentialsManagerError``
public struct CredentialsManager {

    private let storage: CredentialsStorage
    private let storeKey: String
    private let authentication: Authentication
    private let dispatchQueue = DispatchQueue(label: "com.auth0.credentialsmanager.serial")
    private let dispatchGroup = DispatchGroup()
    #if WEB_AUTH_PLATFORM
    var bioAuth: BioAuthentication?
    #endif

    /// Creates a new `CredentialsManager` instance.
    ///
    /// - Parameters:
    ///   - authentication: Auth0 Authentication API client.
    ///   - storeKey:       Key used to store user credentials in the Keychain. Defaults to 'credentials'.
    ///   - storage:        The ``CredentialsStorage`` instance used to manage credentials storage. Defaults to a standard `A0SimpleKeychain` instance.
    public init(authentication: Authentication, storeKey: String = "credentials", storage: CredentialsStorage = A0SimpleKeychain()) {
        self.storeKey = storeKey
        self.authentication = authentication
        self.storage = storage
    }

    /// Retrieves the user information from the Keychain synchronously, without checking if the credentials are expired.
    /// The user information is read from the stored [ID token](https://auth0.com/docs/security/tokens/id-tokens).
    ///
    /// ```
    /// let user = credentialsManager.user
    /// ```
    ///
    /// - Important: Access to this property will not be protected by biometric authentication.
    public var user: UserInfo? {
        guard let credentials = retrieveCredentials(),
              let jwt = try? decode(jwt: credentials.idToken) else { return nil }

        return UserInfo(json: jwt.body)
    }

    #if WEB_AUTH_PLATFORM
    /// Enables biometric authentication for additional security during credentials retrieval.
    ///
    /// ```
    /// credentialsManager.enableBiometrics(withTitle: "Touch to Login")
    /// ```
    ///
    /// If needed, you can specify a particular `LAPolicy` to be used. For example, you might want to support Face ID or
    /// Touch ID, but also allow fallback to passcode.
    ///
    /// ```
    /// credentialsManager.enableBiometrics(withTitle: "Touch or enter passcode to Login", 
    ///                                     evaluationPolicy: .deviceOwnerAuthentication)
    /// ```
    ///
    /// - Parameters:
    ///   - title:            Main message to display when Face ID or Touch ID is used.
    ///   - cancelTitle:      Cancel message to display when Face ID or Touch ID is used.
    ///   - fallbackTitle:    Fallback message to display when Face ID or Touch ID is used after a failed match.
    ///   - evaluationPolicy: Policy to be used for authentication policy evaluation.
    /// - Important: Access to the ``user`` property will not be protected by biometric authentication.
    public mutating func enableBiometrics(withTitle title: String, cancelTitle: String? = nil, fallbackTitle: String? = nil, evaluationPolicy: LAPolicy = LAPolicy.deviceOwnerAuthenticationWithBiometrics) {
        self.bioAuth = BioAuthentication(authContext: LAContext(), evaluationPolicy: evaluationPolicy, title: title, cancelTitle: cancelTitle, fallbackTitle: fallbackTitle)
    }
    #endif

    /// Stores a credentials instance in the Keychain.
    ///
    /// ```
    /// let didStore = credentialsManager.store(credentials: credentials)
    /// ```
    ///
    /// - Parameter credentials: Credentials instance to store.
    /// - Returns: If the credentials were stored.
    public func store(credentials: Credentials) -> Bool {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: credentials, requiringSecureCoding: true) else {
            return false
        }
        return self.storage.setEntry(data, forKey: storeKey)
    }

    /// Clears credentials stored in the Keychain.
    ///
    /// ```
    /// let didClear = credentialsManager.clear()
    /// ```
    ///
    /// - Returns: If the credentials were removed.
    public func clear() -> Bool {
        return self.storage.deleteEntry(forKey: storeKey)
    }

    /// Calls the `/oauth/revoke` endpoint to revoke the refresh token and then clears the credentials if the request
    /// was successful. Otherwise, the credentials will not be cleared and the callback will be called with a failure
    /// result containing a ``CredentialsManagerError/revokeFailed`` error.
    /// 
    /// ```
    /// credentialsManager.revoke { result in
    ///     switch result {
    ///     case .success:
    ///         print("Revoked refresh token and cleared credentials")
    ///     case .failure(let error):
    ///         print("Failed with: \(error)")
    ///     }
    /// }
    /// ```
    ///
    /// If you need to specify custom headers for the refresh token revocation:
    ///
    /// ```
    /// credentialsManager.revoke(headers: ["key": "value"]) { print($0) }
    /// ```
    ///
    /// If no refresh token is available the endpoint is not called, the credentials are cleared, and the callback is
    /// invoked with a success case.
    ///
    /// - Parameters:
    ///   - headers:  Additional headers to use when revoking the refresh token.
    ///   - callback: Callback that receives a `Result` containing either an empty success case or an error.
    /// - See: [Refresh tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - See: [Authentication API Endpoint](https://auth0.com/docs/api/authentication#revoke-refresh-token)
    public func revoke(headers: [String: String] = [:], _ callback: @escaping (CredentialsManagerResult<Void>) -> Void) {
        guard let data = self.storage.getEntry(forKey: self.storeKey),
              let credentials = try? NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data),
              let refreshToken = credentials.refreshToken else {
                  _ = self.clear()
                  return callback(.success(()))
        }

        self.authentication
            .revoke(refreshToken: refreshToken)
            .headers(headers)
            .start { result in
                switch result {
                case .failure(let error):
                    callback(.failure(CredentialsManagerError(code: .revokeFailed, cause: error)))
                case .success:
                    _ = self.clear()
                    callback(.success(()))
                }
            }
    }

    /// Checks that there are credentials stored, and that the access token has not expired and will not expire within
    /// the specified TTL.
    ///
    /// ```
    /// guard credentialsManager.hasValid() else {
    ///     // No valid credentials exist, present the login page
    /// }
    /// // Retrieve stored credentials
    /// ```
    ///
    /// - Parameter minTTL: Minimum lifetime in seconds the access token must have left. Defaults to `0`.
    /// - Returns: If there are credentials stored containing an access token that is neither expired or about to expire.
    /// - See: ``Credentials/expiresIn``
    public func hasValid(minTTL: Int = 0) -> Bool {
        guard let data = self.storage.getEntry(forKey: self.storeKey),
            let credentials = try? NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data) else { return false }
        return !self.hasExpired(credentials) && !self.willExpire(credentials, within: minTTL)
    }

    #if WEB_AUTH_PLATFORM
    /// Retrieves credentials from the Keychain and yields new credentials using the refresh token if the access token
    /// is expired. Otherwise, the retrieved credentials will be returned via the success case as they are not expired.
    /// Renewed credentials will be stored in the Keychain.
    ///
    /// ```
    /// credentialsManager.credentials { result in
    ///     switch result {
    ///     case .success(let credentials):
    ///         print("Obtained credentials: \(credentials)")
    ///     case .failure(let error):
    ///         print("Failed with: \(error)")
    ///     }
    /// }
    /// ```
    ///
    /// To avoid retrieving access tokens with too little time left, you can enforce a minimum TTL:
    ///
    /// ```
    /// credentialsManager.credentials(minTTL: 60) { print($0) }
    /// ```
    ///
    /// If you need to specify custom parameters or headers for the credentials renewal:
    ///
    /// ```
    /// credentialsManager.credentials(parameters: ["key": "value"],
    ///                                headers: ["key": "value"]) { print($0) }
    /// ```
    ///
    /// When renewing credentials you can get a downscoped access token by requesting fewer scopes than were requested
    /// on login. If you specify fewer scopes, the credentials will be renewed immediately, regardless of whether they
    /// are expired or not.
    ///
    /// ```
    /// credentialsManager.credentials(scope: "openid offline_access") { print($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - scope:      Space-separated list of scope values to request when renewing credentials. Defaults to `nil`, which will ask for the same scopes that were requested on login.
    ///   - minTTL:     Minimum time in seconds the access token must remain valid to avoid being renewed. Defaults to `0`.
    ///   - parameters: Additional parameters to use when renewing credentials.
    ///   - headers:    Additional headers to use when renewing credentials.
    ///   - callback:   Callback that receives a `Result` containing either the user's credentials or an error.
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If the credentials are expired and there is no refresh token, the callback will be called with a failure case containing a ``CredentialsManagerError/noRefreshToken`` error.
    /// - Note: This method is thread-safe.
    /// - See: [Refresh tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - See: [Authentication API Endpoint](https://auth0.com/docs/api/authentication#refresh-token)
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
                            callback(.failure(CredentialsManagerError(code: .renewFailed, cause: error)))
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

    /// Calls the `/oauth/revoke` endpoint to revoke the refresh token and then clears the credentials if the request
    /// was successful. Otherwise, the credentials are not cleared and the subscription completes with an error.
    ///
    /// ```
    /// credentialsManager
    ///     .revoke()
    ///     .sink(receiveCompletion: { completion in
    ///         switch completion {
    ///         case .finished:
    ///             print("Revoked refresh token and cleared credentials")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }, receiveValue: {})
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// If you need to specify custom headers for the refresh token revocation:
    ///
    /// ```
    /// credentialsManager
    ///     .revoke(headers: ["key": "value"])
    ///     .sink(receiveCompletion: { print($0) },
    ///           receiveValue: {})
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// If no refresh token is available the endpoint is not called, the credentials are cleared, and the subscription
    /// completes without an error.
    ///
    /// - Parameter headers: Additional headers to use when revoking the refresh token.
    /// - Returns: A type-erased publisher.
    /// - See: [Refresh tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - See: [Authentication API Endpoint](https://auth0.com/docs/api/authentication#revoke-refresh-token)
    func revoke(headers: [String: String] = [:]) -> AnyPublisher<Void, CredentialsManagerError> {
        return Deferred {
            Future { callback in
                return self.revoke(headers: headers, callback)
            }
        }.eraseToAnyPublisher()
    }

    /// Retrieves credentials from the Keychain and yields new credentials using the refresh token if the access token
    /// is expired. Otherwise, the subscription will complete with the retrieved credentials as they are not expired.
    /// Renewed credentials will be stored in the Keychain.
    ///
    /// ```
    /// credentialsManager
    ///     .credentials()
    ///     .sink(receiveCompletion: { completion in
    ///         if case .failure(let error) = completion {
    ///             print("Failed with: \(error)")
    ///         }
    ///     }, receiveValue: { credentials in
    ///         print("Obtained credentials: \(credentials)")
    ///     })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// To avoid retrieving access tokens with too little time left, you can enforce a minimum TTL:
    ///
    /// ```
    /// credentialsManager
    ///     .credentials(minTTL: 60)
    ///     .sink(receiveCompletion: { print($0) },
    ///           receiveValue: { print($0) })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// If you need to specify custom parameters or headers for the credentials renewal:
    ///
    /// ```
    /// credentialsManager
    ///     .credentials(parameters: ["key": "value"],
    ///                  headers: ["key": "value"])
    ///     .sink(receiveCompletion: { print($0) },
    ///           receiveValue: { print($0) })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// When renewing credentials you can get a downscoped access token by requesting fewer scopes than were requested
    /// on login. If you specify fewer scopes, the credentials will be renewed immediately, regardless of whether they
    /// are expired or not.
    ///
    /// ```
    /// credentialsManager
    ///     .credentials(scope: "openid offline_access")
    ///     .sink(receiveCompletion: { print($0) },
    ///           receiveValue: { print($0) })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// - Parameters:
    ///   - scope:      Space-separated list of scope values to request when renewing credentials. Defaults to `nil`, which will ask for the same scopes that were requested on login.
    ///   - minTTL:     Minimum time in seconds the access token must remain valid to avoid being renewed. Defaults to `0`.
    ///   - parameters: Additional parameters to use when renewing credentials.
    ///   - headers:    Additional headers to use when renewing credentials.
    /// - Returns: A type-erased publisher.
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If the credentials are expired and there is no refresh token, the subscription will complete with a ``CredentialsManagerError/noRefreshToken`` error.
    /// - Note: This method is thread-safe.
    /// - See: [Refresh tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - See: [Authentication API Endpoint](https://auth0.com/docs/api/authentication#refresh-token)
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

    /// Calls the `/oauth/revoke` endpoint to revoke the refresh token and then clears the credentials if the request
    /// was successful. Otherwise, the credentials are not cleared and an error is thrown.
    ///
    /// ```
    /// do {
    ///     try await credentialsManager.revoke()
    ///     print("Revoked refresh token and cleared credentials")
    /// } catch {
    ///     print("Failed with: \(error)")
    /// }
    /// ```
    ///
    /// If you need to specify custom headers for the refresh token revocation:
    ///
    /// ```
    /// try await credentialsManager.revoke(headers: ["key": "value"])
    /// ```
    ///
    /// If no refresh token is available the endpoint is not called, the credentials are cleared, and no error is thrown.
    ///
    /// - Parameter headers: Additional headers to use when revoking the refresh token.
    /// - Throws: An error of type ``CredentialsManagerError``.
    /// - See: [Refresh tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - See: [Authentication API Endpoint](https://auth0.com/docs/api/authentication#revoke-refresh-token)
    #if compiler(>=5.5.2)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func revoke(headers: [String: String] = [:]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.revoke(headers: headers, continuation.resume)
        }
    }
    #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func revoke(headers: [String: String] = [:]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.revoke(headers: headers, continuation.resume)
        }
    }
    #endif

    /// Retrieves credentials from the Keychain and yields new credentials using the refresh token if the access token
    /// is expired. Otherwise, return the retrieved credentials as they are not expired. Renewed credentials will be
    /// stored in the Keychain.
    ///
    /// ```
    /// do {
    ///     let credentials = try await credentialsManager.credentials()
    ///     print("Obtained credentials: \(credentials)")
    /// } catch {
    ///     print("Failed with: \(error)")
    /// }
    /// ```
    ///
    /// To avoid retrieving access tokens with too little time left, you can enforce a minimum TTL:
    ///
    /// ```
    /// let credentials = try await credentialsManager.credentials(minTTL: 60)
    /// ```
    ///
    /// If you need to specify custom parameters or headers for the credentials renewal:
    ///
    /// ```
    /// let credentials = try await credentialsManager.credentials(parameters: ["key": "value"],
    ///                                                            headers: ["key": "value"])
    /// ```
    ///
    /// When renewing credentials you can get a downscoped access token by requesting fewer scopes than were requested
    /// on login. If you specify fewer scopes, the credentials will be renewed immediately, regardless of whether they
    /// are expired or not.
    ///
    /// ```
    /// let credentials = try await credentialsManager.credentials(scope: "openid offline_access")
    /// ```
    ///
    /// - Parameters:
    ///   - scope:      Space-separated list of scope values to request when renewing credentials. Defaults to `nil`, which will ask for the same scopes that were requested on login.
    ///   - minTTL:     Minimum time in seconds the access token must remain valid to avoid being renewed. Defaults to `0`.
    ///   - parameters: Additional parameters to use when renewing credentials.
    ///   - headers:    Additional headers to use when renewing credentials.
    /// - Returns: The user's credentials.
    /// - Throws: An error of type ``CredentialsManagerError``.
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If the credentials are expired and there is no refresh token, the error ``CredentialsManagerError/noRefreshToken`` will be thrown.
    /// - Note: This method is thread-safe.
    /// - See: [Refresh tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - See: [Authentication API Endpoint](https://auth0.com/docs/api/authentication#refresh-token)
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
