import Foundation

/**
 Represents the response from enrolling a TOTP (Time-based One-Time Password) authenticator.

 An OTP enrollment challenge is returned after successfully initiating the enrollment of a TOTP
 authenticator app (such as Google Authenticator, Authy, or 1Password). It contains the information
 needed to set up the authenticator app, including the secret key and QR code URI.

 This response provides both a machine-readable QR code URI and a human-readable secret for
 flexible enrollment options.

 ## Properties

 - ``authenticatorType``: The type of authenticator (always `"otp"` for TOTP)
 - ``secret``: The shared secret key for manual entry
 - ``barcodeUri``: The URI for generating a QR code
 - ``recoveryCodes``: One-time recovery codes for account recovery

 ## See Also

 - ``MFAClient``
 - ``MFAEnrollmentChallenge``
 - ``PushMFAEnrollmentChallenge``
 - [MFA API Documentation](https://auth0.com/docs/api/authentication#multi-factor-authentication)
 - [Authenticate Using ROPG Flow with MFA](https://auth0.com/docs/secure/multi-factor-authentication/authenticate-using-ropg-flow-with-mfa)
 - [Key URI Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format)
 */
public struct OTPMFAEnrollmentChallenge: Decodable {
    
    /// The type of MFA authenticator that was enrolled.
    ///
    /// For TOTP enrollment challenges, this value is always `"otp"`, indicating that a
    /// time-based one-time password authenticator is being enrolled.
    public let authenticatorType: String
    
    /// The shared secret key for the TOTP authenticator.
    ///
    /// This Base32-encoded secret is used by the authenticator app to generate time-based
    /// one-time passwords. It should be displayed to users who prefer manual entry over
    /// scanning QR codes, and must be kept confidential.
    public let secret: String
    
    /// The URI for generating a QR code that can be scanned by authenticator apps.
    ///
    /// This URI follows the [Key URI Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format)
    /// standard (`otpauth://totp/...`) and contains all necessary information for the authenticator
    /// app, including the account name, issuer, and secret key.
    public let barcodeUri: String
    
    /// One-time recovery codes for account recovery.
    ///
    /// An optional array of recovery codes that can be used to authenticate when the user
    /// doesn't have access to their authenticator app. These codes should be displayed to
    /// the user immediately, can only be used once each, and cannot be retrieved again
    /// after enrollment.
    public let recoveryCodes: [String]?

    enum CodingKeys: String, CodingKey {
        case authenticatorType = "authenticator_type"
        case secret
        case barcodeUri = "barcode_uri"
        case recoveryCodes = "recovery_codes"
    }
}