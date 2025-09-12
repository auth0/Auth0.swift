/// My Account API sub-client for managing the current user's authentication methods.
///
/// ## See Also
/// - ``MyAccount``
/// - ``MyAccountError``
public protocol MyAccountAuthenticationMethods: MyAccountClient {
    
#if PASSKEYS_PLATFORM
    /// Requests a challenge for enrolling a new passkey. This is the first part of the enrollment flow.
    ///
    /// You can specify an optional user identity identifier and an optional database connection name. If a
    /// connection name is not specified, your tenant's default directory will be used.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `create:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .passkeyEnrollmentChallenge()
    ///     .start { result in
    ///         switch result {
    ///         case .success(let enrollmentChallenge):
    ///             print("Obtained enrollment challenge: \(enrollmentChallenge)")
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
    ///     relyingPartyIdentifier: enrollmentChallenge.relyingPartyId
    /// )
    ///
    /// let request = credentialProvider.createCredentialRegistrationRequest(
    ///     challenge: enrollmentChallenge.challengeData,
    ///     name: enrollmentChallenge.userName,
    ///     userID: enrollmentChallenge.userId
    /// )
    ///
    /// let authController = ASAuthorizationController(authorizationRequests: [request])
    /// authController.delegate = self // ASAuthorizationControllerDelegate
    /// authController.presentationContextProvider = self
    /// authController.performRequests()
    /// ```
    ///
    /// Then, call ``enroll(passkey:challenge:)`` with the created passkey credential and the challenge to complete the
    /// enrollment.
    ///
    /// - Parameters:
    ///   - userIdentityId: Unique identifier of the current user's identity. Needed if the user logged in with a [linked account](https://auth0.com/docs/manage-users/user-accounts/user-account-linking).
    ///   Defaults to `nil`.
    ///   - connection:     Name of the database connection where the user is stored. Defaults to `nil`.
    /// - Returns: A request that will yield a passkey enrollment challenge.
    ///
    /// ## See Also
    ///
    /// - [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Register-a-new-account-on-a-service)
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyEnrollmentChallenge(userIdentityId: String?,
                                    connection: String?) -> Request<PasskeyEnrollmentChallenge, MyAccountError>
    
    /// Enrolls a new passkey credential. This is the last part of the enrollment flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `create:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .enroll(passkey: newPasskey, challenge: enrollmentChallenge)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let authenticationMethod):
    ///             print("Enrolled passkey: \(authenticationMethod)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - passkey:   The new passkey credential obtained from the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate) delegate.
    ///   - challenge: The passkey enrollment challenge obtained from ``passkeyEnrollmentChallenge(userIdentityId:connection:)``.
    /// - Returns: A request that will yield an enrolled passkey authentication method.
    ///
    /// ## See Also
    ///
    /// - [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Register-a-new-account-on-a-service)
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func enroll(passkey: NewPasskey,
                challenge: PasskeyEnrollmentChallenge) -> Request<PasskeyAuthenticationMethod, MyAccountError>
#endif

    /// Requests a challenge for enrolling a recovery code authentication method. This is the first part of the enrollment flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `create:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .enrollRecoveryCode()
    ///     .start { result in
    ///         switch result {
    ///         case .success(let enrollmentChallenge):
    ///             print("Obtained enrollment Challenge \(enrollmentChallenge)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Returns: A request that will yield an recovery code challenge
    func enrollRecoveryCode() -> Request<RecoveryCodeEnrollmentChallenge, MyAccountError>

    /// Enrolls a new Recovery code credential. This is the last part of the enrollment flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `create:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .confirmRecoveryCodeEnrollment(id: id, authSession: authSession)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let authenticationMethod):
    ///             print("Enrolled recovery code: \(authenticationMethod)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - id: This value is part of the Location header returned when creating an authentication method. It should be used as it is, without any modifications.
    ///   - authSession: The unique session identifier for the enrollment as returned by POST /authentication-methods
    /// - Returns: A request that will yield an enrolled recovery code authentication method.
    func confirmRecoveryCodeEnrollment(id: String,
                                      authSession: String) -> Request<AuthenticationMethod, MyAccountError>

