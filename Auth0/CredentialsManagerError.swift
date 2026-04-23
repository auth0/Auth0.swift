import Foundation

/// Represents an error during a Credentials Manager operation.
public struct CredentialsManagerError: Auth0Error, Sendable {

    enum Code: Equatable {
        case noCredentials
        case noRefreshToken
        case renewFailed
        case apiExchangeFailed
        case ssoExchangeFailed
        case storeFailed
        case clearFailed
        case biometricsFailed
        case revokeFailed
        case unknown
        case largeMinTTL(minTTL: Int, lifetime: Int)
        case dpopKeyMissing
        case dpopKeyMismatch
        case dpopNotConfigured
    }

    let code: Code

    init(code: Code, cause: Error? = nil) {
        self.code = code
        self.cause = cause
    }

    /// The underlying `Error` value, if any. Defaults to `nil`.
    public let cause: Error?

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    public var debugDescription: String {
        self.appendCause(to: self.message)
    }

    // MARK: - Error Cases

    /// No credentials were found in the store.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let noCredentials: CredentialsManagerError = .init(code: .noCredentials)

    /// The stored ``Credentials`` instance does not contain a refresh token.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let noRefreshToken: CredentialsManagerError = .init(code: .noRefreshToken)

    /// The credentials renewal failed.
    /// The underlying ``AuthenticationError`` can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let renewFailed: CredentialsManagerError = .init(code: .renewFailed)

    /// The exchange of the refresh token for API credentials failed.
    /// The underlying ``AuthenticationError`` can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let apiExchangeFailed: CredentialsManagerError = .init(code: .apiExchangeFailed)

    /// The exchange of the refresh token for SSO credentials failed.
    /// The underlying ``AuthenticationError`` can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let ssoExchangeFailed: CredentialsManagerError = .init(code: .ssoExchangeFailed)

    /// Storing the renewed credentials failed.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let storeFailed: CredentialsManagerError = .init(code: .storeFailed)
    
    /// Clearing of credentials failed.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let clearFailed: CredentialsManagerError = .init(code: .clearFailed)

    /// The biometric authentication failed.
    /// The underlying `LAError` can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let biometricsFailed: CredentialsManagerError = .init(code: .biometricsFailed)

    /// The revocation of the refresh token failed.
    /// The underlying ``AuthenticationError`` can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let revokeFailed: CredentialsManagerError = .init(code: .revokeFailed)

    /// An unknown error occurred.
    /// The underlying `Error` can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let unknown: CredentialsManagerError = .init(code: .unknown)

    /// The `minTTL` requested is greater than the lifetime of the renewed access token. Request a lower `minTTL` or
    /// increase the **Token Expiration** value in the settings page of your [Auth0 API](https://manage.auth0.com/#/apis/).
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let largeMinTTL: CredentialsManagerError = .init(code: .largeMinTTL(minTTL: 0, lifetime: 0))

    /// The stored credentials are DPoP-bound but the DPoP key pair is no longer available in the Keychain.
    /// Stored credentials are cleared automatically when this error is returned.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let dpopKeyMissing: CredentialsManagerError = .init(code: .dpopKeyMissing)

    /// The stored credentials are DPoP-bound but the `Authentication` client used by this
    /// `CredentialsManager` was not configured with DPoP via `.useDPoP()`.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let dpopNotConfigured: CredentialsManagerError = .init(code: .dpopNotConfigured)

    /// The stored credentials are DPoP-bound but the current DPoP key pair does not match the one
    /// used when the credentials were saved.
    /// Stored credentials are cleared automatically when this error is returned.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let dpopKeyMismatch: CredentialsManagerError = .init(code: .dpopKeyMismatch)
}

// MARK: - Error Messages
public extension CredentialsManagerError {

    var message: String {
        switch self.code {
        case .noCredentials: return "No credentials were found in the store."
        case .noRefreshToken: return "The stored credentials instance does not contain a refresh token."
        case .renewFailed: return "The credentials renewal failed."
        case .apiExchangeFailed: return "The exchange of the refresh token for API credentials failed."
        case .ssoExchangeFailed: return "The exchange of the refresh token for SSO credentials failed."
        case .storeFailed: return "Storing the renewed credentials failed."
        case .clearFailed:
            return "Clearing of the credentials failed"
        case .biometricsFailed: return "The biometric authentication failed."
        case .revokeFailed: return "The revocation of the refresh token failed."
        case .unknown: return "An unknown error occurred."
        case .largeMinTTL(let minTTL, let lifetime): return "The minTTL requested (\(minTTL)s) is greater than the"
            + " lifetime of the renewed access token (\(lifetime)s). Request a lower minTTL or increase the"
            + " 'Token Expiration' value in the settings page of your Auth0 API."
        case .dpopKeyMissing:
            return "The stored credentials are DPoP-bound but the DPoP key pair is no longer available in the Keychain."
        case .dpopKeyMismatch:
            return "The stored credentials are DPoP-bound but the current DPoP key pair does not match the one"
            + " used when the credentials were saved."
        case .dpopNotConfigured:
            return "The stored credentials are DPoP-bound but the Authentication client used by this"
            + " CredentialsManager was not configured with DPoP via .useDPoP()."
        }
    }

}

// MARK: - Equatable

extension CredentialsManagerError: Equatable {

    /// Conformance to `Equatable`.
    public static func == (lhs: CredentialsManagerError, rhs: CredentialsManagerError) -> Bool {
        return lhs.code == rhs.code && lhs.localizedDescription == rhs.localizedDescription
    }

}

// MARK: - Pattern Matching Operator

public extension CredentialsManagerError {

    /// Matches `CredentialsManagerError` values in a switch statement.
    static func ~= (lhs: CredentialsManagerError, rhs: CredentialsManagerError) -> Bool {
        return lhs.code == rhs.code
    }

    /// Matches `Error` values in a switch statement.
    static func ~= (lhs: CredentialsManagerError, rhs: Error) -> Bool {
        guard let rhs = rhs as? CredentialsManagerError else { return false }
        return lhs.code == rhs.code
    }

}
