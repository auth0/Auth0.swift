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
                                    connection: String?) -> any Requestable<PasskeyEnrollmentChallenge, MyAccountError>

    /// Enrolls a new passkey credential. This is the last part of the enrollment flow.
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
                challenge: PasskeyEnrollmentChallenge) -> any Requestable<PasskeyAuthenticationMethod, MyAccountError>
#endif

    /// Requests a challenge for enrolling a password authentication method. This is the first part of the enrollment flow.
    ///
    /// You can specify an optional user identity identifier and an optional database connection name. If a
    /// connection name is not specified, your tenant's default directory will be used.
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
    ///     .enrollPassword()
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
    /// Use the challenge's ``PasswordEnrollmentChallenge/policy`` to guide the user toward a compliant password,
    /// then call ``confirmPasswordEnrollment(id:authSession:newPassword:)`` with the new password to complete
    /// the enrollment.
    ///
    /// - Parameters:
    ///   - userIdentityId: Unique identifier of the current user's identity. Needed if the user logged in with a [linked account](https://auth0.com/docs/manage-users/user-accounts/user-account-linking).
    ///   Pass the bare identifier **without** the identity provider prefix (e.g. use `123456` rather than `auth0|123456`).
    ///   Defaults to `nil`.
    ///   - connection:     Name of the database connection where the user is stored. Defaults to `nil`.
    /// - Returns: A request that will yield a password enrollment challenge, including the password policy to satisfy.
    func enrollPassword(userIdentityId: String?,
                        connection: String?) -> any Requestable<PasswordEnrollmentChallenge, MyAccountError>

    /// Confirms the enrollment of a password authentication method by providing a new password that satisfies
    /// the policy from the enrollment challenge. This is the last part of the enrollment flow.
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
    ///     .confirmPasswordEnrollment(id: id, authSession: authSession, newPassword: newPassword)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let authenticationMethod):
    ///             print("Enrolled password: \(authenticationMethod)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - id: The ``PasswordEnrollmentChallenge/authenticationId`` returned by ``enrollPassword(userIdentityId:connection:)``. It should be used as it is, without any modifications.
    ///   - authSession: The unique session identifier for the enrollment as returned by POST /authentication-methods
    ///   - newPassword: The new password to set, satisfying the policy from the enrollment challenge.
    /// - Returns: A request that will yield an enrolled password authentication method.
    func confirmPasswordEnrollment(id: String,
                                   authSession: String,
                                   newPassword: String) -> any Requestable<AuthenticationMethod, MyAccountError>

    /// Requests a challenge for enrolling a recovery code authentication method. This is the first part of the enrollment flow.
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
    func enrollRecoveryCode() -> any Requestable<RecoveryCodeEnrollmentChallenge, MyAccountError>

    /// Enrolls a new Recovery code credential. This is the last part of the enrollment flow.
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
                                       authSession: String) -> any Requestable<AuthenticationMethod, MyAccountError>

    /// Requests a challenge for enrolling a TOTP authentication method. This is the first part of the enrollment flow.
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
    func enrollTOTP() -> any Requestable<TOTPEnrollmentChallenge, MyAccountError>

    /// Enrolls a new ToTP authentication method. This is the last part of the enrollment flow.
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
                               otpCode: String) -> any Requestable<AuthenticationMethod, MyAccountError>

    /// Requests a challenge for enrolling a push notification authentication method. This is the first part of the enrollment flow.
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
    func enrollPushNotification() -> any Requestable<PushEnrollmentChallenge, MyAccountError>

    /// Enrolls a new Push Notification authentication method. This is the last part of the enrollment flow.
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
                                           authSession: String) -> any Requestable<AuthenticationMethod, MyAccountError>

    /// Requests a challenge for enrolling a Email authentication method. This is the first part of the enrollment flow.
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
    func enrollEmail(emailAddress: String) -> any Requestable<EmailEnrollmentChallenge, MyAccountError>

    /// Enrolls a new Email authentication method. This is the last part of the enrollment flow.
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
                                otpCode: String) -> any Requestable<AuthenticationMethod, MyAccountError>

    /// Requests a challenge for enrolling a Phone authentication method. This is the first part of the enrollment flow.
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
                     preferredAuthenticationMethod: PreferredAuthenticationMethod?) -> any Requestable<PhoneEnrollmentChallenge, MyAccountError>

    /// Enrolls a new Phone authentication method. This is the last part of the enrollment flow.
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
                                otpCode: String) -> any Requestable<AuthenticationMethod, MyAccountError>

    /// Delete an authentication method associated with an id
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
    func deleteAuthenticationMethod(by id: String) -> any Requestable<Void, MyAccountError>

    /// Fetch details of an authentication method associated with an id
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
    func getAuthenticationMethod(by id: String) -> any Requestable<AuthenticationMethod, MyAccountError>

    /// Retrieve detailed list of authentication methods belonging to the authenticated user.
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
    /// - Parameter type: Filters results to only authentication methods of this type. Pass `nil` to retrieve all types.
    /// - Returns: A request that will return list of authentication methods of an authenticated user
    func getAuthenticationMethods(type: AuthenticationMethodType?) -> any Requestable<[AuthenticationMethod], MyAccountError>

    /// Update an authentication method associated with an id.
    ///
    /// ## Scopes Required
    ///
    /// `update:me:authentication_methods`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .updateAuthenticationMethod(by: id, name: name)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let authenticationMethod):
    ///             print("Updated authentication method: \(authenticationMethod)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - id:                            Id of the authentication method to update.
    ///   - name:                          The friendly name of the authentication method. Pass `nil` to leave unchanged.
    ///   - preferredAuthenticationMethod: For phone authenticators, the preferred delivery method (`sms` or `voice`). Pass `nil` to leave unchanged.
    /// - Returns: A request that will yield the updated authentication method.
    func updateAuthenticationMethod(by id: String,
                                    name: String?,
                                    preferredAuthenticationMethod: PreferredAuthenticationMethod?) -> any Requestable<AuthenticationMethod, MyAccountError>

    /// List of factors enabled for the Auth0 tenant and available for enrollment by this user.
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
    func getFactors() -> any Requestable<[Factor], MyAccountError>

    /// Retrieves the authenticated user's profile.
    ///
    /// Returns the user's profile attributes along with a per-field access policy
    /// (``MyAccountProfile/profilePolicy``) that indicates which fields are editable.
    ///
    /// ## Availability
    ///
    /// This feature is currently in
    /// [Beta](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#beta).
    /// It might change before General Availability, and Auth0 does not support beta functionality for
    /// production use. The feature must be enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `read:me:profile`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .getUserProfile(options: nil)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let profile):
    ///             print("User profile: \(profile)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// Use ``GetUserProfileOptions`` to limit which fields are returned:
    ///
    /// ```swift
    /// let options = GetUserProfileOptions(
    ///     fields: ["given_name", "family_name", "email"],
    ///     includeFields: true
    /// )
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .getUserProfile(options: options)
    ///     .start { result in ... }
    /// ```
    ///
    /// - Note: A `MyAccountError` with `statusCode == 403` means the token lacks the required scope or the
    ///   **My Account Profile** feature is not enabled for this tenant. Check ``MyAccountError/code``:
    ///   `.../A0E-403-0002` is insufficient scope and `.../A0E-403-0003` is not entitled. When the feature is
    ///   off, tokens are not granted the profile scopes, so you will usually see insufficient scope.
    ///
    /// - Parameter options: Field-selection options. Pass `nil` to return all fields.
    /// - Returns: A request that will yield the user's ``MyAccountProfile``.
    ///
    /// ## See Also
    ///
    /// - ``MyAccountProfile``
    /// - ``GetUserProfileOptions``
    /// - ``MyAccountError``
    func getUserProfile(options: GetUserProfileOptions?) -> any Requestable<MyAccountProfile, MyAccountError>

    /// Updates the authenticated user's writable profile attributes.
    ///
    /// Only the fields you set on ``UpdateUserProfileRequest`` are sent; omitted fields leave
    /// the stored values unchanged. The update is all-or-nothing — if any field is read-only or
    /// fails validation, the entire request is rejected.
    ///
    /// Returns the full updated profile.
    ///
    /// ## Availability
    ///
    /// This feature is currently in
    /// [Beta](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#beta).
    /// It might change before General Availability, and Auth0 does not support beta functionality for
    /// production use. The feature must be enabled for your tenant.
    ///
    /// ## Scopes Required
    ///
    /// `update:me:profile`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let request = UpdateUserProfileRequest(nickname: "wonderland_alice")
    ///
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .updateUserProfile(request)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let profile):
    ///             print("Updated profile: \(profile)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Note: A `MyAccountError` with `statusCode == 403` means the token lacks the required scope or the
    ///   **My Account Profile** feature is not enabled for this tenant. Check ``MyAccountError/code``:
    ///   `.../A0E-403-0002` is insufficient scope and `.../A0E-403-0003` is not entitled. When the feature is
    ///   off, tokens are not granted the profile scopes, so you will usually see insufficient scope.
    ///
    /// - Parameter request: The profile attributes to update.
    /// - Returns: A request that will yield the updated ``MyAccountProfile``.
    ///
    /// ## See Also
    ///
    /// - ``MyAccountProfile``
    /// - ``UpdateUserProfileRequest``
    /// - ``MyAccountError``
    func updateUserProfile(_ request: UpdateUserProfileRequest) -> any Requestable<MyAccountProfile, MyAccountError>
}
// MARK: - Default Parameters

