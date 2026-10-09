import Foundation

/// An identifier whose ownership must be verified with a one-time code before a passkey signup can complete.
///
/// Returned in ``PasskeySignupChallenge/verificationRequired`` and ``AuthenticationError/passkeyVerificationRequired``.
/// Use ``rawValue`` as the key when passing the collected codes in the `verification` dictionary of
/// ``Authentication/login(passkey:challenge:connection:audience:scope:organization:verification:)``.
///
/// ```swift
/// let verification = [PasskeyVerificationMethod.email.rawValue: emailCode]
/// ```
public enum PasskeyVerificationMethod: Sendable, Hashable {

    /// The user's email address.
    case email

    /// The user's phone number.
    case phone

    /// An identifier type not known to this version of the SDK. The associated value is the raw value returned by
    /// Auth0.
    case unknown(String)

}

extension PasskeyVerificationMethod: RawRepresentable {

    /// The value used by the Auth0 Authentication API, e.g. `"email"`.
    public var rawValue: String {
        switch self {
        case .email: return "email"
        case .phone: return "phone"
        case .unknown(let value): return value
        }
    }

    /// Creates a ``PasskeyVerificationMethod`` from the value used by the Auth0 Authentication API.
    ///
    /// - Parameter rawValue: The raw value, e.g. `"email"`. Unrecognized values map to ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "email": self = .email
        case "phone": self = .phone
        default: self = .unknown(rawValue)
        }
    }

}

extension PasskeyVerificationMethod: Decodable {

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

}
