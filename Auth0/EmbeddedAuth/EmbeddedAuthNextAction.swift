import Foundation

// MARK: - NextAction

/// A typed action the server will accept on the next ``EmbeddedAuth`` call.
public enum NextAction: Sendable, Equatable {

    /// Server expects the caller to submit an email address via ``EmbeddedAuth/identify(_:type:)``.
    case identifyEmail

    /// Server expects the caller to submit a phone number via ``EmbeddedAuth/identify(_:type:)``.
    case identifyPhone

    /// Server expects the caller to submit a username via ``EmbeddedAuth/identify(_:type:)``.
    case identifyUsername

    /// Server expects the caller to trigger an email OTP send via ``EmbeddedAuth/challengeEmail(index:)``.
    ///
    /// - Parameters:
    ///   - index:      Zero-based position of this authenticator among the user's enrolled email authenticators.
    ///     Pass it back unchanged to ``EmbeddedAuth/challengeEmail(index:)``; it is not this entry's position in `nextActions`.
    ///   - identifier: Masked destination the server will deliver the OTP to (e.g. `"al**@example.com"`).
    case challengeEmail(index: Int, identifier: String)

    /// Server expects the caller to trigger a phone OTP challenge via ``EmbeddedAuth/challengePhone(index:deliveryMethod:)``.
    ///
    /// - Parameters:
    ///   - index:           Zero-based position of this authenticator among the user's enrolled phone authenticators.
    ///     Pass it back unchanged to ``EmbeddedAuth/challengePhone(index:deliveryMethod:)``; it is not this entry's position in `nextActions`.
    ///   - identifier:      Masked phone number (e.g. `"+1*****567"`).
    ///   - deliveryMethods: Delivery methods supported by this authenticator. Methods this SDK version does not
    ///     recognise are left out, so the list can be empty.
    case challengePhone(index: Int, identifier: String, deliveryMethods: [PhoneDeliveryMethod])

    /// Server expects the caller to trigger a push notification via ``EmbeddedAuth/challengePush(index:)``.
    ///
    /// - Parameters:
    ///   - index: Zero-based position of this authenticator among the user's enrolled push authenticators.
    ///     Pass it back unchanged to ``EmbeddedAuth/challengePush(index:)``; it is not this entry's position in `nextActions`.
    ///   - name:  Display name of the push authenticator (e.g. `"Diego's iPhone"`).
    case challengePush(index: Int, name: String)

    /// Server expects a one-time code via ``EmbeddedAuth/verifyOtp(_:type:)``.
    ///
    /// - Parameters:
    ///   - channel:    Delivery channel for the one-time password.
    ///   - identifier: Masked destination (e.g. `"al**@example.com"`), if provided.
    case verifyOTP(channel: OtpChannel, identifier: String?)

    /// Server expects ``EmbeddedAuth/verifyOob()`` to poll for push notification approval.
    ///
    /// - Parameter pollInMs: Milliseconds to wait before calling ``EmbeddedAuth/verifyOob()`` again.
    case verifyOob(pollInMs: Int)

    /// Server expects the user's password via ``EmbeddedAuth/verifyPassword(_:)``.
    case verifyPassword

    /// Server expects a recovery code via ``EmbeddedAuth/verifyRecoveryCode(_:)``.
    case verifyRecoveryCode

    /// Server expects ``EmbeddedAuth/confirmRecoveryCode()`` to be called so the user can record their rotated recovery code.
    ///
    /// - Parameter newCode: The rotated recovery code the user must record before the flow continues.
    case confirmRecoveryCode(newCode: String)

    /// Server offers to register a new user: call ``EmbeddedAuth/signup()`` if the user wants to create an account.
    ///
    /// Offered alongside the identify steps when the connection allows self-registration. Calling
    /// ``EmbeddedAuth/signup()`` does not create the account yet: the server answers with the steps needed to
    /// register (for example identifying the new user and verifying a one-time code). Once the user completes them,
    /// the server offers ``confirmSignup``.
    ///
    /// - Parameter identifiers: The identifiers the server accepts for registration, each flagged as required or optional.
    ///   Identifiers this SDK version does not recognise are left out, so the list can be empty.
    case signup(identifiers: [SignupIdentifier])

