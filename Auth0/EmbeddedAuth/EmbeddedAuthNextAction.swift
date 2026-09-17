import Foundation

// MARK: - NextAction

/// A typed action the server will accept on the next ``EmbeddedAuthClient`` call.
public enum NextAction: Sendable, Equatable {

    /// Server expects the caller to submit an email address via ``EmbeddedAuthClient/identifyEmail(_:)``.
    case identifyEmail

    /// Server expects the caller to submit a phone number via ``EmbeddedAuthClient/identifyPhone(_:)``.
    case identifyPhone

    /// Server expects the caller to trigger an email OTP send via ``EmbeddedAuthClient/challengeEmail(index:)``.
    case challengeEmail

    /// Server expects a one-time code via ``EmbeddedAuthClient/verifyOtp(_:type:)``.
    ///
    /// - Parameters:
    ///   - channel:    Delivery channel (e.g. `"email"`), if provided by the server.
    ///   - identifier: Masked destination (e.g. `"al**@example.com"`), if provided.
    case verifyOTP(channel: String?, identifier: String?)

    /// An action string the SDK does not recognise — preserved for forward compatibility.
    case unknown(rawAction: String)

}

// MARK: - EmbeddedAction

/// Wire strings used in request bodies and for parsing `next` menus.
public enum EmbeddedAction: String, Sendable, CaseIterable {

    /// Identify by email.
    case identifyEmail  = "action:identify:email:v1"

    /// Identify by phone number.
    case identifyPhone  = "action:identify:phone:v1"

    /// Request an email OTP challenge.
    case challengeEmail = "action:challenge:email:v1"

    /// Submit an OTP to verify identity.
    case verifyOTP      = "action:verify:otp:v1"

}

// MARK: - EmbeddedCapability

/// A capability the SDK advertises in the initial ``EmbeddedAuthClient/authorize(connection:capabilities:scope:audience:)`` call.
public enum EmbeddedCapability: Sendable, Equatable {

    /// SDK can identify a user by email.
    case identifyEmail

    /// SDK can identify a user by phone number.
    case identifyPhone

    /// SDK can trigger an email OTP challenge.
    case challengeEmail

    /// SDK can verify an OTP code.
    case verifyOTP

    /// All capabilities this SDK version supports.
    public static let all: [EmbeddedCapability] = [.identifyEmail, .identifyPhone, .challengeEmail, .verifyOTP]

    var action: EmbeddedAction {
        switch self {
        case .identifyEmail:  return .identifyEmail
        case .identifyPhone:  return .identifyPhone
        case .challengeEmail: return .challengeEmail
        case .verifyOTP:      return .verifyOTP
        }
    }

}

// MARK: - OtpType

/// The type of one-time password used in ``EmbeddedAuthClient/verifyOtp(_:type:)``.
public enum OtpType: String, Sendable {

    /// An out-of-band code delivered over email, SMS, or voice.
    case oob  = "oob"

    /// A time-based code from an authenticator app (TOTP).
    case totp = "totp"

}
