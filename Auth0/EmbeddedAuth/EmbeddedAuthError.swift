import Foundation

/// Represents an error during a request to the Auth0 Embedded Authentication API.
public struct EmbeddedAuthError: Auth0APIError, @unchecked Sendable {

    /// Raw error values from the JSON response (or empty for bare HTTP errors).
    public let info: [String: Any]

    /// HTTP status code of the response.
    public let statusCode: Int

    /// The password requirement of the sign-up in progress, when the SDK knows it.
    ///
    /// Set by the client that runs the flow, never by the server response, and used to fill
    /// ``SignupPassword/isRequired`` when the `next` actions are parsed. Not part of equality.
    var signupPasswordRequirement: CredentialRequirement?

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

// MARK: - Sign-up password state

extension EmbeddedAuthError {

    /// A copy of this error that carries the password requirement of the sign-up in progress.
    func withSignupPasswordRequirement(_ requirement: CredentialRequirement?) -> EmbeddedAuthError {
        var copy = self
        copy.signupPasswordRequirement = requirement
        return copy
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
        case (_, "insufficient_authorization", "invalid_identifier_or_password"):
            return .insufficientAuthorization(reason: .invalidIdentifierOrPassword, nextActions: parsedNextActions)
        case (_, "insufficient_authorization", "authorization_pending"):
            return .insufficientAuthorization(reason: .authorizationPending, nextActions: parsedNextActions)
        case (_, "insufficient_authorization", "slow_down"):
            return .insufficientAuthorization(reason: .slowDown, nextActions: parsedNextActions)
        case (_, "insufficient_authorization", "password_required"):
            return .insufficientAuthorization(reason: .passwordRequired, nextActions: parsedNextActions)
        case (_, "insufficient_authorization", "password_not_accepted"):
            return .insufficientAuthorization(reason: .passwordNotAccepted, nextActions: parsedNextActions)
        case (_, "insufficient_authorization", "invalid_password"):
            return .insufficientAuthorization(reason: .invalidPassword, nextActions: parsedNextActions)
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
        case (_, "access_denied", "consent_required"):
            return .consentRequired
        case (_, "access_denied", "no_next_steps"):
            return .noNextSteps
        case (_, "access_denied", "password_leaked"):
            return .passwordLeaked
        case (_, "access_denied", _):
            return .accessDenied
        case (429, "too_many_requests", "too_many_attempts"):
            return .tooManyAttempts
        case (429, "too_many_requests", "too_many_logins"):
            return .tooManyLogins
        case (_, "too_many_requests", "ip_blocked"):
            return .ipBlocked
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
            case .identifyUsername:
                return .identifyUsername
            case .challengeEmail:
                guard let index = entry["index"] as? Int,
                      let identifier = entry["identifier"] as? String else { return nil }
                return .challengeEmail(index: index, identifier: identifier)
            case .challengePhone:
                guard let index = entry["index"] as? Int,
                      let identifier = entry["identifier"] as? String,
                      let rawMethods = entry["delivery_methods"] as? [String] else { return nil }
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
            case .verifyPassword:
                return .verifyPassword
            case .verifyRecoveryCode:
                return .verifyRecoveryCode
            case .confirmRecoveryCode:
                guard let newCode = entry["new_code"] as? String else { return nil }
                return .confirmRecoveryCode(newCode: newCode)
            case .signup:
                guard let identifiers = entry["identifiers"] as? [String: Any] else { return nil }
                return .signup(identifiers: Self.signupIdentifiers(from: identifiers),
                               passwordRequirement: Self.passwordRequirement(from: entry))
            case .confirmSignup:
                return confirmSignupAction(from: entry)
            case .none:
                return .unknown(rawAction: actionString)
            }
        }
    }

    /// Reads `authentication_methods.password.required` of a sign-up entry.
    ///
    /// Anything the SDK cannot read as a boolean flag on a `password` object means the connection does not collect
    /// a password.
    static func passwordRequirement(from entry: [String: Any]) -> CredentialRequirement {
        guard let methods = entry["authentication_methods"] as? [String: Any],
              let password = methods["password"] as? [String: Any],
              let isRequired = password["required"] as? Bool else { return .none }
        return isRequired ? .required : .optional
    }

    /// Maps a confirm-sign-up entry.
    ///
    /// Without `password_complexity_options` the connection does not collect a password. Options that cannot be read
    /// (not an object, or no integer `min_length`) drop the entry, like any other entry the SDK cannot parse.
    func confirmSignupAction(from entry: [String: Any]) -> NextAction? {
        guard let rawOptions = entry["password_complexity_options"] else { return .confirmSignup(password: nil) }
        guard let options = rawOptions as? [String: Any],
              let minLength = options["min_length"] as? Int else { return nil }
        let complexity = SignupPasswordComplexity(minLength: minLength,
                                                  characterTypes: Self.characterTypes(from: options))
        // Only an optional password can be skipped; unknown means the sign-up offer was never seen, so assume required.
        let isRequired = signupPasswordRequirement != CredentialRequirement.optional
        return .confirmSignup(password: SignupPassword(isRequired: isRequired, complexity: complexity))
    }

    /// Reads `character_types`, leaving out unknown values and duplicates and keeping the server's order.
    static func characterTypes(from options: [String: Any]) -> [SignupPasswordComplexity.CharacterType] {
        guard let raw = options["character_types"] as? [Any] else { return [] }
        var types: [SignupPasswordComplexity.CharacterType] = []
        for case let value as String in raw {
            if let type = SignupPasswordComplexity.CharacterType(rawValue: value), !types.contains(type) {
                types.append(type)
            }
        }
        return types
    }

    /// Maps the `identifiers` object of a sign-up entry, in a fixed order (email, then phone).
    ///
    /// Keys the SDK does not recognise, and keys whose `required` flag cannot be read as a boolean, are left out.
    /// Numbers follow Swift's bridging rules, so `0` and `1` are read as `false` and `true`.
    static func signupIdentifiers(from identifiers: [String: Any]) -> [SignupIdentifier] {
        [("email", IdentifierType.email), ("phone_number", IdentifierType.phone)].compactMap { key, type in
            guard let details = identifiers[key] as? [String: Any],
                  let isRequired = details["required"] as? Bool else { return nil }
            return SignupIdentifier(type: type, isRequired: isRequired)
        }
    }

}