public extension MyAccountAuthenticationMethods {

    #if PASSKEYS_PLATFORM
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyEnrollmentChallenge(userIdentityId: String? = nil,
                                    connection: String? = nil) -> any Requestable<PasskeyEnrollmentChallenge, MyAccountError> {
        self.passkeyEnrollmentChallenge(userIdentityId: userIdentityId, connection: connection)
    }
    #endif

    func enrollPhone(phoneNumber: String,
                     preferredAuthenticationMethod: PreferredAuthenticationMethod? = nil) -> any Requestable<PhoneEnrollmentChallenge, MyAccountError> {
        self.enrollPhone(phoneNumber: phoneNumber,
                         preferredAuthenticationMethod: preferredAuthenticationMethod)
    }

    func enrollPassword(userIdentityId: String? = nil,
                        connection: String? = nil) -> any Requestable<PasswordEnrollmentChallenge, MyAccountError> {
        self.enrollPassword(userIdentityId: userIdentityId, connection: connection)
    }

    func getAuthenticationMethods(type: AuthenticationMethodType? = nil) -> any Requestable<[AuthenticationMethod], MyAccountError> {
        self.getAuthenticationMethods(type: type)
    }

    func updateAuthenticationMethod(by id: String,
                                    name: String? = nil,
                                    preferredAuthenticationMethod: PreferredAuthenticationMethod? = nil) -> any Requestable<AuthenticationMethod, MyAccountError> {
        self.updateAuthenticationMethod(by: id,
                                        name: name,
                                        preferredAuthenticationMethod: preferredAuthenticationMethod)
    }
}

