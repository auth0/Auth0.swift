#if WEB_AUTH_PLATFORM
import Foundation

/**
 *  Represents an error during a Web Authentication operation
 */
public struct WebAuthError: Auth0Error {

    enum Code: Equatable {
        case noBundleIdentifier
        case userCancelled
        case missingAccessToken
        case pkceNotAllowed
        case idTokenValidationFailed
        case other
        case unknown
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
        switch self.code {
        case .userCancelled: return "User cancelled Web Authentication"
        case .pkceNotAllowed: return "Unable to complete authentication with PKCE. "
            + "PKCE support can be enabled by setting Application Type to 'Native' "
            + "and Token Endpoint Authentication Method to 'None' for this app in the Auth0 Dashboard."
        case .missingAccessToken: return "Could not validate the token"
        default: return self.cause?.localizedDescription ?? self.message ?? "Failed to perform webAuth"
        }
    }

    public static let noBundleIdentifier: WebAuthError = .init(code: .noBundleIdentifier)
    public static let userCancelled: WebAuthError = .init(code: .userCancelled)
    public static let missingAccessToken: WebAuthError = .init(code: .missingAccessToken)
    public static let pkceNotAllowed: WebAuthError = .init(code: .pkceNotAllowed)
    public static let idTokenValidationFailed: WebAuthError = .init(code: .idTokenValidationFailed)
    public static let other: WebAuthError = .init(code: .other)
    public static let unknown: WebAuthError = .init(code: .unknown)

}

// MARK: - Equatable

extension WebAuthError: Equatable {

    public static func == (lhs: WebAuthError, rhs: WebAuthError) -> Bool {
        return lhs.code == rhs.code
            && lhs.cause?.localizedDescription == rhs.cause?.localizedDescription
            && lhs.message == rhs.message
    }

}

// MARK: - Pattern Matching Operator

extension WebAuthError {

    public static func ~= (lhs: WebAuthError, rhs: WebAuthError) -> Bool {
        return lhs.code == rhs.code
    }

    public static func ~= (lhs: WebAuthError, rhs: Error) -> Bool {
        guard let rhs = rhs as? WebAuthError else { return false }
        return lhs.code == rhs.code
    }

}
#endif
