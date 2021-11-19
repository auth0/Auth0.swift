import Foundation

/**
 *  Represents an error during a Credentials Manager operation
 */
public struct CredentialsManagerError: Auth0Error {

    enum Code: Equatable {
        case noCredentials
        case noRefreshToken
        case refreshFailed
        case biometricsFailed
        case revokeFailed
        case largeMinTTL
    }

    let code: Code
    let message: String?

    /**
     The underlying `Error`, if any
     */
    public let cause: Error?

    private init(code: Code, cause: Error?, message: String?) {
        self.code = code
        self.cause = cause
        self.message = message
    }

    init(code: Code) {
        self.init(code: code, cause: nil, message: nil)
    }

    init(code: Code, cause: Error) {
        self.init(code: code, cause: cause, message: cause.localizedDescription)
    }

    init(code: Code, message: String) {
        self.init(code: code, cause: nil, message: message)
    }

    /**
     Description of the error
     - important: You should avoid displaying description to the user, it's meant for debugging only.
     */
    public var localizedDescription: String {
        switch self.code { // TODO: Complete
        default: return self.cause?.localizedDescription ?? self.message ?? "Failed to perform webAuth"
        }
    }

    public static let noCredentials: CredentialsManagerError = .init(code: .noCredentials)
    public static let noRefreshToken: CredentialsManagerError = .init(code: .noRefreshToken)
    public static let refreshFailed: CredentialsManagerError = .init(code: .refreshFailed)
    public static let biometricsFailed: CredentialsManagerError = .init(code: .biometricsFailed)
    public static let revokeFailed: CredentialsManagerError = .init(code: .revokeFailed)
    public static let largeMinTTL: CredentialsManagerError = .init(code: .largeMinTTL)

}

// MARK: - Equatable

extension CredentialsManagerError: Equatable {

    public static func == (lhs: CredentialsManagerError, rhs: CredentialsManagerError) -> Bool {
        return lhs.code == rhs.code
            && lhs.cause?.localizedDescription == rhs.cause?.localizedDescription
            && lhs.message == rhs.message
    }

}

// MARK: - Pattern Matching Operator

extension CredentialsManagerError {

    public static func ~= (lhs: CredentialsManagerError, rhs: CredentialsManagerError) -> Bool {
        return lhs.code == rhs.code
    }

    public static func ~= (lhs: CredentialsManagerError, rhs: Error) -> Bool {
        guard let rhs = rhs as? CredentialsManagerError else { return false }
        return lhs.code == rhs.code
    }

}
