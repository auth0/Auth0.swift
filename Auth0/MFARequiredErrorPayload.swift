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
///     let enrollmentTypes = mfaPayload.mfaRequirements.enroll?.map { $0.type }
/// }
/// ```
///
/// ## See Also
///
/// - ``AuthenticationError/isMultifactorRequired``
/// - ``AuthenticationError/mfaRequiredErrorPayload``
public struct MFARequiredErrorPayload: Sendable {

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
    ///
    /// When the server does not include `mfa_requirements` in the response, defaults to an
    /// ``MFARequirements`` value where both ``MFARequirements/enroll`` and
    /// ``MFARequirements/challenge`` are `nil`.
    public let mfaRequirements: MFARequirements
}

extension MFARequiredErrorPayload: Decodable {

    private enum CodingKeys: String, CodingKey {
        case error
        case errorDescription
        case mfaToken
        case mfaRequirements
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.error = try container.decode(String.self, forKey: .error)
        self.errorDescription = try container.decode(String.self, forKey: .errorDescription)
        self.mfaToken = try container.decode(String.self, forKey: .mfaToken)
        self.mfaRequirements = try container.decodeIfPresent(MFARequirements.self, forKey: .mfaRequirements)
            ?? MFARequirements()
    }
}

/// Represents the MFA requirements including enrollment options.
public struct MFARequirements: Decodable, Sendable {

    /// Array of available MFA enrollment types.
    ///
    /// Each element represents an MFA factor that can be enrolled,
    /// such as OTP, SMS, push notifications, or recovery codes.
    public let enroll: [MFAFactor]?
    public let challenge: [MFAFactor]?

    init(enroll: [MFAFactor]? = nil, challenge: [MFAFactor]? = nil) {
        self.enroll = enroll
        self.challenge = challenge
    }
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
