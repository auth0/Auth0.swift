import Foundation

/**
 Client for the [Auth0 Multifactor Authentication API](https://auth0.com/docs/api/authentication#multi-factor-authentication).

 ## See Also

 - ``AuthenticationError``
 - [MFA API Documentation](https://auth0.com/docs/secure/multi-factor-authentication)
 */
public protocol MFAClient: SenderConstraining, Trackable, Loggable, Sendable {

    // MARK: - Authenticators

    /**
     Retrieves the list of available authenticators for the user.

     This endpoint returns all available authenticators that the user can use for MFA enrollment,
     filtered by the specified factor types.

     ## Usage

     ```swift
     Auth0
         .mfa()
         .getAuthenticators(mfaToken: "MFA_TOKEN", factorsAllowed: ["otp", "oob"])
         .start { result in
             switch result {
             case .success(let authenticators):
                 print("Available authenticators: \(authenticators)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     - Parameters:
       - mfaToken: The MFA token received from an authentication error when MFA is required.
       - factorsAllowed: Array of factor types to filter the authenticators (e.g., `["otp", "oob", "push-notification"]`).
     - Returns: A request that will yield an array of available authenticators.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#list-authenticators)
     */
    func getAuthenticators(mfaToken: String, factorsAllowed: [String]) -> Request<[Authenticator], AuthenticationError>

    // MARK: - Phone (SMS) Enrollment

    /**
     Enrolls a phone number for SMS-based MFA.

     This method initiates the enrollment of a phone number as an MFA factor. An SMS with a verification
     code will be sent to the specified phone number.

     ## Usage

     ```swift
     Auth0
         .mfa()
         .enroll(mfaToken: "MFA_TOKEN", phoneNumber: "+12025550135")
         .start { result in
             switch result {
             case .success(let challenge):
                 print("Enrollment initiated: \(challenge)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     - Parameters:
       - mfaToken: The MFA token received from an authentication error when MFA is required.
       - phoneNumber: The phone number to enroll, including country code (e.g., `+12025550135`).
     - Returns: A request that will yield an MFA enrollment challenge.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#enroll-and-challenge-a-sms-or-voice-authenticator)
     */
    func enroll(mfaToken: String, phoneNumber: String) -> Request<MFAEnrollmentChallenge, AuthenticationError>

    // MARK: - Challenge

    /**
     Initiates an MFA challenge for an enrolled authenticator.

     This method requests a challenge (e.g., OTP code via SMS) for an already enrolled MFA factor.
     The user must complete the challenge to authenticate successfully.

     ## Usage

     ```swift
     Auth0
         .mfa()
         .challenge(with: "sms|dev_authenticator_id", mfaToken: "MFA_TOKEN")
         .start { result in
             switch result {
             case .success(let challenge):
                 print("Challenge sent: \(challenge)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     - Parameters:
       - authenticatorId: The ID of the enrolled authenticator.
       - mfaToken: The MFA token received from an authentication error when MFA is required.
     - Returns: A request that will yield an MFA challenge.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#challenge-with-sms-oob-otp)
     */
    func challenge(with authenticatorId: String, mfaToken: String) -> Request<MFAChallenge, AuthenticationError>

    // MARK: - OOB Verification

    /**
     Verifies an out-of-band (OOB) MFA challenge using a code received via SMS or email.

     This method completes the MFA authentication flow by verifying the OTP code sent to the user's
     phone or email. Upon successful verification, user credentials are returned.

     ## Usage

     ```swift
     Auth0
         .mfa()
         .verify(oobCode: "123456", bindingCode: nil, mfaToken: "MFA_TOKEN")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     With binding code (for enhanced security):

     ```swift
     Auth0
         .mfa()
         .verify(oobCode: "oob_code", bindingCode: "BINDING_CODE", mfaToken: "MFA_TOKEN")
         .start { print($0) }
     ```

     - Parameters:
       - oobCode: The out-of-band code received via SMS or email.
       - bindingCode: Optional binding code for additional security verification.
       - mfaToken: The MFA token received from an authentication error when MFA is required.
     - Returns: A request that will yield Auth0 user's credentials.
     - Requires: MFA OOB Grant `http://auth0.com/oauth/grant-type/mfa-oob`.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#verify-with-out-of-band-oob)
     */
    func verify(oobCode: String,
                bindingCode: String?,
                mfaToken: String) -> Request<Credentials, AuthenticationError>

    // MARK: - OTP Enrollment

