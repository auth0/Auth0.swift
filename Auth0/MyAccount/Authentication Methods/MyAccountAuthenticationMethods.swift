public protocol MyAccountAuthenticationMethods: MyAccountClient {

    #if PASSKEYS_PLATFORM
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyEnrollmentChallenge(userIdentityId: String?,
                                    connection: String?) -> Request<PasskeyEnrollmentChallenge, MyAccountError>

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func enroll(passkey: NewPasskey,
                challenge: PasskeyEnrollmentChallenge) -> Request<PasskeyAuthenticationMethod, MyAccountError>
    #endif

}

public extension MyAccountAuthenticationMethods {

    #if PASSKEYS_PLATFORM
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyEnrollmentChallenge(userIdentityId: String? = nil,
                                    connection: String? = nil) -> Request<PasskeyEnrollmentChallenge, MyAccountError> {
        self.passkeyEnrollmentChallenge(userIdentityId: userIdentityId, connection: connection)
    }
    #endif

}
