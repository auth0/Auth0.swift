import Foundation

/**
 Represents an MFA challenge issued to the user during the authentication flow.

 An MFA challenge contains the information needed to complete the verification process for a
 previously enrolled MFA factor, including the challenge identifier, type, and optional binding
 method for enhanced security.

 ## Properties

 - ``challengeType``: The type of challenge issued (e.g., `oob`, `otp`)
 - ``oobCode``: The unique identifier for this challenge session
 - ``bindingMethod``: Optional binding method for additional security verification

 ## See Also

 - ``MFAClient``
 - ``Authenticator``
 - ``MFAEnrollmentChallenge``
 - [MFA API Documentation](https://auth0.com/docs/api/authentication#multi-factor-authentication)
 - [Authenticate Using ROPG Flow with MFA](https://auth0.com/docs/secure/multi-factor-authentication/authenticate-using-ropg-flow-with-mfa)
 */
public struct MFAChallenge: Decodable {
    
    /// The type of MFA challenge issued.
    ///
    /// Indicates which MFA factor type was used to generate this challenge.
    /// Common values are `"oob"` (out-of-band) for SMS, email, and push notifications,
    /// or `"otp"` for time-based one-time password authenticators.
    public let challengeType: String
    
    /// The unique identifier for this challenge session.
    ///
    /// This value must be provided when verifying the challenge to complete the MFA authentication.
    /// It represents the challenge session, distinct from the actual verification code entered by the user.
    public let oobCode: String
    
    /// The binding method required for this challenge, if any.
    ///
    /// Indicates how additional verification is bound to this challenge.
    /// Common values are `"prompt"` (user must manually enter a code) or `"transfer"`
    /// (code is automatically transferred, typically for push notifications).
    /// A value of `nil` indicates no additional binding code is required.
    public let bindingMethod: String?

    enum CodingKeys: String, CodingKey {
        case challengeType = "challenge_type"
        case oobCode = "oob_code"
        case bindingMethod = "binding_method"
    }
}