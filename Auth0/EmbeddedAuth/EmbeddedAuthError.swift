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
    /// switch error.reason {
    /// case .insufficientAuthorization(_, let nextActions):
    ///     // Flow is live — present the first action's UI.
    /// case .network:
    ///     // Retry the same step.
    /// default:
    ///     // Terminal — start over with authorize().
    /// }
    /// ```
    var reason: EmbeddedAuthErrorReason {
        let desc = info["error_description"] as? String
        switch (statusCode, code, desc) {
        case (_, "insufficient_authorization", "invalid_code"):
            return .insufficientAuthorization(reason: .invalidCode, nextActions: parsedNextActions)
        case (_, "insufficient_authorization", "invalid_identifier_or_code"):
            return .insufficientAuthorization(reason: .invalidIdentifierOrCode, nextActions: parsedNextActions)
        case (_, "insufficient_authorization", "authorization_pending"):
            return .insufficientAuthorization(reason: .authorizationPending, nextActions: parsedNextActions)
        case (_, "insufficient_authorization", "slow_down"):
            return .insufficientAuthorization(reason: .slowDown, nextActions: parsedNextActions)
        case (_, "insufficient_authorization", _):
            return .insufficientAuthorization(reason: .none, nextActions: parsedNextActions)
        case (_, "access_denied", "too_many_wrong_otp_attempts"):
            return .tooManyWrongOtpAttempts
        case (_, "access_denied", "challenge_expired"):
            return .challengeExpired
        case (_, "access_denied", "authorization_rejected"):
            return .authorizationRejected
        case (_, "access_denied", "no_eligible_factors"):
            return .noEligibleFactors
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
        case (_, "invalid_request", _):
            return .invalidRequest
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
            case .identifyPhone:
                return .identifyPhone
            case .challengeEmail:
                guard let index = entry["index"] as? Int,
                      let identifier = entry["identifier"] as? String else { return nil }
                return .challengeEmail(index: index, identifier: identifier)
            case .challengePhone:
                guard let index = entry["index"] as? Int,
                      let identifier = entry["identifier"] as? String else { return nil }
                let rawMethods = entry["delivery_methods"] as? [String] ?? []
                let methods = rawMethods.compactMap { PhoneDeliveryMethod(rawValue: $0) }
                return .challengePhone(index: index, identifier: identifier, deliveryMethods: methods)
            case .challengePush:
                guard let index = entry["index"] as? Int,
                      let name = entry["name"] as? String else { return nil }
                return .challengePush(index: index, name: name)
            case .verifyOTP:
                guard let channelString = entry["channel"] as? String,
                      let channel = OtpChannel(rawValue: channelString.lowercased()) else { return nil }
                return .verifyOTP(channel: channel, identifier: entry["identifier"] as? String)
            case .verifyOob:
                guard let pollInMs = entry["poll_in_ms"] as? Int else { return nil }
                return .verifyOob(pollInMs: pollInMs)
            case .verifyRecoveryCode:
                return .verifyRecoveryCode
            case .confirmRecoveryCode:
                guard let newCode = entry["new_code"] as? String else { return nil }
                return .confirmRecoveryCode(newCode: newCode)
            case .none:
                return .unknown(rawAction: actionString)
            }
        }
    }

}