    /// Server expects ``EmbeddedAuth/confirmSignup()`` to be called to finish registration and sign the user in.
    case confirmSignup

    /// Server offers passkey sign-in: show the system passkey UI built from `options`, then call
    /// `verifyPasskey(_:)` with the resulting assertion.
    ///
    /// Offered in the first `nextActions`, alongside the identify steps. A passkey both identifies and verifies the
    /// user in one step. The offer is only valid until another step is submitted: after ``EmbeddedAuth/identify(_:type:)``
    /// it is gone, and only a new ``EmbeddedAuth/authorize(connection:capabilities:scope:audience:)`` offers it again.
    /// After ``EmbeddedAuthErrorReason/InsufficientAuthorization/invalidPasskey`` use the new options from the error,
    /// never the previous ones.
    ///
    /// `verifyPasskey(_:)` is only available on iOS 16.6+, macOS 13.5+ and visionOS 1.0+. On other platforms offer
    /// another entry from `nextActions`.
    ///
    /// - Parameter options: The WebAuthn request options sent by the server.
    case verifyPasskey(options: PasskeyRequestOptions)

    /// An action string the SDK does not recognise — preserved for forward compatibility.
    case unknown(rawAction: String)

}

// MARK: - SignupIdentifier

/// An identifier the server accepts when registering a new user, as offered by ``NextAction/signup(identifiers:)``.
public struct SignupIdentifier: Sendable, Equatable {

    /// The kind of identifier. Never ``IdentifierType/username``: the server does not offer username sign-up.
    public let type: IdentifierType

    /// Whether the server requires this identifier for registration.
    public let isRequired: Bool

    /// Creates a sign-up identifier description.
    ///
    /// - Parameters:
    ///   - type:       The kind of identifier.
    ///   - isRequired: Whether the server requires this identifier for registration.
    public init(type: IdentifierType, isRequired: Bool) {
        self.type = type
        self.isRequired = isRequired
    }

}

// MARK: - OtpChannel

/// The delivery channel for a one-time password.
public enum OtpChannel: String, Sendable, CaseIterable {
    /// Delivered via email.
    case email
    /// Delivered via SMS.
    case sms
    /// Delivered via voice call.
    case voice
    /// Time-based authenticator app code.
    case totp
}

// MARK: - PhoneDeliveryMethod

/// The delivery method for a phone OTP challenge.
public enum PhoneDeliveryMethod: String, Sendable, Equatable, CaseIterable {
    /// SMS text message.
    case text
    /// Voice call.
    case voice
}

// MARK: - EmbeddedAction

/// Wire strings used in request bodies and for parsing `next` menus.
enum EmbeddedAction: String, Sendable, CaseIterable {

    /// Identify by email.
    case identifyEmail  = "action:identify:email:v1"

    /// Identify by phone.
    case identifyPhone  = "action:identify:phone:v1"

    /// Identify by username.
    case identifyUsername = "action:identify:username:v1"

    /// Request an email OTP challenge.
    case challengeEmail = "action:challenge:email:v1"

    /// Request a phone OTP challenge.
    case challengePhone = "action:challenge:phone:v1"

    /// Request a push notification challenge.
    case challengePush  = "action:challenge:push:v1"

    /// Submit an OTP to verify identity.
    case verifyOTP      = "action:verify:otp:v1"

    /// Poll for push notification approval.
    case verifyOob      = "action:verify:oob:v1"

    /// Submit the user's password.
    case verifyPassword = "action:verify:password:v1"

    /// Submit a recovery code.
    case verifyRecoveryCode  = "action:verify:recovery-code:v1"

