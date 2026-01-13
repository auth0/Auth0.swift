public protocol MFAClient: SenderConstraining, Trackable, Loggable, Sendable {
    func getAuthenticators(mfaToken: String, factorsAllowed: [String]) -> Request<[Authenticator], AuthenticationError>

    func enroll(mfaToken: String, phoneNumber: String) -> Request<MFAEnrollmentChallenge, AuthenticationError>

    func challenge(with authenticatorId: String, mfaToken: String) -> Request<MFAChallenge, AuthenticationError>

    func verify(oobCode: String,
                bindingCode: String?,
                mfaToken: String) -> Request<Credentials, AuthenticationError>

    func enroll(mfaToken: String) -> Request<OTPMFAEnrollmentChallenge, AuthenticationError>

    func verify(otp: String,
                mfaToken: String) -> Request<Credentials, AuthenticationError>

    func verify(recoveryCode: String,
                mfaToken: String) -> Request<Credentials, AuthenticationError>

    func enroll(mfaToken: String) -> Request<PushMFAEnrollmentChallenge, AuthenticationError>

    func enroll(mfaToken: String, email: String) -> Request<MFAEnrollmentChallenge, AuthenticationError>
}
