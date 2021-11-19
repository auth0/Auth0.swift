#if WEB_AUTH_PLATFORM
import Foundation

/**
 *  Represents an error during a Web Authentication operation
 */
public struct WebAuthError: Auth0Error {

    enum Code: Equatable {
        case noBundleIdentifier
        case malformedInvitationURL(String)
        case userCancelled
        case pkceNotAllowed
        case idTokenValidationFailed
        case other
        case unknown(String)
    }

    let code: Code

    init(code: Code, cause: Error? = nil) {
        self.code = code
        self.cause = cause
    }

    /**
     The underlying `Error`, if any
     */
    public let cause: Error?

    /**
     Description of the error
     - important: You should avoid displaying description to the user, it's meant for debugging only.
     */
    public var localizedDescription: String {
        if let description = self.cause?.localizedDescription { return description }

        switch self.code {
        case .noBundleIdentifier: return "Unable to retrieve the bundle identifier."
        case .malformedInvitationURL: return ""
        case .userCancelled: return "User cancelled Web Authentication."
        case .pkceNotAllowed: return "Unable to complete authentication with PKCE. PKCE support can be enabled by "
            + "setting Application Type to 'Native' and Token Endpoint Authentication Method to 'None' for this app "
            + "in the Auth0 Dashboard."
        default: return "Failed to perform Web Auth operation,"
        }
    }

    public static let noBundleIdentifier: WebAuthError = .init(code: .noBundleIdentifier)
    public static let malformedInvitationURL: WebAuthError = .init(code: .malformedInvitationURL(""))
    public static let userCancelled: WebAuthError = .init(code: .userCancelled)
    public static let pkceNotAllowed: WebAuthError = .init(code: .pkceNotAllowed)
    public static let idTokenValidationFailed: WebAuthError = .init(code: .idTokenValidationFailed)
    public static let other: WebAuthError = .init(code: .other)
    public static let unknown: WebAuthError = .init(code: .unknown(""))

}

// MARK: - Equatable

extension WebAuthError: Equatable {

    public static func == (lhs: WebAuthError, rhs: WebAuthError) -> Bool {
        return lhs.code == rhs.code && lhs.localizedDescription == rhs.localizedDescription
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