    /**
     Enrolls a time-based one-time password (TOTP) authenticator for MFA.

     This method initiates the enrollment of an authenticator app (like Google Authenticator or Authy)
     as an MFA factor. It returns a challenge containing a QR code and secret that can be scanned
     by the authenticator app.

     ## Usage

     ```swift
     Auth0
         .mfa()
         .enroll(mfaToken: "MFA_TOKEN")
         .start { result in
             switch result {
             case .success(let challenge):
                 print("QR Code URI: \(challenge.barcode ?? "N/A")")
                 print("Secret: \(challenge.secret ?? "N/A")")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     - Parameter mfaToken: The MFA token received from an authentication error when MFA is required.
     - Returns: A request that will yield an OTP MFA enrollment challenge containing QR code and secret.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#enroll-and-challenge-a-otp-authenticator)
     */
    func enroll(mfaToken: String) -> Request<OTPMFAEnrollmentChallenge, AuthenticationError>

    // MARK: - OTP Verification

    /**
     Verifies an MFA challenge using a one-time password (OTP) code.

     This method completes the MFA authentication flow by verifying the OTP code from the user's
     authenticator app. Upon successful verification, user credentials are returned.

     ## Usage

     ```swift
     Auth0
         .mfa()
         .verify(otp: "123456", mfaToken: "MFA_TOKEN")
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
       - otp: The 6-digit one-time password code from the authenticator app.
       - mfaToken: The MFA token received from an authentication error when MFA is required.
     - Returns: A request that will yield Auth0 user's credentials.
     - Requires: MFA OTP Grant `http://auth0.com/oauth/grant-type/mfa-otp`.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#verify-with-one-time-password-otp)
     */
    func verify(otp: String,
                mfaToken: String) -> Request<Credentials, AuthenticationError>

    // MARK: - Recovery Code Verification

    /**
     Verifies an MFA challenge using a recovery code.

     This method allows users to authenticate when they don't have access to their primary MFA factor.
     Recovery codes are typically provided during MFA enrollment and should be stored securely.

     ## Usage

     ```swift
     Auth0
         .mfa()
         .verify(recoveryCode: "RECOVERY_CODE_123", mfaToken: "MFA_TOKEN")
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
       - recoveryCode: The recovery code provided during MFA enrollment.
       - mfaToken: The MFA token received from an authentication error when MFA is required.
     - Returns: A request that will yield Auth0 user's credentials.
     - Requires: MFA Recovery Code Grant `http://auth0.com/oauth/grant-type/mfa-recovery-code`.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#verify-with-recovery-code)
     */
    func verify(recoveryCode: String,
                mfaToken: String) -> Request<Credentials, AuthenticationError>

    // MARK: - Push Notification Enrollment

    /**
     Enrolls push notification as an MFA factor.

     This method initiates the enrollment of Auth0 Guardian push notifications as an MFA factor.
     Users will receive authentication requests via push notifications on their enrolled device.

     ## Usage

     ```swift
     Auth0
         .mfa()
         .enroll(mfaToken: "MFA_TOKEN")
         .start { result in
             switch result {
             case .success(let challenge):
                 print("Push enrollment challenge: \(challenge)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     - Parameter mfaToken: The MFA token received from an authentication error when MFA is required.
     - Returns: A request that will yield a push MFA enrollment challenge.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#enroll-and-challenge-push-notifications)
     - [Auth0 Guardian](https://auth0.com/docs/secure/multi-factor-authentication/auth0-guardian)
     */
    func enroll(mfaToken: String) -> Request<PushMFAEnrollmentChallenge, AuthenticationError>

    // MARK: - Email Enrollment

    /**
     Enrolls an email address for email-based MFA.

     This method initiates the enrollment of an email address as an MFA factor. Verification codes
     will be sent to the specified email address during authentication.

     ## Usage

     ```swift
     Auth0
         .mfa()
         .enroll(mfaToken: "MFA_TOKEN", email: "user@example.com")
         .start { result in
             switch result {
             case .success(let challenge):
                 print("Email enrollment challenge: \(challenge)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     - Parameters:
       - mfaToken: The MFA token received from an authentication error when MFA is required.
       - email: The email address to enroll for MFA.
     - Returns: A request that will yield an MFA enrollment challenge.

     ## See Also

     - [Authentication API Endpoint](https://auth0.com/docs/api/authentication#enroll-and-challenge-a-email-authenticator)
     */
    func enroll(mfaToken: String, email: String) -> Request<MFAEnrollmentChallenge, AuthenticationError>

}
