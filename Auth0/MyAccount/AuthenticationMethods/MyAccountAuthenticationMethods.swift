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

}
