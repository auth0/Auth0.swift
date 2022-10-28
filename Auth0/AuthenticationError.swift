import Foundation

/// Represents an error during a request to the Auth0 Authentication API.
///
/// ## See Also
///
/// - [Standard Error Responses](https://auth0.com/docs/api/authentication#standard-error-responses)
public struct AuthenticationError: Auth0APIError {

    /// Additional information about the error.
    public let info: [String: Any]

    /// Creates an error from a JSON response.
    ///
    /// - Parameters:
    ///   - info:       JSON response from Auth0.
    ///   - statusCode: HTTP status code of the response.
    ///
    /// - Returns: A new `AuthenticationError`.
    public init(info: [String: Any], statusCode: Int) {
        var values = info
        values["statusCode"] = statusCode
        self.info = values
        self.statusCode = statusCode
    }

    /// HTTP status code of the response.
    public let statusCode: Int

    /// The underlying `Error` value, if any. Defaults to `nil`.
    public var cause: Error? {
        return self.info["cause"] as? Error
    }

    /// The code of the error as a string.
    public var code: String {
        let code = self.info["error"] ?? self.info["code"]
        return code as? String ?? unknownError
    }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    public var debugDescription: String {
        self.appendCause(to: self.message)
    }

    // MARK: - Error Types

    /// When MFA is required to authenticate.
    public var isMultifactorRequired: Bool {
        return self.code == "a0.mfa_required" || self.code == "mfa_required"
    }

    /// When MFA is required and the user is not enrolled.
    public var isMultifactorEnrollRequired: Bool {
        return self.code == "a0.mfa_registration_required" || self.code == "unsupported_challenge_type"
    }

    /// When the MFA code sent is invalid or expired.
    public var isMultifactorCodeInvalid: Bool {
        return self.code == "a0.mfa_invalid_code" || self.code == "invalid_grant" && self.localizedDescription == "Invalid otp_code."
    }

    /// When the MFA token is invalid or expired.
    public var isMultifactorTokenInvalid: Bool {
        return self.code == "expired_token" && self.localizedDescription == "mfa_token is expired" || self.code == "invalid_grant" && self.localizedDescription == "Malformed mfa_token"
    }

    /// When the password used for signup does not match the strength requirements of the connection.
    /// Additional information is available in the ``info`` dictionary.
    public var isPasswordNotStrongEnough: Bool {
        return self.code == "invalid_password" && self.info["name"] as? String == "PasswordStrengthError"
    }

    /// When the password used for signup was already used before. This is reported when the Password History feature
    /// is enabled.
    /// Additional information is available in the ``info`` dictionary.
    public var isPasswordAlreadyUsed: Bool {
        return self.code == "invalid_password" && self.info["name"] as? String == "PasswordHistoryError"
    }

    /// When an Auth0 rule returns an error.
    /// The message returned by the rule is available in ``Auth0Error/localizedDescription``.
    public var isRuleError: Bool {
        return self.code == "unauthorized"
    }

    /// When the username and/or password used for authentication are invalid.
    public var isInvalidCredentials: Bool {
        return self.code == "invalid_user_password"
            || self.code == "invalid_grant" && self.localizedDescription == "Wrong email or password."
            || self.code == "invalid_grant" && self.localizedDescription == "Wrong email or verification code."
            || self.code == "invalid_grant" && self.localizedDescription == "Wrong phone number or verification code."
    }

    /// When the credentials renewal fails because the user was deleted.
    public var isRefreshTokenDeleted: Bool {
        return self.code == "invalid_grant"
            && self.localizedDescription == "The refresh_token was generated for a user who doesn't exist anymore."

    }

    /// When Auth0 denies access due to some misconfiguration or an error in an Action or Rule.
    public var isAccessDenied: Bool {
        return self.code == "access_denied"
    }

    /// When the user is blocked due to too many attempts to log in.
    public var isTooManyAttempts: Bool {
        return self.code == "too_many_attempts"
    }

    /// When an additional verification step is required.
    public var isVerificationRequired: Bool {
        return self.code == "requires_verification"
    }

    /// When the password used was reported to be leaked.
    public var isPasswordLeaked: Bool {
        return self.code == "password_leaked"
    }

    /// When performing Web Auth login with `prompt: "none"` and the Auth0 session has expired.
    public var isLoginRequired: Bool {
        return self.code == "login_required"
    }

    /// When the request failed due to network issues.
    ///
    /// Returns `true` when the `URLError` code is one of the following:
    /// - [notConnectedToInternet](https://developer.apple.com/documentation/foundation/urlerror/2293104-notconnectedtointernet)
    /// - [networkConnectionLost](https://developer.apple.com/documentation/foundation/urlerror/2293759-networkconnectionlost)
    /// - [dnsLookupFailed](https://developer.apple.com/documentation/foundation/urlerror/2293434-dnslookupfailed)
    /// - [cannotFindHost](https://developer.apple.com/documentation/foundation/urlerror/2293460-cannotfindhost)
    /// - [cannotConnectToHost](https://developer.apple.com/documentation/foundation/urlerror/2293028-cannotconnecttohost)
    /// - [timedOut](https://developer.apple.com/documentation/foundation/urlerror/2293002-timedout)
    /// - [internationalRoamingOff](https://developer.apple.com/documentation/foundation/urlerror/2292893-internationalroamingoff)
    /// - [callIsActive](https://developer.apple.com/documentation/foundation/urlerror/2293147-callisactive)
    ///
    /// The underlying `URLError` is available in the ``Auth0Error/cause-9wuyi`` property.
    public var isNetworkError: Bool {
        guard let code = (self.cause as? URLError)?.code else {
            return false
        }

        let networkErrorCodes: [URLError.Code] = [
            .notConnectedToInternet,
            .networkConnectionLost,
            .dnsLookupFailed,
            .cannotFindHost,
            .cannotConnectToHost,
            .timedOut,
            .internationalRoamingOff,
            .callIsActive
        ]
        return networkErrorCodes.contains(code)
    }
}

// MARK: - Error Messages

extension AuthenticationError {

    var message: String {
        let description = self.info["description"] ?? self.info["error_description"]

        if let string = description as? String {
            return string
        }
        if self.code == unknownError {
            return "Failed with unknown error \(self.info)."
        }

        return "Received error with code \(self.code)."
    }

}

// MARK: - Equatable

extension AuthenticationError: Equatable {

    /// Conformance to `Equatable`.
    public static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
        return lhs.code == rhs.code
            && lhs.statusCode == rhs.statusCode
            && lhs.localizedDescription == rhs.localizedDescription
    }

}
