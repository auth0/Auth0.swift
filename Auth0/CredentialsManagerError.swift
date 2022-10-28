import Foundation

/// Represents an error during a Credentials Manager operation.
public struct CredentialsManagerError: Auth0Error {

    enum Code: Equatable {
        case noCredentials
        case noRefreshToken
        case renewFailed
        case storeFailed
        case biometricsFailed
        case revokeFailed
        case largeMinTTL(minTTL: Int, lifetime: Int)
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

    /// Storing the renewed credentials failed.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let storeFailed: CredentialsManagerError = .init(code: .storeFailed)

    /// The biometric authentication failed.
    /// The underlying `LAError` can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let biometricsFailed: CredentialsManagerError = .init(code: .biometricsFailed)

    /// The revocation of the refresh token failed.
    /// The underlying ``AuthenticationError`` can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let revokeFailed: CredentialsManagerError = .init(code: .revokeFailed)

    /// The `minTTL` requested is greater than the lifetime of the renewed access token. Request a lower `minTTL` or 
    /// increase the **Token Expiration** value in the settings page of your [Auth0 API](https://manage.auth0.com/#/apis/).
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let largeMinTTL: CredentialsManagerError = .init(code: .largeMinTTL(minTTL: 0, lifetime: 0))

}

// MARK: - Error Messages

extension CredentialsManagerError {

    var message: String {
        switch self.code {
        case .noCredentials: return "No credentials were found in the store."
        case .noRefreshToken: return "The stored credentials instance does not contain a refresh token."
        case .renewFailed: return "The credentials renewal failed."
        case .storeFailed: return "Storing the renewed credentials failed."
        case .biometricsFailed: return "The biometric authentication failed."
        case .revokeFailed: return "The revocation of the refresh token failed."
        case .largeMinTTL(let minTTL, let lifetime): return "The minTTL requested (\(minTTL)s) is greater than the"
            + " lifetime of the renewed access token (\(lifetime)s). Request a lower minTTL or increase the"
            + " 'Token Expiration' value in the settings page of your Auth0 API."
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
