#if WEB_AUTH_PLATFORM
import Foundation

/// Represents an error during a Web Auth operation.
public struct WebAuthError: Auth0Error, Sendable {

    enum Code: Equatable {
        case webViewFailure(String)
        case noBundleIdentifier
        case transactionActiveAlready
        case userCancelled
        case authenticationFailed
        case codeExchangeFailed
        case noAuthorizationCode([String: String])
        case invalidRequestUri(String)
        case idTokenValidationFailed
        case credentialsManagerError
        case other
        case unknown(String)
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

    /// The bundle identifier could not be retrieved from `Bundle.main.bundleIdentifier`, or it could not be used to
    /// build a valid URL.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let noBundleIdentifier: WebAuthError = .init(code: .noBundleIdentifier)

    /// There is already an active transaction at the moment; therefore, this newly initiated transaction is canceled.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let transactionActiveAlready: WebAuthError = .init(code: .transactionActiveAlready)

    /// The user cancelled the Web Auth operation.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let userCancelled: WebAuthError = .init(code: .userCancelled)

    /// The callback URL contains an error returned by the authorization server.
    /// This occurs when authentication fails on the server side.
    /// The underlying ``AuthenticationError`` can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let authenticationFailed: WebAuthError = .init(code: .authenticationFailed)

    /// The authorization code exchange request failed.
    /// This occurs when the SDK cannot exchange the authorization code for tokens.
    /// The underlying ``AuthenticationError`` can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let codeExchangeFailed: WebAuthError = .init(code: .codeExchangeFailed)

    /// The callback URL is missing the `code` query parameter.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let noAuthorizationCode: WebAuthError = .init(code: .noAuthorizationCode([:]))

    /// The `request_uri` provided is invalid. It must start with `urn:ietf:params:oauth:request_uri:`.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let invalidRequestUri: WebAuthError = .init(code: .invalidRequestUri(""))

    /// The ID token validation performed after authentication failed.
    /// The underlying `Error` value can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let idTokenValidationFailed: WebAuthError = .init(code: .idTokenValidationFailed)

    /// The credentials manager failed to store or clear credentials.
    /// The underlying ``CredentialsManagerError`` can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let credentialsManagerError: WebAuthError = .init(code: .credentialsManagerError)

    /// An unexpected error occurred, and an `Error` value is available.
    /// The underlying `Error` value can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let other: WebAuthError = .init(code: .other)

    /// An unexpected error occurred, but an `Error` value is not available.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let unknown: WebAuthError = .init(code: .unknown(""))

}

// MARK: - Error Messages

public extension WebAuthError {

    var message: String {
        switch self.code {
        case .webViewFailure(let webViewFailureMessage): return webViewFailureMessage
        case .noBundleIdentifier: return "Unable to retrieve the bundle identifier from Bundle.main.bundleIdentifier,"
            + " or it could not be used to build a valid URL."
        case .transactionActiveAlready: return "Failed to start this transaction, as there is an active transaction at the"
            + " moment."
        case .userCancelled: return "The user cancelled the Web Auth operation."
        case .authenticationFailed: return "The authentication request failed."
        case .codeExchangeFailed: return "The authorization code exchange failed."
        case .noAuthorizationCode(let values): return "The callback URL is missing the authorization code in its"
            + " query parameters (\(values))."
        case .invalidRequestUri(let uri): return "The request_uri '\(uri)' is invalid."
            + " It must start with 'urn:ietf:params:oauth:request_uri:'."
        case .idTokenValidationFailed: return "The ID token validation performed after authentication failed."
        case .credentialsManagerError: return "The credentials manager failed to store or clear credentials."
        case .other: return "An unexpected error occurred."
        case .unknown(let message): return message
        }
    }

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

    /// Matches `WebAuthError` values in a switch statement.
    static func ~= (lhs: WebAuthError, rhs: WebAuthError) -> Bool {
        return lhs.code == rhs.code
    }

    /// Matches `Error` values in a switch statement.
    static func ~= (lhs: WebAuthError, rhs: Error) -> Bool {
        guard let rhs = rhs as? WebAuthError else { return false }
        return lhs.code == rhs.code
    }

}
#endif