// MARK: - Profile convenience

public extension MyAccountAuthenticationMethods {

    /// Retrieves the authenticated user's profile with all fields.
    ///
    /// Convenience overload of ``getUserProfile(options:)`` that returns all profile fields.
    ///
    /// This API is currently in [Beta](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#beta) and might change before General Availability.
    ///
    /// ## Scopes Required
    ///
    /// `read:me:profile`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .authenticationMethods
    ///     .getUserProfile()
    ///     .start { result in
    ///         switch result {
    ///         case .success(let profile):
    ///             print("User profile: \(profile)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Returns: A request that will yield the user's ``MyAccountProfile``.
    func getUserProfile() -> any Requestable<MyAccountProfile, MyAccountError> {
        return getUserProfile(options: nil)
    }

}

// MARK: - Default implementations
public extension MyAccountAuthenticationMethods {

    /// Default implementation of ``getUserProfile(options:)`` for types outside the SDK that conform to
    /// ``MyAccountAuthenticationMethods``.
    ///
    /// This API is currently in [Beta](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#beta) and might change before General Availability.
    ///
    /// The client returned by ``MyAccount/authenticationMethods`` implements this method and calls the
    /// My Account API. This default implementation sends no request: the returned request fails with a
    /// ``MyAccountError`` whose ``MyAccountError/code`` is `a0.sdk.internal_error.not_implemented`. Implement the
    /// method in your conforming type to support it.
    ///
    /// - Parameter options: Ignored.
    /// - Returns: A request that fails with a ``MyAccountError``.
    func getUserProfile(options: GetUserProfileOptions?) -> any Requestable<MyAccountProfile, MyAccountError> {
        return notImplementedRequest(method: "GET", requirement: "getUserProfile(options:)")
    }

    /// Default implementation of ``updateUserProfile(_:)`` for types outside the SDK that conform to
    /// ``MyAccountAuthenticationMethods``.
    ///
    /// This API is currently in [Beta](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#beta) and might change before General Availability.
    ///
    /// The client returned by ``MyAccount/authenticationMethods`` implements this method and calls the
    /// My Account API. This default implementation sends no request: the returned request fails with a
    /// ``MyAccountError`` whose ``MyAccountError/code`` is `a0.sdk.internal_error.not_implemented`. Implement the
    /// method in your conforming type to support it.
    ///
    /// - Parameter request: Ignored.
    /// - Returns: A request that fails with a ``MyAccountError``.
    func updateUserProfile(_ request: UpdateUserProfileRequest) -> any Requestable<MyAccountProfile, MyAccountError> {
        return notImplementedRequest(method: "PATCH", requirement: "updateUserProfile(_:)")
    }

}

extension MyAccountAuthenticationMethods {

    /// A request that fails before it is sent, because the conforming type does not implement `requirement`.
    func notImplementedRequest<T: Decodable & Sendable>(method: String,
                                                        requirement: String) -> any Requestable<T, MyAccountError> {
        // The validator throws before the data task is created, so the session is never used.
        return Request(session: .shared,
                       url: url,
                       method: method,
                       requestValidator: [NotImplementedValidator(requirement: requirement)],
                       handle: { @Sendable result, callback in myAccountValidatedDecodable(result: result, callback: callback) },
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo)
    }

}

struct NotImplementedValidator: RequestValidator {

    let requirement: String

    func validate() throws {
        throw MyAccountError(info: ["type": notImplementedError,
                                    "title": "Not implemented",
                                    "detail": "\(requirement) is not implemented by this MyAccountAuthenticationMethods conformance."],
                             statusCode: 0)
    }

}
