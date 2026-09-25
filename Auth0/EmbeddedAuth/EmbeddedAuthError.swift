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

// MARK: - Authorize loop helpers

public extension EmbeddedAuthError {

    /// Whether the flow has more steps to complete (non-terminal).
    ///
    /// When `true`, read ``nextActions`` to know which step to present next.
    var isInsufficientAuthorization: Bool { code == "insufficient_authorization" }

    /// Whether the server terminated the flow without issuing a code.
    var isAccessDenied: Bool { code == "access_denied" }

    /// Whether the server terminated the flow because the OTP was entered wrong too many times (terminal — start over).
    var isTooManyWrongOtpAttempts: Bool {
        code == "access_denied" &&
        (info["error_description"] as? String) == "too_many_wrong_otp_attempts"
    }

    /// Whether the rate limit on login attempts has been hit.
    var isTooManyAttempts: Bool {
        code == "too_many_requests" &&
        (info["error_description"] as? String) == "too_many_attempts"
    }

    /// Whether the OTP or identifier code entered by the user is wrong but the session is still recoverable.
    var isInvalidCode: Bool {
        code == "insufficient_authorization" &&
        ["invalid_identifier_or_code", "invalid_code"].contains(info["error_description"] as? String ?? "")
    }

    /// Whether the OTP challenge has expired and a new challenge must be triggered.
    var isChallengeExpired: Bool {
        code == "access_denied" &&
        (info["error_description"] as? String) == "challenge_expired"
    }

    /// Whether the rate limit on logins has been hit.
    var isTooManyLogins: Bool {
        code == "too_many_requests" &&
        (info["error_description"] as? String) == "too_many_logins"
    }

    /// Typed menu of what the server will accept on the next call.
    ///
    /// Non-empty only when ``isInsufficientAuthorization`` is `true`.
    var nextActions: [NextAction] {
        guard let nextArray = info["next"] as? [[String: Any]] else { return [] }
        return nextArray.map { entry in
            guard let actionString = entry["action"] as? String else {
                return .unknown(rawAction: "")
            }
            switch EmbeddedAction(rawValue: actionString) {
            case .identifyEmail:  return .identifyEmail
            case .identifyPhone:  return .identifyPhone
            case .challengeEmail:
                return .challengeEmail(
                    index: entry["index"] as? Int ?? 0,
                    identifier: entry["identifier"] as? String
                )
            case .verifyOTP:
                return .verifyOTP(
                    channel: entry["channel"] as? String,
                    identifier: entry["identifier"] as? String
                )
            case .none:
                return .unknown(rawAction: actionString)
            }
        }
    }

}
