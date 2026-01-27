import Foundation

/**
 Represents an enrolled MFA authenticator for a user.

 An authenticator is a specific MFA factor that has been enrolled by the user, such as an SMS-enabled
 phone number, an authenticator app (TOTP), a push notification device, or an email address. Each
 authenticator has a unique identifier and status indicating whether it can be used for authentication.

 ## Authenticator Types

 Common authenticator types include:

 - **`oob`**: Out-of-band authenticators (SMS, push notifications, email)
 - **`otp`**: One-time password authenticators (TOTP apps like Google Authenticator)
 - **`recovery-code`**: Recovery codes for account recovery

 ## OOB Channels

 For out-of-band (`oob`) authenticators, the delivery method is specified:

 - **`sms`**: SMS text messages
 - **`auth0`**: Auth0 Guardian push notifications
 - **`email`**: Email delivery

 ## Properties

 - ``authenticatorType``: The type of MFA factor (e.g., `otp`, `oob`)
 - ``oobChannel``: The delivery channel for OOB authenticators (e.g., `sms`, `email`)
 - ``id``: Unique identifier for this authenticator instance
 - ``name``: Optional display name for the authenticator
 - ``active``: Whether this authenticator is currently active
 - ``type``: Additional type information about the authenticator

 ## See Also

 - ``MFAClient``
 - [MFA API Documentation](https://auth0.com/docs/api/authentication#multi-factor-authentication)
 - [Authenticate Using ROPG Flow with MFA](https://auth0.com/docs/secure/multi-factor-authentication/authenticate-using-ropg-flow-with-mfa)
 */
public struct Authenticator: Decodable, Hashable {
    
    /// The type of MFA authenticator.
    ///
    /// Common values are `"oob"` (out-of-band for SMS, push, email),
    /// `"otp"` (one-time password for TOTP apps), or `"recovery-code"`.
    public let authenticatorType: String
    
    /// The out-of-band channel used for this authenticator.
    ///
    /// Only populated for `oob` authenticator types. Possible values are
    /// `"sms"`, `"auth0"` (Guardian push), or `"email"`. Returns `nil`
    /// for non-OOB authenticators.
    public let oobChannel: String?
    
    /// The unique identifier for this authenticator instance.
    ///
    /// Used to reference this specific authenticator when initiating MFA challenges.
    /// Format typically follows the pattern `{type}|{id}`, such as `sms|dev_authenticator_id`.
    public let id: String
    
    /// An optional display name for the authenticator.
    ///
    /// Typically shows masked information like the last digits of a phone number
    /// (e.g., `"****0135"`) or a masked email address. May be `nil` if no display
    /// name is available.
    public let name: String?
    
    /// Indicates whether this authenticator is currently active.
    ///
    /// Only active authenticators can be used to complete MFA challenges.
    /// Inactive authenticators require re-enrollment.
    public let active: Bool
    
    /// Additional type information about the authenticator.
    ///
    /// Provides supplementary type classification beyond the primary `authenticatorType`.
    public let type: String

    enum CodingKeys: String, CodingKey {
        case authenticatorType = "authenticator_type"
        case oobChannel = "oob_channel"
        case type
        case name
        case active
        case id
    }

    /// Hashes the essential components of this authenticator.
    ///
    /// The hash is based solely on the authenticator's unique ``id``,
    /// as it uniquely identifies each authenticator instance.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
