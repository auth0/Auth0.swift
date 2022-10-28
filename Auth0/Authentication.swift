// swiftlint:disable file_length
// swiftlint:disable function_parameter_count

import Foundation

/// A newly created database user (just the email, username, and email verified flag).
public typealias DatabaseUser = (email: String, username: String?, verified: Bool)

/**
 Client for the [Auth0 Authentication API](https://auth0.com/docs/api/authentication).

 ## See Also

 - ``AuthenticationError``
 - [Standard Error Responses](https://auth0.com/docs/api/authentication#standard-error-responses)
 */
public protocol Authentication: Trackable, Loggable {

    /// The Auth0 Client ID.
    var clientId: String { get }
    /// The Auth0 Domain URL.
    var url: URL { get }

    // MARK: - Methods

    /**
     Logs in a user using an email and an OTP code received via email. This is the last part of the passwordless login
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

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#authenticate-user)
     - [Error Responses](https://auth0.com/docs/api/authentication#post-passwordless-verify)
     */
    func login(email: String, code: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Logs in a user using a phone number and an OTP code received via SMS. This is the last part of the passwordless login flow.

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

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#authenticate-user)
     - [Error Responses](https://auth0.com/docs/api/authentication#post-passwordless-verify)
     */
    func login(phoneNumber: String, code: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Logs in a user using a username and password with a realm or connection.

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
       - usernameOrEmail:   Username or email of the user.
       - password:          Password of the user.
       - realmOrConnection: Domain of the realm or connection name.
       - audience:          API Identifier that your application is requesting access to.
       - scope:             Space-separated list of requested scope values.
     - Returns: Request that will yield Auth0 user's credentials.
     - Requires: The `http://auth0.com/oauth/grant-type/password-realm` grant. Check
     [our documentation](https://auth0.com/docs/get-started/applications/application-grant-types) for more information.
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

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#verify-with-one-time-password-otp-)
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
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#verify-with-out-of-band-oob-)
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
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#verify-with-recovery-code)
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
    /// - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#challenge-request)
    func multifactorChallenge(mfaToken: String, types: [String]?, authenticatorId: String?) -> Request<Challenge, AuthenticationError>

    /**
     Authenticates a user with their Sign In with Apple authorization code.

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

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#token-exchange-for-native-social)
     */
    func login(appleAuthorizationCode authorizationCode: String, fullName: PersonNameComponents?, profile: [String: Any]?, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Authenticates a user with their Facebook [session info access token](https://developers.facebook.com/docs/facebook-login/access-tokens/session-info-access-token/) and profile data.

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

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#token-exchange-for-native-social)
     */
    func login(facebookSessionAccessToken sessionAccessToken: String, profile: [String: Any], audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Logs in a user using a username and password in the default directory.

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
       - scope:    Space-separated list of requested scope values.
     - Returns: A request that will yield Auth0 user's credentials.
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
       - connection:     Name of the connection where the user will be created (database connection).
       - userMetadata:   Additional user metadata parameters that will be added to the newly created user.
       - rootAttributes: Root attributes that will be added to the newly created user. These will not overwrite existing parameters. See https://auth0.com/docs/api/authentication#signup for the full list of supported attributes.
     - Returns: A request that will yield a newly created database user (just the email, username, and email verified flag).

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#signup)
     */
    func signup(email: String, username: String?, password: String, connection: String, userMetadata: [String: Any]?, rootAttributes: [String: Any]?) -> Request<DatabaseUser, AuthenticationError>

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

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#change-password)
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

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#get-code-or-link)
     - [Error Responses](https://auth0.com/docs/api/authentication#post-passwordless-start)
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

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#get-code-or-link)
     - [Error Responses](https://auth0.com/docs/api/authentication#post-passwordless-start)
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

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#get-user-info)
     */
    func userInfo(withAccessToken accessToken: String) -> Request<UserInfo, AuthenticationError>

    /**
     Performs the last step of Proof Key for Code Exchange (PKCE).
     This will request the user's tokens using the code and its verifier after a request to `/oauth/authorize`.

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

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#authorization-code-flow-with-pkce45)
     - [RFC 7636](https://tools.ietf.org/html/rfc7636)
     */
    func codeExchange(withCode code: String, codeVerifier: String, redirectURI: String) -> Request<Credentials, AuthenticationError>

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

     You can get a downscoped access token by requesting fewer scopes than were originally requested on login:

     ```swift
     Auth0
         .authentication()
         .renew(withRefreshToken: credentials.refreshToken,
                scope: "openid offline_access")
         .start { print($0) }
     ```

     - Parameters:
       - refreshToken: The refresh token.
       - scope:        Space-separated list of scope values to request. Defaults to `nil`, which will ask for the same scopes that were originally requested on login.
     - Returns: A request that will yield Auth0 user's credentials.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#refresh-token)
     */
    func renew(withRefreshToken refreshToken: String, scope: String?) -> Request<Credentials, AuthenticationError>

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

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#revoke-refresh-token)
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

    func startPasswordless(email: String, type: PasswordlessType = .code, connection: String = "email") -> Request<Void, AuthenticationError> {
        return self.startPasswordless(email: email, type: type, connection: connection)
    }

    func startPasswordless(phoneNumber: String, type: PasswordlessType = .code, connection: String = "sms") -> Request<Void, AuthenticationError> {
        return self.startPasswordless(phoneNumber: phoneNumber, type: type, connection: connection)
    }

    func renew(withRefreshToken refreshToken: String, scope: String? = nil) -> Request<Credentials, AuthenticationError> {
        return self.renew(withRefreshToken: refreshToken, scope: scope)
    }

}
