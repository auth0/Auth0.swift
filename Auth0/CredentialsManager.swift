// swiftlint:disable file_length

import Foundation
import SimpleKeychain
import JWTDecode
import Combine
#if WEB_AUTH_PLATFORM
import LocalAuthentication
#endif

/// Credentials management utility for securely storing and retrieving the user's credentials from the Keychain.
///
/// - Warning: The Credentials Manager is not thread-safe, except for its
/// ``CredentialsManager/credentials(withScope:minTTL:parameters:headers:callback:)``,
/// ``CredentialsManager/apiCredentials(forAudience:scope:minTTL:parameters:headers:callback:)``, and
/// ``CredentialsManager/renew(parameters:headers:callback:)`` methods. To avoid concurrency issues, do not call its
/// non thread-safe methods and properties from different threads without proper synchronization.
///
/// ## See Also
///
/// - ``CredentialsManagerError``
/// - <doc:RefreshTokens>
public struct CredentialsManager {

    private let storage: CredentialsStorage
    private let storeKey: String
    private let authentication: Authentication
    private let dispatchQueue = DispatchQueue(label: "com.auth0.credentialsmanager.serial")
    #if WEB_AUTH_PLATFORM
    var bioAuth: BioAuthentication?
    #endif

    /// Creates a new `CredentialsManager` instance.
    ///
    /// - Parameters:
    ///   - authentication: Auth0 Authentication API client.
    ///   - storeKey:       Key used to store user credentials in the Keychain. Defaults to 'credentials'.
    ///   - storage:        The ``CredentialsStorage`` instance used to manage credentials storage. Defaults to a standard `SimpleKeychain` instance.
    public init(authentication: Authentication,
                storeKey: String = "credentials",
                storage: CredentialsStorage = SimpleKeychain()) {
        self.storeKey = storeKey
        self.authentication = authentication
        self.storage = storage
    }

    /// Retrieves the user information from the Keychain synchronously, without checking if the credentials are expired.
    /// The user information is read from the stored [ID token](https://auth0.com/docs/secure/tokens/id-tokens).
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let user = credentialsManager.user
    /// ```
    ///
    /// - Important: Access to this property will not be protected by biometric authentication.
    public var user: UserInfo? {
        guard let credentials = self.retrieveCredentials(),
              let jwt = try? decode(jwt: credentials.idToken) else { return nil }

        return UserInfo(json: jwt.body)
    }

    #if WEB_AUTH_PLATFORM
    /// Enables biometric authentication for additional security during credentials retrieval.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID")
    /// ```
    ///
    /// If needed, you can specify a particular `LAPolicy` to be used. For example, you might want to support Face ID or
    /// Touch ID, but also allow fallback to passcode.
    ///
    /// ```swift
    /// credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID or passcode", 
    ///                                     evaluationPolicy: .deviceOwnerAuthentication)
    /// ```
    ///
    /// - Parameters:
    ///   - title:            Main message to display when Face ID or Touch ID is used.
    ///   - cancelTitle:      Cancel message to display when Face ID or Touch ID is used.
    ///   - fallbackTitle:    Fallback message to display when Face ID or Touch ID is used after a failed match.
    ///   - evaluationPolicy: Policy to be used for authentication policy evaluation.
    /// - Important: Access to the ``user`` property will not be protected by biometric authentication.
    public mutating func enableBiometrics(withTitle title: String,
                                          cancelTitle: String? = nil,
                                          fallbackTitle: String? = nil,
                                          evaluationPolicy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics) {
        self.bioAuth = BioAuthentication(authContext: LAContext(), evaluationPolicy: evaluationPolicy, title: title, cancelTitle: cancelTitle, fallbackTitle: fallbackTitle)
    }
    #endif

    /// Stores a ``Credentials`` instance in the Keychain.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let didStore = credentialsManager.store(credentials: credentials)
    /// ```
    ///
    /// - Parameter credentials: ``Credentials`` instance to store.
    /// - Returns: If the credentials were stored.
    public func store(credentials: Credentials) -> Bool {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: credentials,
                                                           requiringSecureCoding: true) else {
            return false
        }