    /// Confirm the rotated recovery code has been recorded.
    case confirmRecoveryCode = "action:confirm:recovery-code:v1"

    /// Start registering a new user.
    case signup = "action:signup:v1"

    /// Confirm the registration and complete the flow.
    case confirmSignup = "action:signup:confirm:v1"

    /// Submit a passkey assertion to sign the user in.
    case verifyPasskey = "action:verify:passkey:v1"

}

// MARK: - EmbeddedCapability

/// A capability the SDK advertises in the initial ``EmbeddedAuth/authorize(connection:capabilities:scope:audience:)`` call.
public enum EmbeddedCapability: Sendable, Equatable {

    /// SDK can identify a user by email.
    case identifyEmail

    /// SDK can identify a user by phone.
    case identifyPhone

    /// SDK can identify a user by username.
    case identifyUsername

    /// SDK can trigger an email OTP challenge.
    case challengeEmail

    /// SDK can trigger a phone OTP challenge.
    case challengePhone

    /// SDK can trigger a push notification challenge.
    case challengePush

    /// SDK can verify an OTP code.
    case verifyOTP

    /// SDK can poll for push notification approval.
    case verifyOob

    /// SDK can verify a password.
    case verifyPassword

    /// SDK can submit a recovery code.
    case verifyRecoveryCode

    /// SDK can confirm a rotated recovery code.
    case confirmRecoveryCode

    /// SDK can start a sign-up.
    case signup

    /// SDK can confirm a sign-up.
    case confirmSignup

    /// SDK can verify a passkey.
    ///
    /// Included in ``all`` only where the SDK can act on it: iOS 16.6+, macOS 13.5+ and visionOS 1.0+.
    /// The server only offers a passkey on a custom domain, for a connection with passkey login enabled.
    case verifyPasskey

    /// All capabilities this SDK version supports on the current platform and OS version.
    ///
    /// Includes ``verifyPasskey`` only on iOS 16.6+, macOS 13.5+ and visionOS 1.0+ (checked at runtime), as the
    /// last entry. To turn passkey sign-in off, pass an explicit list without it, for example
    /// `EmbeddedCapability.all.filter { $0 != .verifyPasskey }`.
    public static var all: [EmbeddedCapability] {
        var capabilities: [EmbeddedCapability] = [
            .identifyEmail, .identifyPhone, .identifyUsername,
            .challengeEmail, .challengePhone, .challengePush,
            .verifyOTP, .verifyOob, .verifyPassword,
            .verifyRecoveryCode, .confirmRecoveryCode,
            .signup, .confirmSignup
        ]
        #if PASSKEYS_PLATFORM
        if #available(iOS 16.6, macOS 13.5, visionOS 1.0, *) {
            capabilities.append(.verifyPasskey)
        }
        #endif
        return capabilities
    }

    var action: EmbeddedAction {
        switch self {
        case .identifyEmail:       return .identifyEmail
        case .identifyPhone:       return .identifyPhone
        case .identifyUsername:    return .identifyUsername
        case .challengeEmail:      return .challengeEmail
        case .challengePhone:      return .challengePhone
        case .challengePush:       return .challengePush
        case .verifyOTP:           return .verifyOTP
        case .verifyOob:           return .verifyOob
        case .verifyPassword:      return .verifyPassword
        case .verifyRecoveryCode:  return .verifyRecoveryCode
        case .confirmRecoveryCode: return .confirmRecoveryCode
        case .signup:              return .signup
        case .confirmSignup:       return .confirmSignup
        case .verifyPasskey:       return .verifyPasskey
        }
    }

}

// MARK: - OtpType

/// The type of one-time password used in ``EmbeddedAuth/verifyOtp(_:type:)``.
public enum OtpType: String, Sendable {

    /// An out-of-band code delivered over email, SMS, or voice.
    case oob

    /// A time-based code from an authenticator app (TOTP).
    case totp

}
