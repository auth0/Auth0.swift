import Foundation

// MARK: - NextAction

/// A typed action the server will accept on the next ``EmbeddedAuth`` call.
public enum NextAction: Sendable, Equatable {

    /// Server expects the caller to submit an email address via ``EmbeddedAuth/identify(_:type:)``.
    case identifyEmail

    /// Server expects the caller to submit a phone number via ``EmbeddedAuth/identify(_:type:)``.
    case identifyPhone

    /// Server expects the caller to trigger an email OTP send via ``EmbeddedAuth/challengeEmail(index:)``.
    ///
    /// - Parameters:
    ///   - index:      Zero-based index of this entry in the server's `next` array; pass it back to ``EmbeddedAuth/challengeEmail(index:)``.
    ///   - identifier: Masked destination the server will deliver the OTP to (e.g. `"al**@example.com"`).
    case challengeEmail(index: Int, identifier: String)

    /// Server expects the caller to trigger a phone OTP challenge via ``EmbeddedAuth/challengePhone(index:deliveryMethod:)``.
    ///
    /// - Parameters:
    ///   - index:           Zero-based index identifying which phone authenticator to challenge.
    ///   - identifier:      Masked phone number (e.g. `"+1*****567"`).
    ///   - deliveryMethods: Delivery methods supported by this authenticator.
    case challengePhone(index: Int, identifier: String, deliveryMethods: [PhoneDeliveryMethod])

    /// Server expects the caller to trigger a push notification via ``EmbeddedAuth/challengePush(index:)``.
    ///
    /// - Parameters:
    ///   - index: Zero-based index identifying which push authenticator to challenge.
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

    /// Server expects a recovery code via ``EmbeddedAuth/verifyRecoveryCode(_:)``.
    case verifyRecoveryCode

    /// Server expects ``EmbeddedAuth/confirmRecoveryCode()`` to be called so the user can record their rotated recovery code.
    ///
    /// - Parameter newCode: The rotated recovery code the user must record before the flow continues.
    case confirmRecoveryCode(newCode: String)

    /// An action string the SDK does not recognise — preserved for forward compatibility.
    case unknown(rawAction: String)

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

    /// Submit a recovery code.
    case verifyRecoveryCode  = "action:verify:recovery-code:v1"

    /// Confirm the rotated recovery code has been recorded.
    case confirmRecoveryCode = "action:confirm:recovery-code:v1"

}

// MARK: - EmbeddedCapability

/// A capability the SDK advertises in the initial ``EmbeddedAuth/authorize(connection:capabilities:scope:audience:)`` call.
public enum EmbeddedCapability: Sendable, Equatable {

    /// SDK can identify a user by email.
    case identifyEmail

    /// SDK can identify a user by phone.
    case identifyPhone

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

    /// SDK can submit a recovery code.
    case verifyRecoveryCode

    /// SDK can confirm a rotated recovery code.
    case confirmRecoveryCode

    /// All capabilities this SDK version supports.
    public static let all: [EmbeddedCapability] = [
        .identifyEmail, .identifyPhone,
        .challengeEmail, .challengePhone, .challengePush,
        .verifyOTP, .verifyOob,
        .verifyRecoveryCode, .confirmRecoveryCode
    ]

    var action: EmbeddedAction {
        switch self {
        case .identifyEmail:       return .identifyEmail
        case .identifyPhone:       return .identifyPhone
        case .challengeEmail:      return .challengeEmail
        case .challengePhone:      return .challengePhone
        case .challengePush:       return .challengePush
        case .verifyOTP:           return .verifyOTP
        case .verifyOob:           return .verifyOob
        case .verifyRecoveryCode:  return .verifyRecoveryCode
        case .confirmRecoveryCode: return .confirmRecoveryCode
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
