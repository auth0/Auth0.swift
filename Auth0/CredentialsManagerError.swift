import Foundation

/**
 *  Represents an error during a Credentials Manager operation.
 */
public struct CredentialsManagerError: Auth0Error {

    enum Code: Equatable {
        case noCredentials
        case noRefreshToken
        case refreshFailed
        case biometricsFailed
        case revokeFailed
        case largeMinTTL(minTTL: Int, lifetime: Int)
    }

    let code: Code

    init(code: Code, cause: Error? = nil) {
        self.code = code
        self.cause = cause
    }

    /**
     The underlying `Error`, if any. Defaults to `nil`.
     */
    public let cause: Error?

    /**
     Description of the error.

     - Important: You should avoid displaying the error description to the user, it's meant for debugging only.
     */
    public var debugDescription: String {
        switch self.code {
        case .noCredentials: return "No valid credentials found."
        case .noRefreshToken: return "No Refresh Token in the credentials."
        case .largeMinTTL(let minTTL, let lifetime): return "The minTTL requested (\(minTTL)s) is greater than the "
            + "lifetime of the renewed Access Token (\(lifetime)s). Request a lower minTTL or increase the "
            + "'Token Expiration' setting of your Auth0 API in the dashboard."
        default: return "Failed to perform Credentials Manager operation."
        }
    }

    // MARK: - Error Cases

    /// No credentials were found in the store. This error does not include a ``cause``.
    public static let noCredentials: CredentialsManagerError = .init(code: .noCredentials)
    /// The ``Credentials`` instance stored does not contain a Refresh Token. This error does not include a ``cause``.
    public static let noRefreshToken: CredentialsManagerError = .init(code: .noRefreshToken)
    /// The credentials renewal failed. The underlying ``AuthenticationError`` can be accessed via the `cause: Error?` property.
    public static let refreshFailed: CredentialsManagerError = .init(code: .refreshFailed)
    /// The Biometric authentication failed. The underlying `LAError` can be accessed via the ``cause`` property.
    public static let biometricsFailed: CredentialsManagerError = .init(code: .biometricsFailed)
    /// The revocation of the Refresh Token failed. The underlying ``AuthenticationError`` can be accessed via the
    /// ``cause`` property.
    public static let revokeFailed: CredentialsManagerError = .init(code: .revokeFailed)
    /// The `minTTL` requested is greater than the lifetime of the renewed Access Token. Request a lower `minTTL` or 
    /// increase the 'Token Expiration' setting of your Auth0 API in the Dashboard. This error does not include a ``cause``.
    public static let largeMinTTL: CredentialsManagerError = .init(code: .largeMinTTL(minTTL: 0, lifetime: 0))

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

    static func ~= (lhs: CredentialsManagerError, rhs: CredentialsManagerError) -> Bool {
        return lhs.code == rhs.code
    }

    static func ~= (lhs: CredentialsManagerError, rhs: Error) -> Bool {
        guard let rhs = rhs as? CredentialsManagerError else { return false }
        return lhs.code == rhs.code
    }

}
