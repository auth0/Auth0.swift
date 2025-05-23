// swiftlint:disable file_length
// swiftlint:disable function_parameter_count

import Foundation

/// A newly created database user (just the email, username, and email verified flag).
public typealias DatabaseUser = (email: String, username: String?, verified: Bool)

/**
 Client for the [Auth0 Authentication API](https://auth0.com/docs/api/authentication).

 ## See Also

 - ``AuthenticationError``
 */
public protocol Authentication: Trackable, Loggable {

    /// The Auth0 Client ID.
    var clientId: String { get }
    /// The Auth0 Domain URL.
    var url: URL { get }

    // MARK: - Methods

    /**
     Logs a user in using an email and an OTP code received via email. This is the last part of the passwordless login
     flow.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .login(email: "support@auth0.com", code: "123456")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     You can also specify audience (the Auth0 API identifier) and scope values:

     ```swift
     Auth0
         .authentication()
         .login(email: "support@auth0.com",
                code: "123456",
                audience: "https://example.com/api",
                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     - Parameters:
       - email:    Email the user used to start the passwordless login flow.
       - code:     One-time password (OTP) code the user received via email.
       - audience: API Identifier that your application is requesting access to. Defaults to `nil`.
       - scope:    Space-separated list of requested scope values. Defaults to `openid profile email`.
     - Returns: Request that will yield Auth0 user's credentials.
     - Requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check
     [our documentation](https://auth0.com/docs/get-started/applications/application-grant-types) for more information.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/passwordless/authenticate-user)
     */
    func login(email: String, code: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Logs a user in using a phone number and an OTP code received via SMS. This is the last part of the passwordless login flow.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .login(phoneNumber: "+12025550135", code: "123456")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     You can also specify audience (the Auth0 API identifier) and scope values:

     ```swift
     Auth0
         .authentication()
         .login(phoneNumber: "+12025550135",
                code: "123456",
                audience: "https://example.com/api",
                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     - Parameters:
       - phoneNumber: Phone number the user used to start the passwordless login flow.
       - code:        One-time password (OTP) code the user received via SMS.
       - audience:    API Identifier that your application is requesting access to. Defaults to `nil`.
       - scope:       Space-separated list of requested scope values. Defaults to `openid profile email`.
     - Returns: Request that will yield Auth0 user's credentials.
     - Requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check
     [our documentation](https://auth0.com/docs/get-started/applications/application-grant-types) for more information.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/passwordless/authenticate-user)
     */
    func login(phoneNumber: String, code: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Logs a user in using a username and password with a realm or connection.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .login(usernameOrEmail: "support@auth0.com",
                password: "secret-password",
                realmOrConnection: "MyDatabase")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     You can also specify audience (the Auth0 API identifier) and scope values:

     ```swift
     Auth0
         .authentication()
         .login(usernameOrEmail: "support@auth0.com",
                password: "secret-password",
                realmOrConnection: "MyDatabase",
                audience: "https://example.com/api",
                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     - Parameters:
       - username: Username or email of the user.
       - password: Password of the user.
       - realm:    Domain of the realm or connection name.
       - audience: API Identifier that your application is requesting access to.
       - scope:    Space-separated list of requested scope values.
     - Returns: Request that will yield Auth0 user's credentials.
     - Requires: The `http://auth0.com/oauth/grant-type/password-realm` grant. Check
     [our documentation](https://auth0.com/docs/get-started/applications/application-grant-types) for more information.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/resource-owner-password-flow/get-token)
     */
    func login(usernameOrEmail username: String, password: String, realmOrConnection realm: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Verifies multi-factor authentication (MFA) using a one-time password (OTP).

     ## Usage

     ```swift
     Auth0
         .authentication()
         .login(withOTP: "123456", mfaToken: "mfa-token")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     - Parameters:
       - otp:      One-time password supplied by a MFA authenticator.
       - mfaToken: Token returned when authentication fails with an ``AuthenticationError/isMultifactorRequired`` error due to MFA requirement.
     - Returns: A request that will yield Auth0 user's credentials.
     - Requires: The `http://auth0.com/oauth/grant-type/mfa-otp` grant. Check
     [our documentation](https://auth0.com/docs/get-started/applications/application-grant-types) for more information.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/muti-factor-authentication/verify-mfa-with-otp)
     */
    func login(withOTP otp: String, mfaToken: String) -> Request<Credentials, AuthenticationError>

    /// Verifies multi-factor authentication (MFA) using an out-of-band (OOB) challenge (either push notification, SMS
    /// or voice).
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .authentication()
    ///     .login(withOOBCode: "123456", mfaToken: "mfa-token")
    ///     .start { result in
    ///         switch result {
    ///         case .success(let credentials):
    ///             print("Obtained credentials: \(credentials)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - oobCode:     The OOB code received from the challenge request.
    ///   - mfaToken:    Token returned when authentication fails with an ``AuthenticationError/isMultifactorRequired`` error due to MFA requirement.
    ///   - bindingCode: A code used to bind the side channel (used to deliver the challenge) with the main channel you are using to authenticate. This is usually an OTP-like code delivered as part of the challenge message.
    /// - Returns: A request that will yield Auth0 user's credentials.
    /// - Requires: The `http://auth0.com/oauth/grant-type/mfa-oob` grant. Check
    /// [our documentation](https://auth0.com/docs/get-started/applications/application-grant-types) for more information.
    ///
    /// ## See Also
    ///
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/muti-factor-authentication/verify-with-out-of-band)
    func login(withOOBCode oobCode: String, mfaToken: String, bindingCode: String?) -> Request<Credentials, AuthenticationError>

    /// Verifies multi-factor authentication (MFA) using a recovery code.
    /// Some multi-factor authentication (MFA) providers support using a recovery code to login. Use this method to
    /// authenticate when the user's enrolled device is unavailable, or the user cannot receive the challenge or accept
    /// it due to connectivity issues.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .authentication()
    ///     .login(withRecoveryCode: "recovery-code", mfaToken: "mfa-token")
    ///     .start { result in
    ///         switch result {
    ///         case .success(let credentials):
    ///             print("Obtained credentials: \(credentials)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - recoveryCode: Recovery code provided by the user.
    ///   - mfaToken:     Token returned when authentication fails with an ``AuthenticationError/isMultifactorRequired`` error due to MFA requirement.
    /// - Returns: A request that will yield Auth0 user's credentials. Might include a **recovery code**, which the
    /// application must display to the user to be stored securely for future use.
    /// - Requires: The `http://auth0.com/oauth/grant-type/mfa-recovery-code` grant. Check
    /// [our documentation](https://auth0.com/docs/get-started/applications/application-grant-types) for more information.
    ///
    /// ## See Also
    ///
    /// - ``Credentials/recoveryCode``
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/muti-factor-authentication/verify-with-recovery-code)
    func login(withRecoveryCode recoveryCode: String, mfaToken: String) -> Request<Credentials, AuthenticationError>

    /// Requests a challenge for multi-factor authentication (MFA) based on the challenge types supported by the
    /// application and user.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .authentication()
    ///     .multifactorChallenge(mfaToken: "mfa-token", types: ["otp"])
    ///     .start { result in
    ///         switch result {
    ///         case .success(let challenge):
    ///             print("Obtained challenge: \(challenge)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// The challenge type is how the user will get the challenge and prove possession. Supported challenge types include:
    /// * `otp`:  for one-time password (OTP)
    /// * `oob`:  for SMS/voice messages or out-of-band (OOB)
    ///
    /// - Parameters:
    ///   - mfaToken:        Token returned when authentication fails with an ``AuthenticationError/isMultifactorRequired`` error due to MFA requirement.
    ///   - types:           A list of the challenges types accepted by your application. Accepted challenge types are `oob` or `otp`. Excluding this parameter means that your application accepts all supported challenge types.
    ///   - authenticatorId: The ID of the authenticator to challenge. You can get the ID by querying the list of available authenticators for the user.
    /// - Returns: A request that will yield a multi-factor challenge.
    ///
    /// ## See Also
    ///
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/muti-factor-authentication/request-mfa-challenge)
    func multifactorChallenge(mfaToken: String, types: [String]?, authenticatorId: String?) -> Request<Challenge, AuthenticationError>

    /**
     Logs a user in with their Sign In with Apple authorization code.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .login(appleAuthorizationCode: "auth-code")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     You can also specify audience (the Auth0 API identifier) and scope values:

     ```swift
     Auth0
         .authentication()
         .login(appleAuthorizationCode: "auth-code",
                fullName: credentials.fullName,
                audience: "https://example.com/api",
                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     - Parameters:
       - authorizationCode: Authorization Code retrieved from Apple Authorization.
       - fullName:          The full name property returned with the Apple ID Credentials.
       - profile:           Additional user profile data returned with the Apple ID Credentials.
       - audience:          API Identifier that your application is requesting access to.   
       - scope:             Space-separated list of requested scope values. Defaults to `openid profile email`.
     - Returns: A request that will yield Auth0 user's credentials.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/token-exchange-for-native-social/token-exchange-native-social)
     */
    func login(appleAuthorizationCode authorizationCode: String, fullName: PersonNameComponents?, profile: [String: Any]?, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Logs a user in with their Facebook [session info access token](https://developers.facebook.com/docs/facebook-login/access-tokens/session-info-access-token/) and profile data.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .login(facebookSessionAccessToken: "session-info-access-token",
                profile: ["key": "value"])
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     You can also specify audience (the Auth0 API identifier) and scope values:

     ```swift
     Auth0
         .authentication()
         .login(facebookSessionAccessToken: "session-info-access-token",
                profile: ["key": "value"],
                audience: "https://example.com/api",
                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     - Parameters:
       - sessionAccessToken: Session info access token retrieved from Facebook.
       - profile:            The user profile data retrieved from Facebook.
       - audience:           API Identifier that your application is requesting access to.
       - scope:              Space-separated list of requested scope values. Defaults to `openid profile email`.
     - Returns: A request that will yield Auth0 user's credentials.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/token-exchange-for-native-social/token-exchange-native-social)
     */
    func login(facebookSessionAccessToken sessionAccessToken: String, profile: [String: Any], audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Logs a user in using a username and password in the default directory.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .loginDefaultDirectory(withUsername: "support@auth0.com",
                                password: "secret-password")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     You can also specify audience (the Auth0 API identifier) and scope values:

     ```swift
     Auth0
         .authentication()
         .loginDefaultDirectory(withUsername: "support@auth0.com",
                                password: "secret-password",
                                audience: "https://example.com/api",
                                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     - Parameters:
       - username: Username or email of the user.
       - password: Password of the user.
       - audience: API Identifier that your application is requesting access to.
       - scope:    Space-separated list of requested scope values. Defaults to `openid profile email`.
     - Returns: A request that will yield Auth0 user's credentials.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/resource-owner-password-flow/get-token)
     */
    func loginDefaultDirectory(withUsername username: String, password: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Creates a user in a database connection.

     ## Usage
     
     ```swift
     Auth0
         .authentication()
         .signup(email: "support@auth0.com",
                 password: "secret-password",
                 connection: "Username-Password-Authentication")
         .start { result in
             switch result {
             case .success(let user):
                 print("User signed up: \(user)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     You can also add additional metadata when creating the user:

     ```swift
     Auth0
         .authentication()
         .signup(email: "support@auth0.com",
                 password: "secret-password",
                 connection: "Username-Password-Authentication",
                 userMetadata: ["first_name": "John", "last_name": "Appleseed"])
         .start { print($0) }
     ```

     If the database connection requires a username:

     ```swift
     Auth0
         .authentication()
         .signup(email: "support@auth0.com",
                 username: "support",
                 password: "secret-password",
                 connection: "Username-Password-Authentication")
         .start { print($0) }
     ```

     - Parameters:
       - email:          Email for the new user.
       - username:       Username for the new user (if the connection requires a username). Defaults to `nil`.
       - password:       Password for the new user.
       - connection:     Name of the database connection where the user will be created.
       - userMetadata:   Additional user metadata parameters that will be added to the newly created user.
       - rootAttributes: Root attributes that will be added to the newly created user. These will not overwrite existing parameters. See https://auth0.com/docs/api/authentication#signup for the full list of supported attributes.
     - Returns: A request that will yield a newly created database user (just the email, username, and email verified flag).

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/signup/create-a-new-user)
     */
    func signup(email: String, username: String?, password: String, connection: String, userMetadata: [String: Any]?, rootAttributes: [String: Any]?) -> Request<DatabaseUser, AuthenticationError>

    #if PASSKEYS_PLATFORM
    /// Logs a user in using an existing passkey credential and the login challenge. This is the last part of the passkey login flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .authentication()
    ///     .login(passkey: loginPasskey,
    ///            challenge: loginChallenge,
    ///            connection: "Username-Password-Authentication")
    ///     .start { result in
    ///         switch result {
    ///         case .success(let credentials):
    ///             print("Obtained credentials: \(credentials)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// You can also specify audience (the Auth0 API identifier) and scope values:
    ///
    /// ```swift
    /// Auth0
    ///     .authentication()
    ///     .login(passkey: loginPasskey,
    ///            challenge: loginChallenge,
    ///            connection: "Username-Password-Authentication",
    ///            audience: "https://example.com/api",
    ///            scope: "openid profile email offline_access")
    ///     .start { print($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - passkey:  The existing passkey credential obtained from the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate) delegate.
    ///   - challenge:  The passkey challenge obtained from ``passkeyLoginChallenge(connection:)``.
    ///   - connection: Name of the database connection. If a connection name is not specified, your tenant's default directory will be used.
    ///   - audience:   API Identifier that your application is requesting access to. Defaults to `nil`.
    ///   - scope:      Space-separated list of requested scope values. Defaults to `openid profile email`.
    /// - Returns: A request that will yield Auth0 user's credentials.
    ///
    /// ## See Also
    ///
    /// - [Authentication API Endpoint](https://auth0.com/docs/native-passkeys-api#authenticate-existing-user)
    /// - [Native Passkeys for Mobile Applications](https://auth0.com/docs/native-passkeys-for-mobile-applications)
    /// - [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Connect-to-a-service-with-an-existing-account)
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func login(passkey: LoginPasskey,
               challenge: PasskeyLoginChallenge,
               connection: String?,
               audience: String?,
               scope: String) -> Request<Credentials, AuthenticationError>

    /// Requests a challenge for logging a user in with an existing passkey. This is the first part of the passkey login flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .authentication()
    ///     .passkeyLoginChallenge(connection: "Username-Password-Authentication")
    ///     .start { result in
    ///         switch result {
    ///         case .success(let loginChallenge):
    ///             print("Obtained login challenge: \(loginChallenge)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// Use the challenge with [`ASAuthorizationPlatformPublicKeyCredentialProvider`](https://developer.apple.com/documentation/authenticationservices/asauthorizationplatformpublickeycredentialprovider)
    /// from the `AuthenticationServices` framework to request an existing passkey credential. It will be delivered
    /// through the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate)
    /// delegate. Check out [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Connect-to-a-service-with-an-existing-account)
    /// to learn more.
    ///
    /// ```swift
    /// let credentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
    ///     relyingPartyIdentifier: loginChallenge.relyingPartyId
    /// )
    ///
    /// let request = credentialProvider.createCredentialAssertionRequest(
    ///     challenge: loginChallenge.challengeData
    /// )
    ///
    /// let authController = ASAuthorizationController(authorizationRequests: [request])
    /// authController.delegate = self // ASAuthorizationControllerDelegate
    /// authController.presentationContextProvider = self
    /// authController.performRequests()
    /// ```
    ///
    /// Then, call ``login(passkey:challenge:connection:audience:scope:)-7s3cz`` with the resulting
    /// passkey credential and the challenge to log the user in.
    ///
    /// - Parameter connection: Name of the database connection. If a connection name is not specified, your tenant's default directory will be used.
    /// - Returns: A request that will yield a passkey login challenge.
    ///
    /// ## See Also
    ///
    /// - [Authentication API Endpoint](https://auth0.com/docs/native-passkeys-api#request-login-challenge)
    /// - [Native Passkeys for Mobile Applications](https://auth0.com/docs/native-passkeys-for-mobile-applications)
    /// - [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Connect-to-a-service-with-an-existing-account)
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyLoginChallenge(connection: String?) -> Request<PasskeyLoginChallenge, AuthenticationError>

    /// Logs a new user in using a signup passkey credential and the signup challenge. This is the last part of the passkey signup flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .authentication()
    ///     .login(passkey: signupPasskey,
    ///            challenge: signupChallenge,
    ///            connection: "Username-Password-Authentication")
    ///     .start { result in
    ///         switch result {
    ///         case .success(let credentials):
    ///             print("Obtained credentials: \(credentials)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// You can also specify audience (the Auth0 API identifier) and scope values:
    ///
    /// ```swift
    /// Auth0
    ///     .authentication()
    ///     .login(passkey: signupPasskey,
    ///            challenge: signupChallenge,
    ///            connection: "Username-Password-Authentication",
    ///            audience: "https://example.com/api",
    ///            scope: "openid profile email offline_access")
    ///     .start { print($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - passkey: The signup passkey credential obtained from the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate) delegate.
    ///   - challenge:   The passkey signup challenge obtained from ``passkeySignupChallenge(email:phoneNumber:username:name:connection:)``.
    ///   - connection:  Name of the database connection where the user will be created. If a connection name is not specified, your tenant's default directory will be used.
    ///   - audience:    API Identifier that your application is requesting access to. Defaults to `nil`.
    ///   - scope:       Space-separated list of requested scope values. Defaults to `openid profile email`.
    /// - Returns: A request that will yield Auth0 user's credentials.
    ///
    /// ## See Also
    /// 
    /// - [Authentication API Endpoint](https://auth0.com/docs/native-passkeys-api#authenticate-new-user)
    /// - [Native Passkeys for Mobile Applications](https://auth0.com/docs/native-passkeys-for-mobile-applications)
    /// - [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Register-a-new-account-on-a-service)
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func login(passkey: SignupPasskey,
               challenge: PasskeySignupChallenge,
               connection: String?,
               audience: String?,
               scope: String) -> Request<Credentials, AuthenticationError>

    /// Requests a challenge for registering a new user with a passkey. This is the first part of the passkey signup flow.
    ///
    /// You need to provide at least one user identifier when requesting the challenge, along with an optional user
    /// display name, and an optional database connection name. If a connection name is not specified, your tenant's
    /// default directory will be used.
    ///
    /// By default, database connections require a valid `email`. If you have enabled [Flexible Identifiers](https://auth0.com/docs/authenticate/database-connections/activate-and-configure-attributes-for-flexible-identifiers)
    /// for your database connection, you may use any combination of `email`, `phoneNumber`, or `username`. These user
    /// identifiers can be required or optional and must match your Flexible Identifiers configuration.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .authentication()
    ///     .passkeySignupChallenge(email: "support@auth0.com",
    ///                             name: "John Appleseed",
    ///                             connection: "Username-Password-Authentication")
    ///     .start { result in
    ///         switch result {
    ///         case .success(let signupChallenge):
    ///             print("Obtained signup challenge: \(signupChallenge)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// Use the challenge with [`ASAuthorizationPlatformPublicKeyCredentialProvider`](https://developer.apple.com/documentation/authenticationservices/asauthorizationplatformpublickeycredentialprovider)
    /// from the `AuthenticationServices` framework to generate a new passkey credential. It will be delivered through the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate)
    /// delegate. Check out [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Register-a-new-account-on-a-service)
    /// to learn more.
    ///
    /// ```swift
    /// let credentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
    ///     relyingPartyIdentifier: signupChallenge.relyingPartyId
    /// )
    ///
    /// let request = credentialProvider.createCredentialRegistrationRequest(
    ///     challenge: signupChallenge.challengeData,
    ///     name: signupChallenge.userName,
    ///     userID: signupChallenge.userId
    /// )
    ///
    /// let authController = ASAuthorizationController(authorizationRequests: [request])
    /// authController.delegate = self // ASAuthorizationControllerDelegate
    /// authController.presentationContextProvider = self
    /// authController.performRequests()
    /// ```
    ///
    /// Then, call ``login(passkey:challenge:connection:audience:scope:)-4q8i0`` with the created
    /// passkey credential and the challenge to log the new user in.
    ///
    /// - Parameters:
    ///   - email:       Email address of the user. Defaults to `nil`.
    ///   - phoneNumber: Phone number of the user. Defaults to `nil`.
    ///   - username:    Username of the user. Defaults to `nil`.
    ///   - name:        Display name of the user. Defaults to `nil`.
    ///   - connection:  Name of the database connection where the user will be created. If a connection name is not specified, your tenant's default directory will be used.
    /// - Returns: A request that will yield a passkey signup challenge.
    ///
    /// ## See Also
    ///
    /// - [Authentication API Endpoint](https://auth0.com/docs/native-passkeys-api#request-signup-challenge)
    /// - [Native Passkeys for Mobile Applications](https://auth0.com/docs/native-passkeys-for-mobile-applications)
    /// - [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Register-a-new-account-on-a-service)
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeySignupChallenge(email: String?,
                                phoneNumber: String?,
                                username: String?,
                                name: String?,
                                connection: String?) -> Request<PasskeySignupChallenge, AuthenticationError>
    #endif

    /**
     Resets the password of a database user.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .resetPassword(email: "support@auth0.com",
                        connection: "Username-Password-Authentication")
         .start { print($0) }
     ```

     - Parameters:
       - email:      Email of the database user.
       - connection: Name of the database connection.
     - Returns: A request for resetting the password.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/change-password/change-password)
     */
    func resetPassword(email: String, connection: String) -> Request<Void, AuthenticationError>

    /**
     Starts passwordless authentication by sending an email with an OTP code. This is the first part of the
     passwordless login flow.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .startPasswordless(email: "support@auth0.com")
         .start { print($0) }
     ```

     If you have configured iOS Universal Links:

     ```swift
     Auth0
         .authentication()
         .startPasswordless(email: "support@auth0.com", type: .iOSLink)
         .start { print($0) }
     ```

     - Parameters:
       - email:      Email where to send the code or link.
       - type:       Type of passwordless authentication. Defaults to 'code'.
       - connection: Name of the passwordless connection. Defaults to 'email'.
     - Returns: A request for starting the passwordless flow.
     - Requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check
     [our documentation](https://auth0.com/docs/get-started/applications/application-grant-types) for more information.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/passwordless/get-code-or-link)
     */
    func startPasswordless(email: String, type: PasswordlessType, connection: String) -> Request<Void, AuthenticationError>

    /**
     Starts passwordless authentication by sending an SMS with an OTP code. This is the first part of the passwordless
     login flow.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .startPasswordless(phoneNumber: "+12025550135")
         .start { print($0) }
     ```

     If you have configured iOS Universal Links:

     ```swift
     Auth0
         .authentication()
         .startPasswordless(phoneNumber: "+12025550135", type: .iOSLink)
         .start { print($0) }
     ```

     - Parameters:
       - phoneNumber: Phone number where to send the SMS with the code or link.
       - type:        Type of passwordless authentication. Defaults to 'code'.
       - connection:  Name of the passwordless connection. Defaults to 'sms'.
     - Returns: A request for starting the passwordless flow.
     - Requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check
     [our documentation](https://auth0.com/docs/get-started/applications/application-grant-types) for more information.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/passwordless/get-code-or-link)
     */
    func startPasswordless(phoneNumber: String, type: PasswordlessType, connection: String) -> Request<Void, AuthenticationError>

    /**
     Returns OIDC standard claims information by performing a request to the `/userinfo` endpoint.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .userInfo(withAccessToken: credentials.accessToken)
         .start { result in
             switch result {
             case .success(let user):
                 print("Obtained user: \(user)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     - Parameter accessToken: Access token obtained by authenticating the user.
     - Returns: A request that will yield user information.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/user-profile/get-user-info)
     */
    func userInfo(withAccessToken accessToken: String) -> Request<UserInfo, AuthenticationError>

    /**
     Performs the last step of Proof Key for Code Exchange (PKCE).
     This will request the user's credentials using the code and its verifier after a request to `/oauth/authorize`.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .codeExchange(withCode: "code",
                       codeVerifier: "code-verifier",
                       redirectURI: "https://samples.auth0.com/callback")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     - Parameters:
       - code:         Code returned after a request to `/oauth/authorize`.
       - codeVerifier: Verifier used to generate the challenge sent in the request to `/oauth/authorize`.
       - redirectURI:  Redirect URI sent in the request to `/oauth/authorize`.
     - Returns: A request that will yield Auth0 user's credentials.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/authorization-code-flow-with-pkce/get-token-pkce)
     - [RFC 7636](https://tools.ietf.org/html/rfc7636)
     */
    func codeExchange(withCode code: String, codeVerifier: String, redirectURI: String) -> Request<Credentials, AuthenticationError>

    /**
     Exchanges a user's refresh token for a session transfer token that can be used to perform web single sign-on
     (SSO).

     ## Availability

     This feature is currently available in
     [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
     Please reach out to Auth0 support to get it enabled for your tenant.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .ssoExchange(refreshToken: credentials.refreshToken)
         .start { result in
             switch result {
             case .success(let ssoCredentials):
                 print("Obtained new SSO credentials: \(ssoCredentials)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     When opening your website on any browser or web view, add the session transfer token to the URL as a query
     parameter. Then your website can redirect the user to Auth0's `/authorize` endpoint, passing along the query
     parameter with the session transfer token. For example,
     `https://example.com/login?session_transfer_token=THE_TOKEN`.

     If you're using `WKWebView` to open your website, you can place the session transfer token inside a cookie
     instead. It will be automatically sent to the `/authorize` endpoint.

     ```swift
     let cookie = HTTPCookie(properties: [
         .domain: "YOUR_AUTH0_DOMAIN", // Or custom domain, if your website is using one
         .path: "/",
         .name: "auth0_session_transfer_token",
         .value: ssoCredentials.sessionTransferToken,
         .expires: ssoCredentials.expiresIn,
         .secure: true
     ])!

     webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
     ```

     > Important: Make sure the cookie's domain matches the Auth0 domain your *website* is using, regardless of the
     one your mobile app is using. Otherwise, the `/authorize` endpoint will not receive the cookie. If your website
     is using the provided Auth0 domain (like `example.us.auth0.com`), set the cookie's domain to this value. On the
     other hand, if your website is using a custom domain, use this value instead.

     - Parameter refreshToken: The refresh token.
     - Returns: A request that will yield SSO credentials.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#refresh-token)
     - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
     */
    func ssoExchange(withRefreshToken refreshToken: String) -> Request<SSOCredentials, AuthenticationError>

    /**
     Renews the user's credentials using a refresh token.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .renew(withRefreshToken: credentials.refreshToken)
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained new credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     You can request credentials for a specific API by passing its audience value. The default scopes configured for
     the API will be granted if you don't request any specific scopes.

     > Important: Currently, only the Auth0 My Account API is supported. Support for other APIs will be added in the future.

     ```swift
     Auth0
         .authentication()
         .renew(withRefreshToken: credentials.refreshToken,
                audience: "https://samples.us.auth0.com/me",
                scope: "create:me:authentication_methods")
         .start { print($0) }
     ```

     - Parameters:
       - refreshToken: The refresh token.
       - audience:     Identifier of the API that your application is requesting access to. Currently, only the Auth0 My Account API is supported. Defaults to `nil`.
       - scope:        Space-separated list of scope values to request. Defaults to `nil`.
     - Returns: A request that will yield Auth0 user's credentials.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/refresh-token/refresh-token)
     - [Refresh Tokens](https://auth0.com/docs/secure/tokens/refresh-tokens)
     - <doc:RefreshTokens>
     */
    func renew(withRefreshToken refreshToken: String, audience: String?, scope: String?) -> Request<Credentials, AuthenticationError>

    /**
     Revokes a user's refresh token by performing a request to the `/oauth/revoke` endpoint.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .revoke(refreshToken: credentials.refreshToken)
         .start { print($0) }
     ```

     - Parameter refreshToken: The refresh token to revoke.
     - Returns: A request for revoking the refresh token.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication/revoke-refresh-token/revoke-refresh-token)
     - [Error Responses](https://auth0.com/docs/api/authentication#post-oauth-revoke)
     */
    func revoke(refreshToken: String) -> Request<Void, AuthenticationError>

    /**
     Returns JSON Web Key Set (JWKS) information from the `/.well-known/jwks.json` endpoint.

     ## Usage

     ```swift
     Auth0
         .authentication()
         .jwks()
         .start { result in
             switch result {
             case .success(let jwks):
                 print("Obtained JWKS: \(jwks)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     - Returns: A request that will yield JWKS information.

     ## See Also

     - [JSON Web Key Sets](https://auth0.com/docs/secure/tokens/json-web-tokens/json-web-key-sets)
     */
    func jwks() -> Request<JWKS, AuthenticationError>

}

public extension Authentication {

    func login(email: String, code: String, audience: String? = nil, scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.login(email: email, code: code, audience: audience, scope: scope)
    }

    func login(phoneNumber: String, code: String, audience: String? = nil, scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.login(phoneNumber: phoneNumber, code: code, audience: audience, scope: scope)
    }

    func login(usernameOrEmail username: String, password: String, realmOrConnection realm: String, audience: String? = nil, scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.login(usernameOrEmail: username, password: password, realmOrConnection: realm, audience: audience, scope: scope)
    }

    func login(withOOBCode oobCode: String, mfaToken: String, bindingCode: String? = nil) -> Request<Credentials, AuthenticationError> {
        return self.login(withOOBCode: oobCode, mfaToken: mfaToken, bindingCode: bindingCode)
    }

    func multifactorChallenge(mfaToken: String, types: [String]? = nil, authenticatorId: String? = nil) -> Request<Challenge, AuthenticationError> {
        return self.multifactorChallenge(mfaToken: mfaToken, types: types, authenticatorId: authenticatorId)
    }

    func login(appleAuthorizationCode authorizationCode: String, fullName: PersonNameComponents? = nil, profile: [String: Any]? = nil, audience: String? = nil, scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.login(appleAuthorizationCode: authorizationCode, fullName: fullName, profile: profile, audience: audience, scope: scope)
    }

    func login(facebookSessionAccessToken sessionAccessToken: String, profile: [String: Any], audience: String? = nil, scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.login(facebookSessionAccessToken: sessionAccessToken, profile: profile, audience: audience, scope: scope)
    }

    func loginDefaultDirectory(withUsername username: String, password: String, audience: String? = nil, scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.loginDefaultDirectory(withUsername: username, password: password, audience: audience, scope: scope)
    }

    func signup(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: Any]? = nil, rootAttributes: [String: Any]? = nil) -> Request<DatabaseUser, AuthenticationError> {
        return self.signup(email: email, username: username, password: password, connection: connection, userMetadata: userMetadata, rootAttributes: rootAttributes)
    }

    #if PASSKEYS_PLATFORM
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func login(passkey: LoginPasskey,
               challenge: PasskeyLoginChallenge,
               connection: String? = nil,
               audience: String? = nil,
               scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.login(passkey: passkey,
                          challenge: challenge,
                          connection: connection,
                          audience: audience,
                          scope: scope)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyLoginChallenge(connection: String? = nil) -> Request<PasskeyLoginChallenge, AuthenticationError> {
        return self.passkeyLoginChallenge(connection: connection)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func login(passkey: SignupPasskey,
               challenge: PasskeySignupChallenge,
               connection: String? = nil,
               audience: String? = nil,
               scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.login(passkey: passkey,
                          challenge: challenge,
                          connection: connection,
                          audience: audience,
                          scope: scope)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeySignupChallenge(email: String? = nil,
                                phoneNumber: String? = nil,
                                username: String? = nil,
                                name: String? = nil,
                                connection: String? = nil) -> Request<PasskeySignupChallenge, AuthenticationError> {
        return self.passkeySignupChallenge(email: email,
                                           phoneNumber: phoneNumber,
                                           username: username,
                                           name: name,
                                           connection: connection)
    }
    #endif

    func startPasswordless(email: String, type: PasswordlessType = .code, connection: String = "email") -> Request<Void, AuthenticationError> {
        return self.startPasswordless(email: email, type: type, connection: connection)
    }

    func startPasswordless(phoneNumber: String, type: PasswordlessType = .code, connection: String = "sms") -> Request<Void, AuthenticationError> {
        return self.startPasswordless(phoneNumber: phoneNumber, type: type, connection: connection)
    }

    func renew(withRefreshToken refreshToken: String, audience: String? = nil, scope: String? = nil) -> Request<Credentials, AuthenticationError> {
        return self.renew(withRefreshToken: refreshToken, audience: audience, scope: scope)
    }

}
