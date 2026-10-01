import Foundation

/// Represents an error during a request to the Auth0 Embedded Authentication API.
public struct EmbeddedAuthError: Auth0APIError, @unchecked Sendable {

    /// Raw error values from the JSON response (or empty for bare HTTP errors).
    public let info: [String: Any]

    /// HTTP status code of the response.
    public let statusCode: Int

    /// Creates an error from a JSON response.
    ///
    /// - Parameters:
    ///   - info:       JSON response from Auth0.
    ///   - statusCode: HTTP status code of the response.
    public init(info: [String: Any], statusCode: Int) {
        self.info = info
        self.statusCode = statusCode
    }

    /// OAuth 2.0 error code from the `"error"` field.
    public var code: String {
        info["error"] as? String ?? unknownError
    }

    /// Whether the tenant `embedded_discovery` feature flag is off (bare `404` with no JSON body).
    public var isFeatureDisabled: Bool {
        statusCode == 404
    }

    /// Whether the request was malformed or per-client `embedded_discovery` is disabled (`invalid_request`).
    public var isInvalidRequest: Bool {
        code == "invalid_request"
    }

    /// Whether the `client_id` does not resolve for the tenant (`invalid_client`).
    public var isInvalidClient: Bool {
        code == "invalid_client"
    }

    /// A textual representation for debugging purposes.
    ///
    /// - Important: Do not show this to end users — it is for **debugging** only.
    public var debugDescription: String {
        appendCause(to: message)
    }

}

// MARK: - Error message

extension EmbeddedAuthError {

    var message: String {
        if let description = info["error_description"] as? String, !description.isEmpty {
            return appendPeriod(to: "\(code): \(description)")
        }
        if code == unknownError {
            return "Failed with unknown error: \(info)."
        }
        return appendPeriod(to: code)
    }

}

// MARK: - Equatable

extension EmbeddedAuthError: Equatable {

    /// Conformance to `Equatable`.
    public static func == (lhs: EmbeddedAuthError, rhs: EmbeddedAuthError) -> Bool {
        lhs.code == rhs.code && lhs.statusCode == rhs.statusCode
    }

}

// MARK: - Authorize loop classification

public extension EmbeddedAuthError {

    /// Strongly-typed classification of this error.
    ///
    /// Use an exhaustive `switch` to handle all cases:
    /// ```swift
    /// switch error.kind {
    /// case .insufficientAuthorization(let nextActions):
    ///     // Flow is live — present the first action's UI.
    /// case .network:
    ///     // Retry the same step.
    /// default:
    ///     // Terminal — start over with authorize().
    /// }
    /// ```
    ///
    /// > Note: Discovery errors (`isFeatureDisabled`, `isInvalidRequest`, `isInvalidClient`)
    /// > are not covered by `kind`; they remain as dedicated properties.
    var kind: EmbeddedAuthErrorKind {
        let desc = info["error_description"] as? String
        switch (statusCode, code, desc) {
        case (_, "insufficient_authorization", _):
            return .insufficientAuthorization(nextActions: parsedNextActions)
        case (_, "access_denied", "too_many_wrong_otp_attempts"):
            return .tooManyWrongOtpAttempts
        case (_, "access_denied", "challenge_expired"):
            return .challengeExpired
        case (_, "access_denied", _):
            return .accessDenied
        case (429, "too_many_requests", "too_many_attempts"):
            return .tooManyAttempts
        case (429, "too_many_requests", "too_many_logins"):
            return .tooManyLogins
        case (_, "invalid_grant", _):
            return .sessionExpired
        case (_, "no_active_session", _):
            return .noActiveSession
        default:
            return isNetworkError ? .network : .unknown
        }
    }

}

// MARK: - Private helpers

private extension EmbeddedAuthError {

    var parsedNextActions: [NextAction] {
        guard let nextArray = info["next"] as? [[String: Any]] else { return [] }
        return nextArray.compactMap { entry in
            guard let actionString = entry["action"] as? String else { return nil }
            switch EmbeddedAction(rawValue: actionString) {
            case .identifyEmail:
                return .identifyEmail
            case .challengeEmail:
                guard let index = entry["index"] as? Int,
                      let identifier = entry["identifier"] as? String else { return nil }
                return .challengeEmail(index: index, identifier: identifier)
            case .verifyOTP:
                guard let channelString = entry["channel"] as? String,
                      let channel = OtpChannel(rawValue: channelString.lowercased()) else { return nil }
                return .verifyOTP(channel: channel, identifier: entry["identifier"] as? String)
            case .none:
                return .unknown(rawAction: actionString)
            }
        }
    }

}
