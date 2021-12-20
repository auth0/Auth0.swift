#if WEB_AUTH_PLATFORM
import Foundation

/**
 *  Represents an error during a Web Authentication operation.
 */
public struct WebAuthError: Auth0Error {

    enum Code: Equatable {
        case noBundleIdentifier
        case invalidInvitationURL(String)
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

    /**
     The underlying `Error`, if any. Defaults to `nil`.
     */
    public let cause: Error?

    /**
     Description of the error.

     - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
     */
    public var debugDescription: String {
        switch self.code {
        case .noBundleIdentifier: return "Unable to retrieve the bundle identifier from Bundle.main.bundleIdentifier,"
            + " or it could not be used to build a valid URL."
        case .invalidInvitationURL(let url): return "The invitation URL (\(url)) is missing the 'invitation' and/or"
            + " the 'organization' query parameters."
        case .userCancelled: return "The user cancelled the Web Auth operation."
        case .pkceNotAllowed: return "Unable to complete authentication with PKCE."
            + " The correct method for Token Endpoint Authentication Method is not set (it should be 'None')."
            + " PKCE support needs to be enabled in the settings page of the Auth0 application, by setting the"
            + " 'ApplicationType' to 'Native' and the 'Token Endpoint Authentication Method' to 'None'."
        case .noAuthorizationCode(let values): return "The callback URL is missing the authorization code in its"
            + " query parameters (\(values))."
        case .idTokenValidationFailed: return "The ID Token validation performed after Web Auth login failed."
            + " The underlying error can be accessed via the 'cause' property."
        case .other: return "An error occurred. The 'Error' value can be accessed via the 'cause' property."
        case .unknown(let message): return message
        }
    }

    // MARK: - Error Cases

    /// The bundle identifier could not be retrieved from `Bundle.main.bundleIdentifier`, or it could not be used to
    /// build a valid URL. This error does not include a ``cause``.
    public static let noBundleIdentifier: WebAuthError = .init(code: .noBundleIdentifier)
    /// The invitation URL is missing the `invitation` and/or the `organization` query parameters.
    /// This error does not include a ``cause``.
    public static let invalidInvitationURL: WebAuthError = .init(code: .invalidInvitationURL(""))
    /// The user cancelled the Web Auth operation. This error does not include a ``cause``.
    public static let userCancelled: WebAuthError = .init(code: .userCancelled)
    /// The correct method for Token Endpoint Authentication Method is not set (it should be 'None').
    /// PKCE support needs to be enabled in the settings page of the Auth0 application, by setting the 'Application Type' to
    /// 'Native' and the 'Token Endpoint Authentication Method' to 'None'. This error does not include a ``cause``.
    public static let pkceNotAllowed: WebAuthError = .init(code: .pkceNotAllowed)
    /// The callback URL is missing the `code` query parameter. This error does not include a ``cause``.
    public static let noAuthorizationCode: WebAuthError = .init(code: .noAuthorizationCode([:]))
    /// The ID Token validation performed after Web Auth login failed.
    /// The underlying error can be accessed via the ``cause`` property.
    public static let idTokenValidationFailed: WebAuthError = .init(code: .idTokenValidationFailed)
    /// An error occurred. The `Error` value can be accessed via the ``cause`` property.
    public static let other: WebAuthError = .init(code: .other)
    /// An unknown error occurred, and an `Error` value is not available. This error does not include a ``cause``.
    public static let unknown: WebAuthError = .init(code: .unknown(""))

}

// MARK: - Equatable

extension WebAuthError: Equatable {

    /// Conformance to `Equatable`.
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