        return self.storage.setEntry(data, forKey: self.storeKey)
    }

    /// Clears credentials stored in the Keychain.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let didClear = credentialsManager.clear()
    /// ```
    ///
    /// - Returns: If the credentials were removed.
    public func clear() -> Bool {
        return self.storage.deleteEntry(forKey: self.storeKey)
    }

    /// Clears API credentials stored in the Keychain for a given audience value.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let didClear = credentialsManager.clear(forAudience: "http://example.com/api")
    /// ```
    ///
    /// - Parameter audience: Identifier of the API the stored API credentials are for.
    /// - Returns: If the API credentials were removed.
    public func clear(forAudience audience: String) -> Bool {
        return self.storage.deleteEntry(forKey: audience)
    }

    /// Calls the `/oauth/revoke` endpoint to revoke the refresh token and then clears the credentials if the request
    /// was successful. Otherwise, the credentials will not be cleared and the callback will be called with a failure
    /// result containing a ``CredentialsManagerError/revokeFailed`` error.
    ///
    /// ## Usage
    /// 
    /// ```swift
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
    /// You can specify custom headers for the refresh token revocation:
    ///
    /// ```swift
    /// credentialsManager.revoke(headers: ["key": "value"]) { print($0) }
    /// ```
    ///
    /// If no refresh token is available the endpoint is not called, the credentials are cleared, and the callback is
    /// invoked with a success case.
    ///
    /// - Parameters:
    ///   - headers:  Additional headers to use when revoking the refresh token.
    ///   - callback: Callback that receives a `Result` containing either an empty success case or an error.
    ///
    /// ## See Also
    ///
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/revoke-refresh-token/revoke-refresh-token)
    public func revoke(headers: [String: String] = [:],
                       _ callback: @escaping (CredentialsManagerResult<Void>) -> Void) {
        guard let credentials = self.retrieveCredentials(),
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
    /// the specified TTL. If you are not using refresh tokens, use this method instead of ``canRenew()`` to
    /// check for stored credentials when your app starts up.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// guard credentialsManager.hasValid() else {
    ///     // No valid credentials exist, present the login page
    /// }
    /// // Retrieve the stored credentials
    /// ```
    ///
    /// - Parameter minTTL: Minimum lifetime in seconds the access token must have left. Defaults to `0`.
    /// - Returns: If there are credentials stored containing an access token that is neither expired or about to expire.
    ///
    /// ## See Also
    ///
    /// - ``Credentials/expiresIn``
    public func hasValid(minTTL: Int = 0) -> Bool {
        guard let credentials = self.retrieveCredentials() else { return false }
        return !self.hasExpired(credentials.expiresIn) && !self.willExpire(credentials.expiresIn, within: minTTL)
    }

    /// Checks that there are credentials stored, and that the credentials contain a refresh token. If you are using
    /// refresh tokens, use this method instead of ``hasValid(minTTL:)`` to check for stored credentials when your app
    /// starts up.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// guard credentialsManager.canRenew() else {
    ///     // No renewable credentials exist, present the login page
    /// }
    /// // Retrieve the stored credentials
    /// ```
    ///
    /// - Returns: If there are credentials stored containing a refresh token.
    public func canRenew() -> Bool {
        guard let credentials = self.retrieveCredentials() else { return false }
        return credentials.refreshToken != nil
    }

    #if WEB_AUTH_PLATFORM
    /// Retrieves credentials from the Keychain and automatically renews them using the refresh token if the access
    /// token is expired. Otherwise, the retrieved credentials will be returned via the success case as they are still
    /// valid. Renewed credentials will be stored in the Keychain. **This method is thread-safe**.
    ///
    /// ## Usage
    ///
    /// ```swift
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
    /// To avoid retrieving access tokens with too little time left, enforce a minimum TTL (in seconds):
    ///
    /// ```swift
    /// credentialsManager.credentials(minTTL: 60) { print($0) }
    /// ```
    ///
    /// You can specify custom parameters or headers for the renewal request:
    ///
    /// ```swift
    /// credentialsManager.credentials(parameters: ["key": "value"],
    ///                                headers: ["key": "value"]) { print($0) }
    /// ```
    ///
    /// When renewing credentials you can get a downscoped access token by requesting fewer scopes than were requested
    /// on login. If you specify fewer scopes, the credentials will be renewed immediately, regardless of whether they
    /// are expired or not.
    ///
    /// ```swift
    /// credentialsManager.credentials(scope: "openid offline_access") { print($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - scope:      Space-separated list of scope values to request when renewing credentials. Defaults to `nil`, which will ask for the same scopes that were requested on login.
    ///   - minTTL:     Minimum time in seconds the access token must remain valid to avoid being renewed. Defaults to `0`.
    ///   - parameters: Additional parameters to use when renewing credentials.
    ///   - headers:    Additional headers to use when renewing credentials.
    ///   - callback:   Callback that receives a `Result` containing either the user's credentials or an error.
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If
    /// the credentials are expired and there is no refresh token, the callback will be called with a
    /// ``CredentialsManagerError/noRefreshToken`` error.
    /// - Warning: Do not call `store(credentials:)` afterward. The Credentials Manager automatically persists the
    /// renewed credentials. Since this method is thread-safe and ``store(credentials:)`` is not, calling it anyway can
    /// cause concurrency issues.
    /// - Important: To ensure that no concurrent renewal requests get made, do not call this method from multiple
    /// Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.
    ///
    /// ## See Also
    ///
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/refresh-token/refresh-token)
    /// - <doc:RefreshTokens>
    public func credentials(withScope scope: String? = nil,
                            minTTL: Int = 0,
                            parameters: [String: Any] = [:],
                            headers: [String: String] = [:],
                            callback: @escaping (CredentialsManagerResult<Credentials>) -> Void) {
        if let bioAuth = self.bioAuth {
            guard bioAuth.available else {
                let error = CredentialsManagerError(code: .biometricsFailed,
                                                    cause: LAError(.biometryNotAvailable))
                return callback(.failure(error))
            }

            bioAuth.validateBiometric { error in
                guard error == nil else {
                    return callback(.failure(CredentialsManagerError(code: .biometricsFailed, cause: error!)))
                }

                self.retrieveCredentials(scope: scope,
                                         minTTL: minTTL,
                                         parameters: parameters,
                                         headers: headers,
                                         forceRenewal: false,
                                         callback: callback)
            }
        } else {
            self.retrieveCredentials(scope: scope,
                                     minTTL: minTTL,
                                     parameters: parameters,
                                     headers: headers,
                                     forceRenewal: false,
                                     callback: callback)
        }
    }
    #else
    /// Retrieves credentials from the Keychain and automatically renews them using the refresh token if the access
    /// token is expired. Otherwise, the retrieved credentials will be returned via the success case as they are still
    /// valid. Renewed credentials will be stored in the Keychain. **This method is thread-safe**.
    ///
    /// ## Usage
    ///
    /// ```swift
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
    /// To avoid retrieving access tokens with too little time left, enforce a minimum TTL (in seconds):
    ///
    /// ```swift
    /// credentialsManager.credentials(minTTL: 60) { print($0) }
    /// ```
    ///
    /// You can specify custom parameters or headers for the renewal request:
    ///
    /// ```swift
    /// credentialsManager.credentials(parameters: ["key": "value"],
    ///                                headers: ["key": "value"]) { print($0) }
    /// ```
    ///
    /// When renewing credentials you can get a downscoped access token by requesting fewer scopes than were requested
    /// on login. If you specify fewer scopes, the credentials will be renewed immediately, regardless of whether they
    /// are expired or not.
    ///
    /// ```swift
    /// credentialsManager.credentials(scope: "openid offline_access") { print($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - scope:      Space-separated list of scope values to request when renewing credentials. Defaults to `nil`, which will ask for the same scopes that were requested on login.
    ///   - minTTL:     Minimum time in seconds the access token must remain valid to avoid being renewed. Defaults to `0`.
    ///   - parameters: Additional parameters to use when renewing credentials.
    ///   - headers:    Additional headers to use when renewing credentials.
    ///   - callback:   Callback that receives a `Result` containing either the user's credentials or an error.
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If
    /// the credentials are expired and there is no refresh token, the callback will be called with a
    /// ``CredentialsManagerError/noRefreshToken`` error.
    /// - Warning: Do not call `store(credentials:)` afterward. The Credentials Manager automatically persists the
    /// renewed credentials. Since this method is thread-safe and ``store(credentials:)`` is not, calling it anyway can
    /// cause concurrency issues.
    /// - Important: To ensure that no concurrent renewal requests get made, do not call this method from multiple
    /// Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.
    ///
    /// ## See Also
    ///
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/refresh-token/refresh-token)
    /// - <doc:RefreshTokens>
    public func credentials(withScope scope: String? = nil,
                            minTTL: Int = 0,
                            parameters: [String: Any] = [:],
                            headers: [String: String] = [:],
                            callback: @escaping (CredentialsManagerResult<Credentials>) -> Void) {
        self.retrieveCredentials(scope: scope,
                                 minTTL: minTTL,
                                 parameters: parameters,
                                 headers: headers,
                                 forceRenewal: false,
                                 callback: callback)
    }
    #endif

    /// Retrieves API credentials from the Keychain and automatically renews them using the refresh token if the access
    /// token is expired. Otherwise, the retrieved API credentials will be returned via the success case as they are
    /// still valid.
    ///
    /// If there are no stored API credentials, the refresh token will be exchaged for a new set of API credentials.
    /// New or renewed API credentials will be automatically stored in the Keychain. **This method is thread-safe**.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// credentialsManager.apiCredentials(forAudience: "http://example.com/api") { result in
    ///     switch result {
    ///     case .success(let apiCredentials):
    ///         print("Obtained API credentials: \(apiCredentials)")
    ///     case .failure(let error):
    ///         print("Failed with: \(error)")
    ///     }
    /// }
    /// ```
    ///
    /// The default scopes configured for the API will be granted if you don't request any specific scopes. If you
    /// request different scopes than the ones that were granted last time, the API credentials will be renewed
    /// immediately, regardless of whether they are expired or not.
    ///
    /// ```swift
    /// credentialsManager.apiCredentials(forAudience: "http://example.com/api",
    ///                                   scope: "read:todos update:todos") { print($0) }
    /// ```
    ///
    /// To avoid retrieving access tokens with too little time left, enforce a minimum TTL (in seconds):
    ///
    /// ```swift
    /// credentialsManager.apiCredentials(forAudience: "http://example.com/api",
    ///                                   minTTL: 60) { print($0) }
    /// ```
    ///
    /// You can specify custom parameters or headers for the exchange request:
    ///
    /// ```swift
    /// credentialsManager.apiCredentials(forAudience: "http://example.com/api",
    ///                                   parameters: ["key": "value"],
    ///                                   headers: ["key": "value"]) { print($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - audience:   Identifier of the API that your application is requesting access to.
    ///   - scope:      Space-separated list of scope values to request when exchanging a refresh token for API credentials. Defaults to `nil`, which will ask for the default scopes configured for the API.
    ///   - minTTL:     Minimum time in seconds the access token must remain valid to avoid being renewed. Defaults to `0`.
    ///   - parameters: Additional parameters to use when exchanging a refresh token for API credentials.
    ///   - headers:    Additional headers to use when exchanging a refresh token for API credentials.
    ///   - callback:   Callback that receives a `Result` containing either the API credentials or an error.
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If
    /// the API credentials are expired and there is no refresh token, the callback will be called with a
    /// ``CredentialsManagerError/noRefreshToken`` error.
    /// - Important: To ensure that no concurrent exchange requests get made, do not call this method from multiple
    /// Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.
    ///
    /// ## See Also
    ///
    /// - [Scopes](https://auth0.com/docs/get-started/apis/scopes)
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/refresh-token/refresh-token)
    /// - <doc:RefreshTokens>
    public func apiCredentials(forAudience audience: String,
                               scope: String? = nil,
                               minTTL: Int = 0,
                               parameters: [String: Any] = [:],
                               headers: [String: String] = [:],
                               callback: @escaping (CredentialsManagerResult<APICredentials>) -> Void) {
        self.retrieveAPICredentials(audience: audience,
                                    scope: scope,
                                    minTTL: minTTL,
                                    parameters: parameters,
                                    headers: headers,
                                    callback: callback)
    }

    /// Renews credentials using the refresh token and stores them in the Keychain. **This method is thread-safe**.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// credentialsManager.renew { result in
    ///     switch result {
    ///     case .success(let credentials):
    ///         print("Renewed credentials: \(credentials)")
    ///     case .failure(let error):
    ///         print("Failed with: \(error)")
    ///     }
    /// }
    /// ```
    ///
    /// You can specify custom parameters or headers for the renewal request:
    ///
    /// ```swift
    /// credentialsManager.renew(parameters: ["key": "value"],
    ///                          headers: ["key": "value"]) { print($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - parameters: Additional parameters to use.
    ///   - headers:    Additional headers to use.
    ///   - callback:   Callback that receives a `Result` containing either the renewed user's credentials or an error.
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If
    /// there is no refresh token, the callback will be called with a ``CredentialsManagerError/noRefreshToken`` error.
    /// - Warning: Do not call `store(credentials:)` afterward. The Credentials Manager automatically persists the
    /// renewed credentials. Since this method is thread-safe and ``store(credentials:)`` is not, calling it anyway can
    /// cause concurrency issues.
    /// - Important: To ensure that no concurrent renewal requests get made, do not call this method from multiple
    /// Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.
    ///
    /// ## See Also
    ///
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/refresh-token/refresh-token)
    /// - <doc:RefreshTokens>
    public func renew(parameters: [String: Any] = [:],
                      headers: [String: String] = [:],
                      callback: @escaping (CredentialsManagerResult<Credentials>) -> Void) {
        self.retrieveCredentials(scope: nil,
                                 minTTL: 0,
                                 parameters: parameters,
                                 headers: headers,
                                 forceRenewal: true,
                                 callback: callback)
    }

    func store(apiCredentials: APICredentials, forAudience audience: String) -> Bool {
        guard let data = try? apiCredentials.encode() else {
            return false
        }

        return self.storage.setEntry(data, forKey: audience)
    }

    private func retrieveCredentials() -> Credentials? {
        guard let data = self.storage.getEntry(forKey: self.storeKey) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data)
    }

    private func retrieveAPICredentials(audience: String) -> APICredentials? {
        guard let data = self.storage.getEntry(forKey: audience) else { return nil }
        return try? APICredentials(from: data)
    }

    // swiftlint:disable:next function_parameter_count
    private func retrieveCredentials(scope: String?,
                                     minTTL: Int,
                                     parameters: [String: Any],
                                     headers: [String: String],
                                     forceRenewal: Bool,
                                     callback: @escaping (CredentialsManagerResult<Credentials>) -> Void) {
        let dispatchGroup = DispatchGroup()

        self.dispatchQueue.async {
            dispatchGroup.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                guard let credentials = self.retrieveCredentials() else {
                    dispatchGroup.leave()
                    return callback(.failure(.noCredentials))
                }
                guard forceRenewal ||
                      self.hasExpired(credentials.expiresIn) ||
                      self.willExpire(credentials.expiresIn, within: minTTL) ||
                      self.hasScopeChanged(from: credentials.scope, to: scope) else {
                    dispatchGroup.leave()
                    return callback(.success(credentials))
                }
                guard let refreshToken = credentials.refreshToken else {
                    dispatchGroup.leave()
                    return callback(.failure(.noRefreshToken))
                }

                self.authentication
                    .renew(withRefreshToken: refreshToken, scope: scope)
                    .parameters(parameters)
                    .headers(headers)
                    .start { result in
                        switch result {
                        case .success(let credentials):
                            let newCredentials = Credentials(from: credentials,
                                                             refreshToken: credentials.refreshToken ?? refreshToken)
                            if self.willExpire(newCredentials.expiresIn, within: minTTL) {
                                let tokenTTL = Int(newCredentials.expiresIn.timeIntervalSinceNow)
                                let error = CredentialsManagerError(code: .largeMinTTL(minTTL: minTTL, lifetime: tokenTTL))
                                dispatchGroup.leave()
                                callback(.failure(error))
                            } else if !self.store(credentials: newCredentials) {
                                dispatchGroup.leave()
                                callback(.failure(CredentialsManagerError(code: .storeFailed)))
                            } else {
                                dispatchGroup.leave()
                                callback(.success(newCredentials))
                            }
                        case .failure(let error):
                            dispatchGroup.leave()
                            callback(.failure(CredentialsManagerError(code: .renewFailed, cause: error)))
                        }
                    }
            }

            dispatchGroup.wait()
        }
    }

    // swiftlint:disable:next function_body_length function_parameter_count
    private func retrieveAPICredentials(audience: String,
                                        scope: String?,
                                        minTTL: Int,
                                        parameters: [String: Any],
                                        headers: [String: String],
                                        callback: @escaping (CredentialsManagerResult<APICredentials>) -> Void) {
        let dispatchGroup = DispatchGroup()

        self.dispatchQueue.async {
            dispatchGroup.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                if let apiCredentials = self.retrieveAPICredentials(audience: audience),
                      !self.hasExpired(apiCredentials.expiresIn),
                      !self.willExpire(apiCredentials.expiresIn, within: minTTL),
                      !self.hasScopeChanged(from: apiCredentials.scope, to: scope) {
                    dispatchGroup.leave()
                    return callback(.success(apiCredentials))
                }
                guard let currentCredentials = self.retrieveCredentials() else {
                    dispatchGroup.leave()
                    return callback(.failure(.noCredentials))
                }
                guard let refreshToken = currentCredentials.refreshToken else {
                    dispatchGroup.leave()
                    return callback(.failure(.noRefreshToken))
                }

                self.authentication
                    .renew(withRefreshToken: refreshToken, audience: audience, scope: scope)
                    .parameters(parameters)
                    .headers(headers)
                    .start { result in
                        switch result {
                        case .success(let credentials):
                            let newCredentials = Credentials(from: currentCredentials,
                                                             idToken: credentials.idToken,
                                                             refreshToken: credentials.refreshToken ?? refreshToken)
                            let newAPICredentials = APICredentials(from: credentials)
                            if self.willExpire(newAPICredentials.expiresIn, within: minTTL) {
                                let tokenTTL = Int(newAPICredentials.expiresIn.timeIntervalSinceNow)
                                let error = CredentialsManagerError(code: .largeMinTTL(minTTL: minTTL, lifetime: tokenTTL))
                                dispatchGroup.leave()
                                callback(.failure(error))
                            } else if !self.store(credentials: newCredentials) {
                                dispatchGroup.leave()
                                callback(.failure(CredentialsManagerError(code: .storeFailed)))
                            } else if !self.store(apiCredentials: newAPICredentials, forAudience: audience) {
                                dispatchGroup.leave()
                                callback(.failure(CredentialsManagerError(code: .storeFailed)))
                            } else {
                                dispatchGroup.leave()
                                callback(.success(newAPICredentials))
                            }
                        case .failure(let error):
                            dispatchGroup.leave()
                            callback(.failure(CredentialsManagerError(code: .apiExchangeFailed, cause: error)))
                        }
                    }
            }

            dispatchGroup.wait()
        }
    }

    func willExpire(_ expiresIn: Date, within ttl: Int) -> Bool {
        return expiresIn < Date(timeIntervalSinceNow: TimeInterval(ttl))
    }

    func hasExpired(_ expiresIn: Date) -> Bool {
        return expiresIn < Date()
    }

    func hasScopeChanged(from lastScope: String?, to newScope: String?) -> Bool {
        if let lastScope = lastScope, let newScope = newScope {
            let lastScopeList = lastScope.lowercased().split(separator: " ").sorted()
            let newScopeList = newScope.lowercased().split(separator: " ").sorted()

            return lastScopeList != newScopeList
        }

        return false
    }

}

