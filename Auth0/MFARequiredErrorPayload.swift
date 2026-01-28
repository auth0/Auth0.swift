import Foundation

/// Represents the payload returned when multifactor authentication is required.
///
/// This structure contains the MFA token needed to complete the authentication flow
/// and the available enrollment options for MFA factors.
///
/// ## Usage
///
/// ```swift
/// if error.isMultifactorRequired, let mfaPayload = error.mfaRequiredErrorPayload {
///     let mfaToken = mfaPayload.mfaToken
///     let enrollmentTypes = mfaPayload.mfaRequirements.enroll.map { $0.type }
/// }
/// ```
///
/// ## See Also
///
/// - ``AuthenticationError/isMultifactorRequired``
/// - ``AuthenticationError/mfaRequiredErrorPayload``
public struct MFARequiredErrorPayload: Decodable, Sendable {
    
    /// The error code returned by Auth0 (e.g., "mfa_required").
    public let error: String
    
    /// A human-readable description of the error.
    public let errorDescription: String
    
    /// The MFA token required to complete the authentication flow.
    ///
    /// This token must be passed to subsequent MFA-related API calls to verify
    /// the second factor or complete enrollment.
    public let mfaToken: String
    
    /// The MFA requirements containing available enrollment options.
    public let mfaRequirements: MFARequirements
}

/// Represents the MFA requirements including enrollment options.
public struct MFARequirements: Decodable, Sendable {
    
    /// Array of available MFA enrollment types.
    ///
    /// Each element represents an MFA factor that can be enrolled,
    /// such as OTP, SMS, push notifications, or recovery codes.
    public let enroll: [MFAFactor]?
    public let challenge: [MFAFactor]?
}

/// Represents an MFA enrollment type option.
public struct MFAFactor: Decodable, Sendable, Hashable {
    
    /// The type of MFA factor available for enrollment.
    ///
    /// Common values include:
    /// - `"recovery-code"`: Recovery codes for account recovery
    /// - `"otp"`: Time-based one-time password (TOTP)
    /// - `"phone"`: SMS-based authentication
    /// - `"push-notification"`: Push notification-based authentication
    public let type: String
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }
}