    /// Requests a challenge for enrolling a TOTP authentication method. This is the first part of the enrollment flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `create:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .enrollTOTP()
    ///     .start { result in
    ///         switch result {
    ///         case .success(let enrollmentChallenge):
    ///             print("Obtained enrollment challenge \(enrollmentChallenge)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Returns: A request that will yield a totp enrollment challenge
    func enrollTOTP() -> Request<TOTPEnrollmentChallenge, MyAccountError>
    
    /// Enrolls a new ToTP authentication method. This is the last part of the enrollment flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `create:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .confirmTOTPEnrollment(id: id, authSession: authSession, otpCode: otpCode)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let authenticationMethod):
    ///             print("Enrolled TOTP: \(authenticationMethod)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - id: This value is part of the Location header returned when creating an authentication method. It should be used as it is, without any modifications.
    ///   - authSession: The unique session identifier for the enrollment as returned by POST /authentication-methods
    ///   - otpCode: The one-time password code retrieved from the TOTP application.
    /// - Returns: A request that will yield an enrolled TOTP authentication method.
    func confirmTOTPEnrollment(id: String,
                               authSession: String,
                               otpCode: String) -> Request<AuthenticationMethod, MyAccountError>

    /// Requests a challenge for enrolling a push notification authentication method. This is the first part of the enrollment flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `create:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .enrollPushNotification()
    ///     .start { result in
    ///         switch result {
    ///         case .success(let enrollmentChallenge):
    ///             print("Obtained enrollment challenge \(enrollmentChallenge)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Returns: A request that will yield a push notification enrolment challenge
    func enrollPushNotification() -> Request<PushEnrollmentChallenge, MyAccountError>

    /// Enrolls a new Push Notification authentication method. This is the last part of the enrollment flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `create:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .confirmPushNotificationEnrollment(id: id, authSession: authSession)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let authenticationMethod):
    ///             print("Enrolled push notification: \(authenticationMethod)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - id: This value is part of the Location header returned when creating an authentication method. It should be used as it is, without any modifications.
    ///   - authSession: The unique session identifier for the enrollment as returned by POST /authentication-methods
    /// - Returns: A request that will yield an enrolled Push Notification authentication method.
    ///
    func confirmPushNotificationEnrollment(id: String,
                                           authSession: String) -> Request<AuthenticationMethod, MyAccountError>

    /// Requests a challenge for enrolling a Email authentication method. This is the first part of the enrollment flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `create:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .enrollEmail(emailAddress: emailAddress)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let enrollmentChallenge):
    ///             print("Enrolled enrollment challenge: \(enrollmentChallenge)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - emailAddress:  The email address to use for sending one-time codes.
    /// - Returns: A request that will yield a email enrolment challenge
    func enrollEmail(emailAddress: String) -> Request<EmailEnrollmentChallenge, MyAccountError>

    /// Enrolls a new Email authentication method. This is the last part of the enrollment flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `create:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .confirmEmailEnrollment(id: id, authSession: authSession, otpCode: otpCode)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let authenticationMethod):
    ///             print("Enrolled email: \(authenticationMethod)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - id: This value is part of the Location header returned when creating an authentication method. It should be used as it is, without any modifications.
    ///   - authSession: The unique session identifier for the enrollment as returned by POST /authentication-methods
    ///   - otpCode: The one-time password code sent to the email address.
    /// - Returns: A request that will yield an enrolled email authentication method.
    func confirmEmailEnrollment(id: String,
                               authSession: String,
                               otpCode: String) -> Request<AuthenticationMethod, MyAccountError>