// MARK: - Combine

public extension CredentialsManager {

    /// Calls the `/oauth/revoke` endpoint to revoke the refresh token and then clears the credentials if the request
    /// was successful. Otherwise, the credentials are not cleared and the subscription completes with an error.
    ///
    /// ## Usage
    ///
    /// ```swift
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
    /// You can specify custom headers for the refresh token revocation:
    ///
    /// ```swift
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
    ///
    /// ## See Also
    ///
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/revoke-refresh-token/revoke-refresh-token)
    func revoke(headers: [String: String] = [:]) -> AnyPublisher<Void, CredentialsManagerError> {
        return Deferred {
            Future { callback in
                return self.revoke(headers: headers, callback)
            }
        }.eraseToAnyPublisher()
    }

    /// Retrieves credentials from the Keychain and automatically renews them using the refresh token if the access
    /// token is expired. Otherwise, the subscription will complete with the retrieved credentials as they are still
    /// valid. Renewed credentials will be stored in the Keychain. **This method is thread-safe**.
    ///
    /// ## Usage
    ///
    /// ```swift
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
    /// To avoid retrieving access tokens with too little time left, enforce a minimum TTL (in seconds):
    ///
    /// ```swift
    /// credentialsManager
    ///     .credentials(minTTL: 60)
    ///     .sink(receiveCompletion: { print($0) },
    ///           receiveValue: { print($0) })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// You can specify custom parameters or headers for the renewal request:
    ///
    /// ```swift
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
    /// ```swift
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
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If
    /// the credentials are expired and there is no refresh token, the subscription will complete with a
    /// ``CredentialsManagerError/noRefreshToken`` error.
    /// - Warning: Do not call `store(credentials:)` afterward. The Credentials Manager automatically persists the
    /// renewed credentials. Since this method is thread-safe and ``store(credentials:)`` is not, calling it anyway can
    /// cause concurrency issues.
    /// - Important: To ensure that no concurrent renewal requests get made, do not call this method from multiple
    /// Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.
    ///
    /// ## See Also
    ///
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/refresh-token/refresh-token)
    /// - <doc:RefreshTokens>
    func credentials(withScope scope: String? = nil,
                     minTTL: Int = 0,
                     parameters: [String: Any] = [:],
                     headers: [String: String] = [:]) -> AnyPublisher<Credentials, CredentialsManagerError> {
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

    /// Retrieves API credentials from the Keychain and automatically renews them using the refresh token if the access
    /// token is expired. Otherwise, the subscription will complete with the retrieved API credentials as they are
    /// still valid.
    ///
    /// If there are no stored API credentials, the refresh token will be exchaged for a new set of API credentials.
    /// New or renewed API credentials will be automatically stored in the Keychain. **This method is thread-safe**.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// credentialsManager
    ///     .apiCredentials(forAudience: "http://example.com/api")
    ///     .sink(receiveCompletion: { completion in
    ///         if case .failure(let error) = completion {
    ///             print("Failed with: \(error)")
    ///         }
    ///     }, receiveValue: { apiCredentials in
    ///         print("Obtained API credentials: \(apiCredentials)")
    ///     })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// The default scopes configured for the API will be granted if you don't request any specific scopes. If you
    /// request different scopes than the ones that were granted last time, the API credentials will be renewed
    /// immediately, regardless of whether they are expired or not.
    ///
    /// ```swift
    /// credentialsManager
    ///     .apiCredentials(forAudience: "http://example.com/api",
    ///                     scopes: "read:todos update:todos")
    ///     .sink(receiveCompletion: { print($0) },
    ///           receiveValue: { print($0) })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// To avoid retrieving access tokens with too little time left, enforce a minimum TTL (in seconds):
    ///
    /// ```swift
    /// credentialsManager
    ///     .apiCredentials(forAudience: "http://example.com/api",
    ///                     minTTL: 60)
    ///     .sink(receiveCompletion: { print($0) },
    ///           receiveValue: { print($0) })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// You can specify custom parameters or headers for the exchange request:
    ///
    /// ```swift
    /// credentialsManager
    ///     .apiCredentials(forAudience: "http://example.com/api",
    ///                     parameters: ["key": "value"],
    ///                     headers: ["key": "value"])
    ///     .sink(receiveCompletion: { print($0) },
    ///           receiveValue: { print($0) })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// - Parameters:
    ///   - audience:   Identifier of the API that your application is requesting access to.
    ///   - scope:      Space-separated list of scope values to request when exchanging a refresh token for API credentials. Defaults to `nil`, which will ask for the default scopes configured for the API.
    ///   - minTTL:     Minimum time in seconds the access token must remain valid to avoid being renewed. Defaults to `0`.
    ///   - parameters: Additional parameters to use when exchanging a refresh token for API credentials.
    ///   - headers:    Additional headers to use when exchanging a refresh token for API credentials.
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If
    /// the API credentials are expired and there is no refresh token, the callback will be called with a
    /// ``CredentialsManagerError/noRefreshToken`` error.
    /// - Important: To ensure that no concurrent exchange requests get made, do not call this method from multiple
    /// Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.
    ///
    /// ## See Also
    ///
    /// - [Scopes](https://auth0.com/docs/get-started/apis/scopes)
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/refresh-token/refresh-token)
    /// - <doc:RefreshTokens>
    func apiCredentials(forAudience audience: String,
                        scope: String? = nil,
                        minTTL: Int = 0,
                        parameters: [String: Any] = [:],
                        headers: [String: String] = [:]) -> AnyPublisher<APICredentials, CredentialsManagerError> {
        return Deferred {
            Future { callback in
                return self.apiCredentials(forAudience: audience,
                                           scope: scope,
                                           minTTL: minTTL,
                                           parameters: parameters,
                                           headers: headers,
                                           callback: callback)
            }
        }.eraseToAnyPublisher()
    }

    /// Renews credentials using the refresh token and stores them in the Keychain. **This method is thread-safe**.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// credentialsManager
    ///     .renew()
    ///     .sink(receiveCompletion: { completion in
    ///         if case .failure(let error) = completion {
    ///             print("Failed with: \(error)")
    ///         }
    ///     }, receiveValue: { credentials in
    ///         print("Renewed credentials: \(credentials)")
    ///     })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// You can specify custom parameters or headers for the renewal request:
    ///
    /// ```swift
    /// credentialsManager
    ///     .renew(parameters: ["key": "value"],
    ///            headers: ["key": "value"])
    ///     .sink(receiveCompletion: { print($0) },
    ///           receiveValue: { print($0) })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// - Parameters:
    ///   - parameters: Additional parameters to use.
    ///   - headers:    Additional headers to use.
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If
    /// there is no refresh token, the subscription will complete with a ``CredentialsManagerError/noRefreshToken``
    /// error.
    /// - Warning: Do not call `store(credentials:)` afterward. The Credentials Manager automatically persists the
    /// renewed credentials. Since this method is thread-safe and ``store(credentials:)`` is not, calling it anyway can
    /// cause concurrency issues.
    /// - Important: To ensure that no concurrent renewal requests get made, do not call this method from multiple
    /// Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.
    ///
    /// ## See Also
    ///
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/refresh-token/refresh-token)
    /// - <doc:RefreshTokens>
    func renew(parameters: [String: Any] = [:],
               headers: [String: String] = [:]) -> AnyPublisher<Credentials, CredentialsManagerError> {
        return Deferred {
            Future { callback in
                return self.renew(parameters: parameters,
                                  headers: headers,
                                  callback: callback)
            }
        }.eraseToAnyPublisher()
    }

}

