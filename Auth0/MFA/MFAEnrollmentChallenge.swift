import Foundation

/**
 Represents the response from enrolling an MFA factor.

 An MFA enrollment challenge contains the information needed to complete the enrollment process
 for out-of-band MFA factors (SMS, email, or push notifications), including the enrollment session
 identifier, binding method, delivery channel, and optional recovery codes.

 ## Properties

 - ``authenticatorType``: The type of authenticator that was enrolled
 - ``bindingMethod``: The verification method required to complete enrollment
 - ``recoveryCodes``: Optional one-time recovery codes for account recovery
 - ``oobChannel``: The delivery channel for the verification code
 - ``oobCode``: The unique identifier for this enrollment session

 ## See Also

 - ``MFAClient``
 - ``MFAChallenge``
 - ``OTPMFAEnrollmentChallenge``
 - ``PushMFAEnrollmentChallenge``
 - [MFA API Documentation](https://auth0.com/docs/api/authentication#multi-factor-authentication)
 - [Authenticate Using ROPG Flow with MFA](https://auth0.com/docs/secure/multi-factor-authentication/authenticate-using-ropg-flow-with-mfa)
 */
public struct MFAEnrollmentChallenge: Decodable {

    /// The type of MFA authenticator that was enrolled.
    ///
    /// Common values are `"oob"` (out-of-band) for SMS, email, and push notifications,
    /// or `"otp"` for time-based one-time password authenticators.
    public let authenticatorType: String

    /// The binding method required to complete the enrollment.
    ///
    /// Indicates how the verification code is delivered or bound to the enrollment.
    /// Common values are `"prompt"` (user must enter a code) or `"transfer"`
    /// (code is automatically transferred, typically for push notifications).
    public let bindingMethod: String

    /// Optional array of one-time recovery codes.
    ///
    /// These codes can be used to authenticate when the primary MFA factor is unavailable.
    /// Each code can only be used once and cannot be retrieved after the initial enrollment response.
    public let recoveryCodes: [String]?

    /// The out-of-band channel used for delivering the verification code.
    ///
    /// Possible values include `"sms"` (SMS text message), `"email"` (email delivery),
    /// or `"auth0"` (Auth0 Guardian push notification).
    public let oobChannel: String

    /// The unique identifier for this enrollment session.
    ///
    /// This value must be provided when verifying the enrollment to complete the MFA setup.
    public let oobCode: String

    enum CodingKeys: String, CodingKey {
        case authenticatorType = "authenticator_type"
        case bindingMethod = "binding_method"
        case recoveryCodes = "recovery_codes"
        case oobChannel = "oob_channel"
        case oobCode = "oob_code"
    }
}