    /// Requests a challenge for enrolling a Phone authentication method. This is the first part of the enrollment flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `create:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .enrollPhone(phoneNumber: phoneNumber, preferredAuthenticationMethod: preferredAuthenticationMethod)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let enrollmentChallenge):
    ///             print("Obtained enrollment challenge: \(enrollmentChallenge)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - phoneNumber: The destination phone number used to send verification codes via text and voice.
    ///   - preferredAuthenticationMethod: The preferred communication method(sms). If no value is passed by default sms will be the preferred authentication method
    /// - Returns: A request that will yield a phone enrollment challenge
    func enrollPhone(phoneNumber: String,
                     preferredAuthenticationMethod: PreferredAuthenticationMethod?) -> Request<PhoneEnrollmentChallenge, MyAccountError>

    /// Enrolls a new Phone authentication method. This is the last part of the enrollment flow.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `create:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .confirmPhoneEnrollment(id: id, authSession: authSession, otpCode: otpCode)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let authenticationMethod):
    ///             print("Enrolled phone: \(authenticationMethod)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - id: This value is part of the Location header returned when creating an authentication method. It should be used as it is, without any modifications.
    ///   - authSession: The unique session identifier for the enrollment as returned by POST /authentication-methods
    ///   - otpCode: The one-time password code sent to the phone number.
    /// - Returns: A request that will yield an enrolled phone authentication method.
    func confirmPhoneEnrollment(id: String,
                                authSession: String,
                                otpCode: String) -> Request<AuthenticationMethod, MyAccountError>

    /// Retrieve detailed list of authentication methods belonging to the authenticated user.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `read:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .getAuthenticationMethods()
    ///     .start { result in
    ///         switch result {
    ///         case .success(let authenticationMethods):
    ///             print("List of Authentication methods: \(authenticationMethods)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Returns: A request that will return list of authentication methods of an authenticated user
    func getAuthenticationMethods() -> Request<[AuthenticationMethod], MyAccountError>

    /// Delete an authentication method associated with an id
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `delete:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .deleteAuthenticationMethod(by: id)
    ///     .start { result in
    ///         switch result {
    ///         case .success:
    ///             print("Authentication method is deleted")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - id: Id of the authentication method user wishes to delete
    /// - Returns: A request that will delete an authentication method associated with an id
    func deleteAuthenticationMethod(by id: String) -> Request<Void, MyAccountError>

    /// Fetch details of an authentication method associated with an id
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `read:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .getAuthenticationMethod(by: id)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let authenticationMethod):
    ///             print("Fetched authentication method: \(authenticationMethod)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - id:  Id of the returned authentication method
    /// - Returns: A request to fetch authentication method associated with the id.
    func getAuthenticationMethod(by id: String) -> Request<AuthenticationMethod, MyAccountError>

    /// List of factors enabled for the Auth0 tenant and available for enrollment by this user.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `read:me:factors`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .getFactors()
    ///     .start { result in
    ///         switch result {
    ///         case .success(let factors):
    ///             print("List of factors enabled: \(factors)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Returns: A request to fetch factors enabled for the Auth0 tenant and available for enrollment
    func getFactors() -> Request<[Factor], MyAccountError>
}
// MARK: - Default Parameters

public extension MyAccountAuthenticationMethods {

    #if PASSKEYS_PLATFORM
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyEnrollmentChallenge(userIdentityId: String? = nil,
                                    connection: String? = nil) -> Request<PasskeyEnrollmentChallenge, MyAccountError> {
        self.passkeyEnrollmentChallenge(userIdentityId: userIdentityId, connection: connection)
    }
    #endif

    func enrollPhone(phoneNumber: String,
                     preferredAuthenticationMethod: PreferredAuthenticationMethod? = nil) -> Request<PhoneEnrollmentChallenge, MyAccountError> {
        self.enrollPhone(phoneNumber: phoneNumber,
                         preferredAuthenticationMethod: preferredAuthenticationMethod)
    }
}
