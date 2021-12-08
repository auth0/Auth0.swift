#if WEB_AUTH_PLATFORM
import Foundation

/**
 *  Represents an error during a Web Authentication operation.
 */
public struct WebAuthError: Auth0Error {

    enum Code: Equatable {
        case noBundleIdentifier
        case malformedInvitationURL(String)
        case userCancelled
        case noAuthorizationCode([String: String])
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

    public let cause: Error?

    public var debugDescription: String {
        switch self.code {
        case .noBundleIdentifier: return "Unable to retrieve the bundle identifier."
        case .malformedInvitationURL(let url): return "The invitation URL (\(url)) is missing the required query "
            + "parameters 'invitation' and 'organization'."
        case .userCancelled: return "User cancelled Web Authentication."
        case .noAuthorizationCode(let values): return "No authorization code found in \(values)."
        case .pkceNotAllowed: return "Unable to complete authentication with PKCE. PKCE support can be enabled by "
            + "setting Application Type to 'Native' and Token Endpoint Authentication Method to 'None' for this app "
            + "in the Auth0 Dashboard."
        case .unknown(let message): return message
        default: return "Failed to perform Web Auth operation."
        }
    }

    public static let noBundleIdentifier: WebAuthError = .init(code: .noBundleIdentifier)
    public static let malformedInvitationURL: WebAuthError = .init(code: .malformedInvitationURL(""))
    public static let userCancelled: WebAuthError = .init(code: .userCancelled)
    public static let pkceNotAllowed: WebAuthError = .init(code: .pkceNotAllowed)
    public static let noAuthorizationCode: WebAuthError = .init(code: .noAuthorizationCode([:]))
    public static let idTokenValidationFailed: WebAuthError = .init(code: .idTokenValidationFailed)
    public static let other: WebAuthError = .init(code: .other)
    public static let unknown: WebAuthError = .init(code: .unknown(""))

}

extension WebAuthError: Equatable {

    public static func == (lhs: WebAuthError, rhs: WebAuthError) -> Bool {
        return lhs.code == rhs.code && lhs.localizedDescription == rhs.localizedDescription
    }

}

// MARK: - Pattern Matching Operator

public extension WebAuthError {

    static func ~= (lhs: WebAuthError, rhs: WebAuthError) -> Bool {
        return lhs.code == rhs.code
    }

    static func ~= (lhs: WebAuthError, rhs: Error) -> Bool {
        guard let rhs = rhs as? WebAuthError else { return false }
        return lhs.code == rhs.code
    }

}
#endif
