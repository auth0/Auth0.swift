// swiftlint:disable file_length

import Foundation

/**
 A created database user (just email, username and email verified flag).
 */
public typealias DatabaseUser = (email: String, username: String?, verified: Bool)

/**
 Types of passwordless authentication.

 - code:        Simple OTP code sent by email or sms.
 - webLink:     Regular Web HTTP link (Web only, uses redirect).
 - iOSLink:     Universal Link.
 - androidLink: Android App Link.
 */
public enum PasswordlessType: String {
    case code = "code"
    case webLink = "link"
    case iOSLink = "link_ios"
    case androidLink = "link_android"
}

/**
 Auth endpoints of Auth0.

 - See: [Auth0 Auth API docs](https://auth0.com/docs/api/authentication)
 */
public protocol Authentication: Trackable, Loggable {
    var clientId: String { get }
    var url: URL { get }

    /**
     Logs in a user using an email and an OTP code received via email (last part of the passwordless login flow).

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(email: "support@auth0.com", code: "123456")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     You can also specify audience and scope:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(email: "support@auth0.com",
                code: "123456",
                audience: "https://myapi.com/api",
                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     When result is `.success`, its associated value will be a `Credentials` object.

     - Parameters:
       - email:    Email the user used to start the passwordless login flow.
       - code:     One time password (OTP) code the user received via email.
       - audience: API Identifier that the client is requesting access to. Default is `nil`.
       - scope:    Scope value requested when authenticating the user. Default is `openid profile email`.
     - Returns: Authentication request that will yield Auth0 user's credentials.
     - Requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
     */
    func login(email username: String, code otp: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Logs in a user using a phone number and an OTP code received via sms (last part of the passwordless login flow).

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(phoneNumber: "+4599134762367", code: "123456")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     You can also specify audience and scope:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(phoneNumber: "+4599134762367",
                code: "123456",
                audience: "https://myapi.com/api",
                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     When result is `.success`, its associated value will be a `Credentials` object.

     - Parameters:
       - phoneNumber: Phone number the user used to start the passwordless login flow.
       - code:        One time password (OTP) code the user received via sms.
       - audience:    API Identifier that the client is requesting access to. Default is `nil`.
       - scope:       Scope value requested when authenticating the user. Default is `openid profile email`.
     - Returns: Authentication request that will yield Auth0 user's credentials.
     - Requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
     */
    func login(phoneNumber username: String, code otp: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Login using username and password in a realm.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(usernameOrEmail: "support@auth0.com",
                password: "a secret password",
                realm: "mydatabase")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     You can also specify audience and scope:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(usernameOrEmail: "support@auth0.com",
                password: "a secret password",
                realm: "mydatabase",
                audience: "https://myapi.com/api",
                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     - Parameters:
       - username: Username or email used of the user to authenticate.
       - password: Password of the user.
       - realm:    Domain of the realm or connection name.
       - audience: API Identifier that the client is requesting access to.
       - scope:    Scope value requested when authenticating the user.
     - Important: This only works if you have the OAuth 2.0 API Authorization flag on.
     - Returns: Authentication request that will yield Auth0 user's credentials.
     - Requires: Grant `http://auth0.com/oauth/grant-type/password-realm`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
     */
    func login(usernameOrEmail username: String, password: String, realm: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Login using One Time Password and MFA token.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(withOTP: "123456", mfaToken: "mfa token")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     - Parameters:
       - otp:      One time password supplied by MFA Authenticator.
       - mfaToken: Token returned when authentication fails due to MFA requirement.
     - Requires: Grant `http://auth0.com/oauth/grant-type/mfa-otp`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
     */
    func login(withOTP otp: String, mfaToken: String) -> Request<Credentials, AuthenticationError>

    /// Verifies multi-factor authentication (MFA) using an out-of-band (OOB) challenge (either Push notification, SMS, or Voice).
    ///
    /// ```
    /// Auth0
    ///     .authentication(clientId: clientId, domain: "samples.auth0.com")
    ///     .login(withOOBCode: "123456", mfaToken: "mfa token")
    ///     .start { result in
    ///         switch result {
    ///         case .success(let credentials):
    ///             print("Obtained credentials: \(credentials)")
    ///         case .failure(let error):
    ///             print("Failed with \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - oobCode:     The oob code received from the challenge request.
    ///   - mfaToken:    Token returned when authentication fails due to MFA requirement.
    ///   - bindingCode: A code used to bind the side channel (used to deliver the challenge) with the main channel you are using to authenticate. This is usually an OTP-like code delivered as part of the challenge message.
    /// - Returns: Authentication request that will yield Auth0 user's credentials.
    /// - Requires: Grant `http://auth0.com/oauth/grant-type/mfa-oob`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
    func login(withOOBCode oobCode: String, mfaToken: String, bindingCode: String?) -> Request<Credentials, AuthenticationError>

    /// Verifies multi-factor authentication (MFA) using a recovery code.
    /// Some multi-factor authentication (MFA) providers (such as Guardian) support using a recovery code to login. Use this method to authenticate when the user's enrolled device is unavailable, or the user cannot receive the challenge or accept it due to connectivity issues.
    ///
    /// ```
    /// Auth0
    ///     .authentication(clientId: clientId, domain: "samples.auth0.com")
    ///     .login(withRecoveryCode: "recovery code", mfaToken: "mfa token")
    ///     .start { result in
    ///         switch result {
    ///         case .success(let credentials):
    ///             print("Obtained credentials: \(credentials)")
    ///         case .failure(let error):
    ///             print("Failed with \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - recoveryCode: Recovery code provided by the end-user.
    ///   - mfaToken:     Token returned when authentication fails due to MFA requirement.
    /// - Returns: Authentication request that will yield Auth0 user's credentials. Might include a recovery code, which the application must display to the end-user to be stored securely for future use.
    /// - Requires: Grant `http://auth0.com/oauth/grant-type/mfa-recovery-code`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
    func login(withRecoveryCode recoveryCode: String, mfaToken: String) -> Request<Credentials, AuthenticationError>

    /// Request a challenge for multi-factor authentication (MFA) based on the challenge types supported by the application and user.
    /// The `type` is how the user will get the challenge and prove possession. Supported challenge types include:
    /// * `otp`:  for one-time password (OTP)
    /// * `oob`:  for SMS/Voice messages or out-of-band (OOB)
    ///
    /// - Parameters:
    ///   - mfaToken:        Token returned when authentication fails due to MFA requirement.
    ///   - types:           A list of the challenges types accepted by your application. Accepted challenge types are `oob` or `otp`. Excluding this parameter means that your client application accepts all supported challenge types.
    ///   - authenticatorId: The ID of the authenticator to challenge. You can get the ID by querying the list of available authenticators for the user.
    /// - Returns: A request that will yield a multi-factor challenge.
    func multifactorChallenge(mfaToken: String, types: [String]?, authenticatorId: String?) -> Request<Challenge, AuthenticationError>

    /**
     Authenticate a user with their Sign In With Apple authorization code.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(appleAuthorizationCode: authCode)
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     If you need to specify a scope:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(appleAuthorizationCode: authCode,
                fullName: credentials.fullName,
                scope: "openid profile email offline_access",
                audience: "https://myapi.com/api")
         .start { print($0) }
     ```

     - Parameters:
       - authCode: Authorization Code retrieved from Apple Authorization.
       - fullName: The full name property returned with the Apple ID Credentials.
       - profile:  Additional user profile data returned with the Apple ID Credentials.
       - scope:    Requested scope value when authenticating the user. By default is `openid profile email`.
       - audience: API Identifier that the client is requesting access to.
     - Returns: A request that will yield Auth0 user's credentials.
     */
    func login(appleAuthorizationCode authorizationCode: String, fullName: PersonNameComponents?, profile: [String: Any]?, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Authenticate a user with their Facebook session info access token and profile data.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(facebookSessionAccessToken: sessionAccessToken, profile: profile)
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     If you need to specify a scope or audience:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(facebookSessionAccessToken: sessionAccessToken,
                scope: "openid profile email offline_access",
                audience: "https://myapi.com/api")
         .start { print($0) }
     ```

     - Parameters:
       - sessionAccessToken: Session info access token retrieved from Facebook.
       - profile:            The user profile returned by Facebook.
       - scope:              Requested scope value when authenticating the user. By default is `openid profile email`.
       - audience:           API Identifier that the client is requesting access to.
     - Returns: A request that will yield Auth0 user's credentials.
     */
    func login(facebookSessionAccessToken sessionAccessToken: String, profile: [String: Any], audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Login using username and password in the default directory.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .loginDefaultDirectory(withUsername: "support@auth0.com",
                                password: "a secret password")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     You can also specify audience and scope:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .loginDefaultDirectory(withUsername: "support@auth0.com",
                                password: "a secret password",
                                audience: "https://myapi.com/api",
                                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     - Parameters:
       - username: Username or email used of the user to authenticate.
       - password: Password of the user.
       - audience: API Identifier that the client is requesting access to.
       - scope:    Scope value requested when authenticating the user.
     - Important: This only works if you have the OAuth 2.0 API Authorization flag on.
     - Returns: Authentication request that will yield Auth0 user's credentials.
     */
    func loginDefaultDirectory(withUsername username: String, password: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError>

    /**
     Creates a user in a Database connection.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .createUser(email: "support@auth0.com",
                     password: "a secret password",
                     connection: "Username-Password-Authentication")
         .start { result in
             switch result {
             case .success(let user):
                 print("User signed up: \(user)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     You can also add additional metadata when creating the user:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .createUser(email: "support@auth0.com",
                     password: "a secret password",
                     connection: "Username-Password-Authentication",
                     userMetadata: ["first_name": "support"])
         .start { print($0) }
     ```

     If the database connection requires a username:

     ```
     Auth0
         .authentication(clientId, domain: "samples.auth0.com")
         .createUser(email: "support@auth0.com",
                     username: "support",
                     password: "a secret password",
                     connection: "Username-Password-Authentication")
         .start { print($0) }
     ```

     - Parameters:
       - email:          Email of the user to create.
       - username:       Username of the user if the connection requires username. By default is `nil`.
       - password:       Password for the new user.
       - connection:     Name where the user will be created (Database connection).
       - userMetadata:   Additional userMetadata parameters that will be added to the newly created user.
       - rootAttributes: Root attributes that will be added to the newly created user. See https://auth0.com/docs/api/authentication#signup for supported attributes. Will not overwrite existing parameters.
     - Returns: Request that will yield a created database user (just email, username and email verified flag).
     */
    // swiftlint:disable:next function_parameter_count
    func createUser(email: String, username: String?, password: String, connection: String, userMetadata: [String: Any]?, rootAttributes: [String: Any]?) -> Request<DatabaseUser, AuthenticationError>

    /**
     Resets a Database user password.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .resetPassword(email: "support@auth0.com", connection: "Username-Password-Authentication")
         .start { print($0) }
     ```

     - Parameters:
       - email:      Email of the database user.
       - connection: Name of the Database connection.
     - Returns: Request to reset password.
     */
    func resetPassword(email: String, connection: String) -> Request<Void, AuthenticationError>

    /**
     Starts passwordless authentication by sending an email with a OTP code.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .startPasswordless(email: "support@auth0.com")
         .start { print($0) }
     ```

     If you have configured iOS Universal Links:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .startPasswordless(email: "support@auth0.com", type: .iOSLink)
         .start { print($0) }
     ```

     - Parameters:
       - email:      Email where to send the code or link.
       - type:       Type of passwordless authentication. By default is `code`.
       - connection: Name of the passwordless connection. By default is 'email'.
     - Returns: A request.
     - Requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
     */
    func startPasswordless(email: String, type: PasswordlessType, connection: String, parameters: [String: Any]) -> Request<Void, AuthenticationError>

    /**
     Starts passwordless authentication by sending an sms with an OTP code.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .startPasswordless(phoneNumber: "+12025550135")
         .start { print($0) }
     ```

     If you have configured iOS Universal Links:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .startPasswordless(phoneNumber: "+12025550135", type: .iOSLink)
         .start { print($0) }
     ```

     - Parameters:
       - phoneNumber: Phone number where to send the sms with code or link.
       - type:        Type of passwordless authentication. By default is `code`.
       - connection:  Name of the passwordless connection. By default is 'sms'.
     - Returns: A request.
     - Requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
     */
    func startPasswordless(phoneNumber: String, type: PasswordlessType, connection: String) -> Request<Void, AuthenticationError>

    /**
     Returns OIDC standard claims information by performing a request to the `/userinfo` endpoint.

     ```
     Auth0
         .authentication(clientId, domain: "samples.auth0.com")
         .userInfo(withAccessToken: accessToken)
         .start { result in
             switch result {
             case .success(let user):
                 print("User: \(user)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     - Parameter accessToken: accessToken obtained by authenticating the user.
     - Returns: A request that will yield user information.
     */
    func userInfo(withAccessToken accessToken: String) -> Request<UserInfo, AuthenticationError>

    /**
     Performs the last step of Proof Key for Code Exchange [RFC 7636](https://tools.ietf.org/html/rfc7636).
     This will request the user's token using the code and it's verifier after a request to `/oauth/authorize`.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .codeExchange(withCode: "a code",
                       codeVerifier: "code verifier",
                       redirectURI: "https://samples.auth0.com/callback")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     - Parameters:
       - code:         Code returned after an `/oauth/authorize` request.
       - codeVerifier: Verifier used to generate the challenge sent in `/oauth/authorize` request.
       - redirectURI:  Redirect uri sent in `/oauth/authorize` request.
     - Returns: A request that will yield Auth0 user's credentials.
     - See: https://tools.ietf.org/html/rfc7636
     */
    func codeExchange(withCode code: String, codeVerifier: String, redirectURI: String) -> Request<Credentials, AuthenticationError>

    /**
     Renew the user's credentials with a `refresh_token` grant for `/oauth/token`.

     ```
     Auth0
         .renew(withRefreshToken: refreshToken, scope: "openid profile email offline_access read:users")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained new credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     To ask the same scopes requested when the refresh token was issued:

     ```
     Auth0
         .renew(withRefreshToken: refreshToken)
         .start { print($0) }
     ```

     - Parameters:
       - refreshToken: The client's refresh token.
       - scope:        Scopes to request for the new tokens. By default is `nil`, which will ask for the same ones requested during Auth.
     - Important: This method only works for a refresh token obtained after auth with OAuth 2.0 API Authorization.
     - Returns: A request that will yield Auth0 user's credentials.
     */
    func renew(withRefreshToken refreshToken: String, scope: String?) -> Request<Credentials, AuthenticationError>

    /**
     Revoke a user's `refresh_token` with a call to `/oauth/revoke`.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .revoke(refreshToken: refreshToken)
         .start { print($0) }
     ```

     - Parameter refreshToken: the client's refresh token.
     - Returns: A request.
     */
    func revoke(refreshToken: String) -> Request<Void, AuthenticationError>

    /**
     Returns JSON Web Key Set (JWKS) information by performing a request to the `/.well-known/jwks.json` endpoint.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .jwks()
         .start { result in
             switch result {
             case .success(let jwks):
                 print("Obtained JWKS: \(jwks)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```
    
     - Returns: A request that will yield JWKS information.
     */
    func jwks() -> Request<JWKS, AuthenticationError>

}

public extension Authentication {

    /**
     Logs in a user using an email and an OTP code received via email (last part of the passwordless login flow).

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(email: "support@auth0.com", code: "123456")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     You can also specify audience and scope:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(email: "support@auth0.com",
                code: "123456",
                audience: "https://myapi.com/api",
                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     When result is `.success`, its associated value will be a `Credentials` object.

     - Parameters:
       - email:    Email the user used to start the passwordless login flow.
       - code:     One time password (OTP) code the user received via email.
       - audience: API Identifier that the client is requesting access to. Default is `nil`.
       - scope:    Scope value requested when authenticating the user. Default is `openid profile email`.
     - Returns: Authentication request that will yield Auth0 user's credentials.
     - Requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
     */
    func login(email username: String, code otp: String, audience: String? = nil, scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.login(email: username, code: otp, audience: audience, scope: scope)
    }

    /**
     Logs in a user using a phone number and an OTP code received via sms (last part of the passwordless login flow).

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(phoneNumber: "+4599134762367", code: "123456")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     You can also specify audience and scope:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(phoneNumber: "+4599134762367",
                code: "123456",
                audience: "https://myapi.com/api",
                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     When result is `.success`, its associated value will be a `Credentials` object.

     - Parameters:
       - phoneNumber: Phone number the user used to start the passwordless login flow.
       - code:        One time password (OTP) code the user received via sms.
       - audience:    API Identifier that the client is requesting access to. Default is `nil`.
       - scope:       Scope value requested when authenticating the user. Default is `openid profile email`.
     - Returns: Authentication request that will yield Auth0 user's credentials.
     - Requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
     */
    func login(phoneNumber username: String, code otp: String, audience: String? = nil, scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.login(phoneNumber: username, code: otp, audience: audience, scope: scope)
    }

    /**
     Login using username and password in a realm.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(usernameOrEmail: "support@auth0.com",
                password: "a secret password",
                realm: "mydatabase")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     You can also specify audience and scope:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(usernameOrEmail: "support@auth0.com",
                password: "a secret password",
                realm: "mydatabase",
                audience: "https://myapi.com/api",
                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     - Parameters:
       - username: Username or email used of the user to authenticate.
       - password: Password of the user.
       - realm:    Domain of the realm or connection name.
       - audience: API Identifier that the client is requesting access to.
       - scope:    Scope value requested when authenticating the user.
     - Important: This only works if you have the OAuth 2.0 API Authorization flag on.
     - Returns: Authentication request that will yield Auth0 user's credentials.
     - Requires: Grant `http://auth0.com/oauth/grant-type/password-realm`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
     */
    func login(usernameOrEmail username: String, password: String, realm: String, audience: String? = nil, scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.login(usernameOrEmail: username, password: password, realm: realm, audience: audience, scope: scope)
    }

    /**
     Authenticate a user with their Sign In With Apple authorization code.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(appleAuthorizationCode: authCode)
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     If you need to specify a scope:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(appleAuthorizationCode: authCode,
                fullName: credentials.fullName,
                scope: "openid profile email offline_access",
                audience: "https://myapi.com/api")
         .start { print($0) }
     ```

     - Parameters:
       - authCode: Authorization Code retrieved from Apple Authorization.
       - fullName: The full name property returned with the Apple ID Credentials.
       - profile:  Additional user profile data returned with the Apple ID Credentials.
       - scope:    Requested scope value when authenticating the user. By default is `openid profile email`.
       - audience: API Identifier that the client is requesting access to.
     - Returns: A request that will yield Auth0 user's credentials.
     */
    func login(appleAuthorizationCode authorizationCode: String, fullName: PersonNameComponents? = nil, profile: [String: Any]? = nil, audience: String? = nil, scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.login(appleAuthorizationCode: authorizationCode, fullName: fullName, profile: profile, audience: audience, scope: scope)
    }

    /**
     Authenticate a user with their Facebook session info access token and profile data.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(facebookSessionAccessToken: sessionAccessToken, profile: profile)
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     If you need to specify a scope or audience:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(facebookSessionAccessToken: sessionAccessToken,
                scope: "openid profile email offline_access",
                audience: "https://myapi.com/api")
         .start { print($0) }
     ```

     - Parameters:
       - sessionAccessToken: Session info access token retrieved from Facebook.
       - profile:            The user profile returned by Facebook.
       - scope:              Requested scope value when authenticating the user. By default is `openid profile email`.
       - audience:           API Identifier that the client is requesting access to.
     - Returns: A request that will yield Auth0 user's credentials.
     */
    func login(facebookSessionAccessToken sessionAccessToken: String, profile: [String: Any], audience: String? = nil, scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.login(facebookSessionAccessToken: sessionAccessToken, profile: profile, audience: audience, scope: scope)
    }

    /**
     Login using username and password in the default directory.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .loginDefaultDirectory(withUsername: "support@auth0.com",
                                password: "a secret password")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     You can also specify audience and scope:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .loginDefaultDirectory(withUsername: "support@auth0.com",
                                password: "a secret password",
                                audience: "https://myapi.com/api",
                                scope: "openid profile email offline_access")
         .start { print($0) }
     ```

     - Parameters:
       - username: Username or email used of the user to authenticate.
       - password: Password of the user.
       - audience: API Identifier that the client is requesting access to.
       - scope:    Scope value requested when authenticating the user.
     - Important: This only works if you have the OAuth 2.0 API Authorization flag on.
     - Returns: Authentication request that will yield Auth0 user's credentials.
     */
    func loginDefaultDirectory(withUsername username: String, password: String, audience: String? = nil, scope: String = defaultScope) -> Request<Credentials, AuthenticationError> {
        return self.loginDefaultDirectory(withUsername: username, password: password, audience: audience, scope: scope)
    }

    /**
     Creates a user in a Database connection.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .createUser(email: "support@auth0.com",
                     password: "a secret password",
                     connection: "Username-Password-Authentication")
         .start { result in
             switch result {
             case .success(let user):
                 print("User signed up: \(user)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     You can also add additional metadata when creating the user:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .createUser(email: "support@auth0.com",
                     password: "a secret password",
                     connection: "Username-Password-Authentication",
                     userMetadata: ["first_name": "support"])
         .start { print($0) }
     ```

     If the database connection requires a username:

     ```
     Auth0
         .authentication(clientId, domain: "samples.auth0.com")
         .createUser(email: "support@auth0.com",
                     username: "support",
                     password: "a secret password",
                     connection: "Username-Password-Authentication")
         .start { print($0) }
     ```

     - Parameters:
       - email:          Email of the user to create.
       - username:       Username of the user if the connection requires username. By default is `nil`.
       - password:       Password for the new user.
       - connection:     Name where the user will be created (Database connection).
       - userMetadata:   Additional userMetadata parameters that will be added to the newly created user.
       - rootAttributes: Root attributes that will be added to the newly created user. See https://auth0.com/docs/api/authentication#signup for supported attributes. Will not overwrite existing parameters.
     - Returns: Request that will yield a created database user (just email, username and email verified flag).
     */
    func createUser(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: Any]? = nil, rootAttributes: [String: Any]? = nil) -> Request<DatabaseUser, AuthenticationError> {
        return self.createUser(email: email, username: username, password: password, connection: connection, userMetadata: userMetadata, rootAttributes: rootAttributes)
    }

    /**
     Creates a user in a Database connection.
     
     - Parameters:
       - email:        Email of the user to create.
       - username:     Username of the user if the connection requires username. By default is `nil`.
       - password:     Password for the new user.
       - connection:   Name where the user will be created (Database connection).
       - userMetadata: Additional userMetadata parameters that will be added to the newly created user.
     - Returns: Request that will yield a created database user (just email, username and email verified flag).
     */
    func createUser(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: Any]? = nil) -> Request<DatabaseUser, AuthenticationError> {
        return self.createUser(email: email, username: username, password: password, connection: connection, userMetadata: userMetadata, rootAttributes: nil)
    }

    /**
     Starts passwordless authentication by sending an email with a OTP code.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .startPasswordless(email: "support@auth0.com")
         .start { print($0) }
     ```

     If you have configured iOS Universal Links:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .startPasswordless(email: "support@auth0.com", type: .iOSLink)
         .start { print($0) }
     ```

     - Parameters:
       - email:      Email where to send the code or link.
       - type:       Type of passwordless authentication. By default is `code`.
       - connection: Name of the passwordless connection. By default is 'email'.
     - Returns: A request.
     - Requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
     */
    func startPasswordless(email: String, type: PasswordlessType = .code, connection: String = "email", parameters: [String: Any] = [:]) -> Request<Void, AuthenticationError> {
        return self.startPasswordless(email: email, type: type, connection: connection, parameters: parameters)
    }

    /**
     Starts passwordless authentication by sending an sms with an OTP code.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .startPasswordless(phoneNumber: "+12025550135")
         .start { print($0) }
     ```

     If you have configured iOS Universal Links:

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .startPasswordless(phoneNumber: "+12025550135", type: .iOSLink)
         .start { print($0) }
     ```

     - Parameters:
       - phoneNumber: Phone number where to send the sms with code or link.
       - type:        Type of passwordless authentication. By default is `code`.
       - connection:  Name of the passwordless connection. By default is 'sms'.
     - Returns: A request.
     - Requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check [our documentation](https://auth0.com/docs/configure/applications/application-grant-types) for more info and how to enable it.
     */
    func startPasswordless(phoneNumber: String, type: PasswordlessType = .code, connection: String = "sms") -> Request<Void, AuthenticationError> {
        return self.startPasswordless(phoneNumber: phoneNumber, type: type, connection: connection)
    }

    /**
     Renew the user's credentials with a `refresh_token` grant for `/oauth/token`.

     ```
     Auth0
         .renew(withRefreshToken: refreshToken, scope: "openid profile email offline_access read:users")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained new credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     To ask the same scopes requested when the refresh token was issued:

     ```
     Auth0
         .renew(withRefreshToken: refreshToken)
         .start { print($0) }
     ```

     - Parameters:
       - refreshToken: The client's refresh token.
       - scope:        Scopes to request for the new tokens. By default is `nil`, which will ask for the same ones requested during Auth.
     - Important: This method only works for a refresh token obtained after auth with OAuth 2.0 API Authorization.
     - Returns: A request that will yield Auth0 user's credentials.
     */
    func renew(withRefreshToken refreshToken: String, scope: String? = nil) -> Request<Credentials, AuthenticationError> {
        return self.renew(withRefreshToken: refreshToken, scope: scope)
    }

}
