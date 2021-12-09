import Foundation

/**
 *  Represents an error during a request to Auth0 Authentication API.
 */
public struct AuthenticationError: Auth0APIError {

    public let info: [String: Any]

    public init(info: [String: Any], statusCode: Int) {
        var values = info
        values["statusCode"] = statusCode
        self.info = values
        self.statusCode = statusCode
    }

    public let statusCode: Int

    public var cause: Error? {
        return self.info["cause"] as? Error
    }

    public var code: String {
        let code = self.info["error"] ?? self.info["code"]
        return code as? String ?? unknownError
    }

    public var debugDescription: String {
        let description = self.info["description"] ?? self.info["error_description"]
        if let string = description as? String {
            return string
        }

        guard self.code == unknownError else { return "Received error with code \(self.code)" }

        return "Failed with unknown error \(self.info)"
    }

    /// When MFA code is required to authenticate.
    public var isMultifactorRequired: Bool {
        return self.code == "a0.mfa_required" || self.code == "mfa_required"
    }

    /// When MFA is required and the user is not enrolled.
    public var isMultifactorEnrollRequired: Bool {
        return self.code == "a0.mfa_registration_required" || self.code == "unsupported_challenge_type"
    }

    /// When MFA code sent is invalid or expired.
    public var isMultifactorCodeInvalid: Bool {
        return self.code == "a0.mfa_invalid_code" || self.code == "invalid_grant" && self.localizedDescription == "Invalid otp_code."
    }

    /// When MFA code sent is invalid or expired.
    public var isMultifactorTokenInvalid: Bool {
        return self.code == "expired_token" && self.localizedDescription == "mfa_token is expired" || self.code == "invalid_grant" && self.localizedDescription == "Malformed mfa_token"
    }

    /// When password used for SignUp does not match connection's strength requirements. More info will be available in `info`.
    public var isPasswordNotStrongEnough: Bool {
        return self.code == "invalid_password" && self.info["name"] as? String == "PasswordStrengthError"
    }

    /// When password used for SignUp was already used before (Reported when password history feature is enabled). More info will be available in `info`.
    public var isPasswordAlreadyUsed: Bool {
        return self.code == "invalid_password" && self.info["name"] as? String == "PasswordHistoryError"
    }

    /// When Auth0 rule returns an error. The message returned by the rule will be in `localizedDescription`.
    public var isRuleError: Bool {
        return self.code == "unauthorized"
    }

    /// When username and/or password used for authentication are invalid.
    public var isInvalidCredentials: Bool {
        return self.code == "invalid_user_password"
            || self.code == "invalid_grant" && self.localizedDescription == "Wrong email or password."
            || self.code == "invalid_grant" && self.localizedDescription == "Wrong email or verification code."
            || self.code == "invalid_grant" && self.localizedDescription == "Wrong phone number or verification code."
    }

    /// When authenticating with web-based authentication and the resource server denied access per OAuth2 spec.
    public var isAccessDenied: Bool {
        return self.code == "access_denied"
    }

    /// When you reached the maximum amount of request for the API.
    public var isTooManyAttempts: Bool {
        return self.code == "too_many_attempts"
    }

    /// When an additional verification step is required.
    public var isVerificationRequired: Bool {
        return self.code == "requires_verification"
    }

}

extension AuthenticationError: Equatable {

    public static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
        return lhs.code == rhs.code
            && lhs.statusCode == rhs.statusCode
            && lhs.localizedDescription == rhs.localizedDescription
    }

}
