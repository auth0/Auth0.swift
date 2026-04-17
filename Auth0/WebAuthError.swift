#if WEB_AUTH_PLATFORM
import Foundation

/// Represents an error during a Web Auth operation.
public struct WebAuthError: Auth0Error, Sendable {

    enum Code: Equatable {
        case webViewFailure(String)
        case transactionActiveAlready
        case userCancelled
        case authenticationFailed
        case codeExchangeFailed
        case idTokenValidationFailed
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

    /// The ID token validation performed after authentication failed.
    /// The underlying `Error` value can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let idTokenValidationFailed: WebAuthError = .init(code: .idTokenValidationFailed)

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
        case .transactionActiveAlready: return "Failed to start this transaction, as there is an active transaction at the"
            + " moment."
        case .userCancelled: return "The user cancelled the Web Auth operation."
        case .authenticationFailed: return "The authentication request failed."
        case .codeExchangeFailed: return "The authorization code exchange failed."
        case .idTokenValidationFailed: return "The ID token validation performed after authentication failed."
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
