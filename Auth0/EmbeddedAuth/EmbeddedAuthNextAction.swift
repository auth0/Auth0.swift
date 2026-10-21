import Foundation

// MARK: - NextAction

/// A typed action the server will accept on the next ``EmbeddedAuth`` call.
public enum NextAction: Sendable, Equatable {

    /// Server expects the caller to submit an email address via ``EmbeddedAuth/identify(_:type:)``.
    case identifyEmail

    /// Server expects the caller to trigger an email OTP send via ``EmbeddedAuth/challengeEmail(index:)``.
    ///
    /// - Parameters:
    ///   - index:      Zero-based index of this entry in the server's `next` array; pass it back to ``EmbeddedAuth/challengeEmail(index:)``.
    ///   - identifier: Masked destination the server will deliver the OTP to (e.g. `"al**@example.com"`).
    case challengeEmail(index: Int, identifier: String)

    /// Server expects a one-time code via ``EmbeddedAuth/verifyOtp(_:type:)``.
    ///
    /// - Parameters:
    ///   - channel:    Delivery channel for the one-time password.
    ///   - identifier: Masked destination (e.g. `"al**@example.com"`), if provided.
    case verifyOTP(channel: OtpChannel, identifier: String?)

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

// MARK: - EmbeddedAction

/// Wire strings used in request bodies and for parsing `next` menus.
enum EmbeddedAction: String, Sendable, CaseIterable {

    /// Identify by email.
    case identifyEmail  = "action:identify:email:v1"

    /// Request an email OTP challenge.
    case challengeEmail = "action:challenge:email:v1"

    /// Submit an OTP to verify identity.
    case verifyOTP      = "action:verify:otp:v1"

}

// MARK: - EmbeddedCapability

/// A capability the SDK advertises in the initial ``EmbeddedAuth/authorize(connection:capabilities:scope:audience:)`` call.
public enum EmbeddedCapability: Sendable, Equatable {

    /// SDK can identify a user by email.
    case identifyEmail

    /// SDK can trigger an email OTP challenge.
    case challengeEmail

    /// SDK can verify an OTP code.
    case verifyOTP

    /// All capabilities this SDK version supports.
    public static let all: [EmbeddedCapability] = [.identifyEmail, .challengeEmail, .verifyOTP]

    var action: EmbeddedAction {
        switch self {
        case .identifyEmail:  return .identifyEmail
        case .challengeEmail: return .challengeEmail
        case .verifyOTP:      return .verifyOTP
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