// MARK: - Async/Await

#if canImport(_Concurrency)
public extension CredentialsManager {

    /// Calls the `/oauth/revoke` endpoint to revoke the refresh token and then clears the credentials if the request
    /// was successful. Otherwise, the credentials are not cleared and an error is thrown.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// do {
    ///     try await credentialsManager.revoke()
    ///     print("Revoked refresh token and cleared credentials")
    /// } catch {
    ///     print("Failed with: \(error)")
    /// }
    /// ```
    ///
    /// You can specify custom headers for the refresh token revocation:
    ///
    /// ```swift
    /// try await credentialsManager.revoke(headers: ["key": "value"])
    /// ```
    ///
    /// If no refresh token is available the endpoint is not called, the credentials are cleared, and no error is thrown.
    ///
    /// - Parameter headers: Additional headers to use when revoking the refresh token.
    /// - Throws: An error of type ``CredentialsManagerError``.
    ///
    /// ## See Also
    ///
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/revoke-refresh-token/revoke-refresh-token)
    func revoke(headers: [String: String] = [:]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.revoke(headers: headers) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Retrieves credentials from the Keychain and automatically renews them using the refresh token if the access
    /// token is expired. Otherwise, it returns the retrieved credentials as they are still valid. Renewed credentials
    /// will be stored in the Keychain. **This method is thread-safe**.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// do {
    ///     let credentials = try await credentialsManager.credentials()
    ///     print("Obtained credentials: \(credentials)")
    /// } catch {
    ///     print("Failed with: \(error)")
    /// }
    /// ```
    ///
    /// To avoid retrieving access tokens with too little time left, enforce a minimum TTL (in seconds):
    ///
    /// ```swift
    /// let credentials = try await credentialsManager.credentials(minTTL: 60)
    /// ```
    ///
    /// You can specify custom parameters or headers for the renewal request:
    ///
    /// ```swift
    /// let credentials = try await credentialsManager.credentials(parameters: ["key": "value"],
    ///                                                            headers: ["key": "value"])
    /// ```
    ///
    /// When renewing credentials you can get a downscoped access token by requesting fewer scopes than were requested
    /// on login. If you specify fewer scopes, the credentials will be renewed immediately, regardless of whether they
    /// are expired or not.
    ///
    /// ```swift
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
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If
    /// the credentials are expired and there is no refresh token, a ``CredentialsManagerError/noRefreshToken`` error
    /// will be thrown.
    /// - Warning: Do not call `store(credentials:)` afterward. The Credentials Manager automatically persists the
    /// renewed credentials. Since this method is thread-safe and ``store(credentials:)`` is not, calling it anyway can
    /// cause concurrency issues.
    /// - Important: To ensure that no concurrent renewal requests get made, do not call this method from multiple
    /// Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.
    ///
    /// ## See Also
    ///
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/refresh-token/refresh-token)
    /// - <doc:RefreshTokens>
    func credentials(withScope scope: String? = nil,
                     minTTL: Int = 0,
                     parameters: [String: Any] = [:],
                     headers: [String: String] = [:]) async throws -> Credentials {
        return try await withCheckedThrowingContinuation { continuation in
            self.credentials(withScope: scope,
                             minTTL: minTTL,
                             parameters: parameters,
                             headers: headers) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Retrieves API credentials from the Keychain and automatically renews them using the refresh token if the access
    /// token is expired. Otherwise, it returns the retrieved API credentials as they are still valid.
    ///
    /// If there are no stored API credentials, the refresh token will be exchaged for a new set of API credentials.
    /// New or renewed API credentials will be automatically stored in the Keychain. **This method is thread-safe**.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// do {
    ///     let apiCredentials = try await credentialsManager.apiCredentials(forAudience: "http://example.com/api")
    ///     print("Obtained API credentials: \(apiCredentials)")
    /// } catch {
    ///     print("Failed with: \(error)")
    /// }
    /// ```
    ///
    /// The default scopes configured for the API will be granted if you don't request any specific scopes. If you
    /// request different scopes than the ones that were granted last time, the API credentials will be renewed
    /// immediately, regardless of whether they are expired or not.
    ///
    /// ```swift
    /// let apiCredentials = try await credentialsManager.apiCredentials(forAudience: "http://example.com/api",
    ///                                                                  scope: "read:todos update:todos")
    /// ```
    ///
    /// To avoid retrieving access tokens with too little time left, enforce a minimum TTL (in seconds):
    ///
    /// ```swift
    /// let apiCredentials = try await credentialsManager.apiCredentials(forAudience: "http://example.com/api",
    ///                                                                  minTTL: 60)
    /// ```
    ///
    /// You can specify custom parameters or headers for the exchange request:
    ///
    /// ```swift
    /// let apiCredentials = try await credentialsManager.apiCredentials(forAudience: "http://example.com/api",
    ///                                                                  parameters: ["key": "value"],
    ///                                                                  headers: ["key": "value"])
    /// ```
    ///
    /// - Parameters:
    ///   - audience:   Identifier of the API that your application is requesting access to.
    ///   - scope:      Space-separated list of scope values to request when exchanging a refresh token for API credentials. Defaults to `nil`, which will ask for the default scopes configured for the API.
    ///   - minTTL:     Minimum time in seconds the access token must remain valid to avoid being renewed. Defaults to `0`.
    ///   - parameters: Additional parameters to use when exchanging a refresh token for API credentials.
    ///   - headers:    Additional headers to use when exchanging a refresh token for API credentials.
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If
    /// the API credentials are expired and there is no refresh token, the callback will be called with a
    /// ``CredentialsManagerError/noRefreshToken`` error.
    /// - Important: To ensure that no concurrent exchange requests get made, do not call this method from multiple
    /// Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.
    ///
    /// ## See Also
    ///
    /// - [Scopes](https://auth0.com/docs/get-started/apis/scopes)
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/refresh-token/refresh-token)
    /// - <doc:RefreshTokens>
    func apiCredentials(forAudience audience: String,
                        scope: String? = nil,
                        minTTL: Int = 0,
                        parameters: [String: Any] = [:],
                        headers: [String: String] = [:]) async throws -> APICredentials {
        return try await withCheckedThrowingContinuation { continuation in
            self.apiCredentials(forAudience: audience,
                                scope: scope,
                                minTTL: minTTL,
                                parameters: parameters,
                                headers: headers,
                                callback: continuation.resume)
        }
    }

    /// Renews credentials using the refresh token and stores them in the Keychain. **This method is thread-safe**.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// do {
    ///     let credentials = try await credentialsManager.renew()
    ///     print("Renewed credentials: \(credentials)")
    /// } catch {
    ///     print("Failed with: \(error)")
    /// }
    /// ```
    ///
    /// You can specify custom parameters or headers for the renewal request:
    ///
    /// ```swift
    /// let credentials = try await credentialsManager.renew(parameters: ["key": "value"],
    ///                                                      headers: ["key": "value"])
    /// ```
    ///
    /// - Parameters:
    ///   - parameters: Additional parameters to use.
    ///   - headers:    Additional headers to use.
    ///   - callback:   Callback that receives a `Result` containing either the renewed user's credentials or an error.
    /// - Requires: The scope `offline_access` to have been requested on login to get a refresh token from Auth0. If
    /// there is no refresh token, a ``CredentialsManagerError/noRefreshToken`` error will be thrown.
    /// - Warning: Do not call `store(credentials:)` afterward. The Credentials Manager automatically persists the
    /// renewed credentials. Since this method is thread-safe and ``store(credentials:)`` is not, calling it anyway can
    /// cause concurrency issues.
    /// - Important: To ensure that no concurrent renewal requests get made, do not call this method from multiple
    /// Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.
    ///
    /// ## See Also
    ///
    /// - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/refresh-token/refresh-token)
    /// - <doc:RefreshTokens>
    func renew(parameters: [String: Any] = [:],
               headers: [String: String] = [:]) async throws -> Credentials {
        return try await withCheckedThrowingContinuation { continuation in
            self.renew(parameters: parameters, headers: headers) { result in
                continuation.resume(with: result)
            }
        }
    }

}
#endif
