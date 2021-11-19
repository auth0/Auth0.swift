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
        self.init(code: code, cause: cause, message: nil)
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
    public static func refreshFailed(_ error: Error) -> CredentialsManagerError { .init(code: .refreshFailed, cause: error) }
    public static func biometricsFailed(_ error: Error) -> CredentialsManagerError { .init(code: .biometricsFailed, cause: error) }
    public static func revokeFailed(_ error: Error) -> CredentialsManagerError { .init(code: .revokeFailed, cause: error) }

}

extension CredentialsManagerError: Equatable {

    public static func == (lhs: CredentialsManagerError, rhs: CredentialsManagerError) -> Bool {
        return lhs.code == rhs.code
    }

}
