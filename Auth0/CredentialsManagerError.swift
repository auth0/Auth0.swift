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

    public let cause: Error?

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

    public static let noCredentials: CredentialsManagerError = .init(code: .noCredentials)
    public static let noRefreshToken: CredentialsManagerError = .init(code: .noRefreshToken)
    public static let refreshFailed: CredentialsManagerError = .init(code: .refreshFailed)
    public static let biometricsFailed: CredentialsManagerError = .init(code: .biometricsFailed)
    public static let revokeFailed: CredentialsManagerError = .init(code: .revokeFailed)
    public static let largeMinTTL: CredentialsManagerError = .init(code: .largeMinTTL(minTTL: 0, lifetime: 0))

}

extension CredentialsManagerError: Equatable {

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
