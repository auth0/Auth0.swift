import Foundation

/**
 Represents the response from enrolling a push notification authenticator (Auth0 Guardian).

 A push enrollment challenge is returned after successfully initiating the enrollment of Auth0 Guardian
 as an MFA factor. It contains the information needed to complete the Guardian enrollment, including
 the QR code URI for linking the Guardian app and recovery codes for account recovery.

 Push notification MFA allows users to approve or reject authentication requests directly from their
 enrolled mobile device via the Auth0 Guardian app, providing a passwordless MFA experience.

 ## Properties

 - ``authenticatorType``: The type of authenticator (always `"oob"` for push)
 - ``oobChannel``: The out-of-band channel (always `"auth0"` for Guardian push)
 - ``oobCode``: The identifier for this enrollment session
 - ``barcodeUri``: The URI for generating a QR code to link Guardian app
 - ``recoveryCodes``: One-time recovery codes for account recovery

 ## See Also

 - ``MFAClient``
 - ``MFAEnrollmentChallenge``
 - ``OTPMFAEnrollmentChallenge``
 - [Auth0 Guardian](https://auth0.com/docs/secure/multi-factor-authentication/auth0-guardian)
 - [MFA API Documentation](https://auth0.com/docs/api/authentication#multi-factor-authentication)
 */
public struct PushMFAEnrollmentChallenge: Decodable, Sendable {
    
    /// The type of MFA authenticator that was enrolled.
    ///
    /// For push notification enrollment challenges, this value is always `"oob"` (out-of-band),
    /// indicating that authentication requests are delivered out-of-band via push notifications.
    public let authenticatorType: String
    
    /// The out-of-band channel used for this enrollment.
    ///
    /// For Auth0 Guardian push notifications, this value is always `"auth0"`, distinguishing
    /// it from other OOB channels like `"sms"` or `"email"`.
    public let oobChannel: String
    
    /// The out-of-band code identifier for this enrollment session.
    ///
    /// This unique identifier represents the enrollment session and is used internally
    /// during the Guardian linking process.
    public let oobCode: String
    
    /// The URI for generating a QR code that links the Guardian app.
    ///
    /// This URI contains all necessary enrollment information and should be displayed as a QR code
    /// that users scan with the Auth0 Guardian mobile app to complete the enrollment process.
    /// The Guardian app will use this to establish a secure link with the Auth0 tenant.
    public let barcodeUri: String
    
    /// One-time recovery codes for account recovery.
    ///
    /// An optional array of recovery codes that can be used to authenticate when the user
    /// doesn't have access to their Guardian-enrolled device (e.g., lost phone, app uninstalled).
    ///
    /// These codes should be displayed to the user immediately after enrollment, stored securely
    /// by them (not in your application), and can only be used once each.
    public let recoveryCodes: [String]?

    enum CodingKeys: String, CodingKey {
        case authenticatorType = "authenticator_type"
        case oobChannel = "oob_channel"
        case oobCode = "oob_code"
        case barcodeUri = "barcode_uri"
        case recoveryCodes = "recovery_codes"
    }
}
