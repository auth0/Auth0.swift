import Foundation

/**
 Error raised when listing MFA authenticators fails.
 
 Returned by ``MFAClient/getAuthenticators(mfaToken:factorsAllowed:)`` when the operation
 fails due to invalid parameters or API errors.
 
 ## Common Error Codes
 
 - `invalid_request`: Request parameters are invalid (e.g., missing or empty factorsAllowed)
 - `invalid_token`: MFA token is invalid or expired
 - `access_denied`: User lacks permission to access this resource
 
 ## See Also
 
 - ``MFAClient``
 - ``Authenticator``
 - [MFA API Documentation](https://auth0.com/docs/api/authentication#multi-factor-authentication)
 */
public struct MfaListAuthenticatorsError: Auth0APIError {
    /**
     Creates an MFA list authenticators error from the API response.
     
     - Parameters:
       - info: Additional error information from the API response.
       - statusCode: HTTP status code from the response.
     */
    public init(info: [String: Any], statusCode: Int = 0) {
        self.info = info
        self.statusCode = statusCode
        code = (info["error"] as? String) ?? "mfa_list_authenticators_error"
    }

    /// Additional error information from the API response.
    public var info: [String: Any]

    /// The error code identifying the type of failure.
    public var code: String

    /// HTTP status code from the API response, or 0 if not applicable.
    public var statusCode: Int

    /// A textual representation for debugging purposes.
    public var debugDescription: String {
        return "MfaListAuthenticatorsError(code: \(code), message: \(message), statusCode: \(statusCode))"
    }

    /// A user-facing description of what went wrong.
    var message: String {
        if let description = self.info[apiErrorDescription] as? String ?? self.info["error_description"] as? String {
            return description
        }

        if self.code == unknownError {
            return "Failed with unknown error: \(self.info)."
        }

        return "Failed to list authenticators"
    }
}

/**
 Error raised when MFA enrollment fails.
 
 Returned by enrollment operations when adding a new MFA factor fails:
 - ``MFAClient/enroll(mfaToken:phoneNumber:)`` - SMS enrollment
 - ``MFAClient/enroll(mfaToken:email:)`` - Email enrollment
 - ``MFAClient/enroll(mfaToken:)`` - TOTP or Push enrollment
 
 ## Common Error Codes
 
 - `invalid_request`: Enrollment parameters are invalid
 - `invalid_token`: MFA token is invalid or expired
 - `enrollment_conflict`: Authenticator is already enrolled
 - `unsupported_challenge_type`: Requested factor type is not enabled
 
 ## See Also
 
 - ``MFAClient``
 - ``MFAEnrollmentChallenge``
 - ``OTPMFAEnrollmentChallenge``
 - ``PushMFAEnrollmentChallenge``
 - [MFA API Documentation](https://auth0.com/docs/api/authentication#multi-factor-authentication)
 */
public struct MfaEnrollmentError: Auth0APIError {
    /**
     Creates an MFA enrollment error from the API response.
     
     - Parameters:
       - info: Additional error information from the API response.
       - statusCode: HTTP status code from the response.
     */
    public init(info: [String: Any], statusCode: Int = 0) {
        self.info = info
        self.statusCode = statusCode
        code = (info["error"] as? String) ?? "mfa_enrollment_error"
    }

    /// Additional error information from the API response.
    public var info: [String: Any]

    /// The error code identifying the type of failure.
    public var code: String

    /// HTTP status code from the API response, or 0 if not applicable.
    public var statusCode: Int

    /// A textual representation for debugging purposes.
    public var debugDescription: String {
        return "MfaEnrollmentError(code: \(code), message: \(message), statusCode: \(statusCode))"
    }

    /// A user-facing description of what went wrong.
    var message: String {
        if let description = self.info[apiErrorDescription] as? String ?? self.info["error_description"] as? String {
            return description
        }

        if self.code == unknownError {
            return "Failed with unknown error: \(self.info)."
        }

        return "Failed to enroll MFA authenticator"
    }
}

/**
 Error raised when initiating an MFA challenge fails.
 
 Returned by ``MFAClient/challenge(with:mfaToken:)`` when requesting a verification
 code fails due to invalid parameters or API errors.
 
 ## Common Error Codes
 
 - `invalid_request`: Challenge parameters are invalid
 - `invalid_token`: MFA token is invalid or expired
 - `authenticator_not_found`: Specified authenticator doesn't exist
 - `unsupported_challenge_type`: Authenticator type doesn't support challenges
 
 ## See Also
 
 - ``MFAClient``
 - ``MFAChallenge``
 - ``Authenticator``
 - [MFA API Documentation](https://auth0.com/docs/api/authentication#multi-factor-authentication)
 */
public struct MfaChallengeError: Auth0APIError {
    /**
     Creates an MFA challenge error from the API response.
     
     - Parameters:
       - info: Additional error information from the API response.
       - statusCode: HTTP status code from the response.
     */
    public init(info: [String: Any], statusCode: Int = 0) {
        self.info = info
        self.statusCode = statusCode
        code = (info["error"] as? String) ?? "mfa_challenge_error"
    }

    /// Additional error information from the API response.
    public var info: [String: Any]

    /// The error code identifying the type of failure.
    public var code: String

    /// HTTP status code from the API response, or 0 if not applicable.
    public var statusCode: Int

    /// A textual representation for debugging purposes.
    public var debugDescription: String {
        return "MfaChallengeError(code: \(code), message: \(message), statusCode: \(statusCode))"
    }

    /// A user-facing description of what went wrong.
    var message: String {
        if let description = self.info[apiErrorDescription] as? String ?? self.info["error_description"] as? String {
            return description
        }

        if self.code == unknownError {
            return "Failed with unknown error: \(self.info)."
        }

        return "Failed to initiate MFA challenge"
    }
}

/**
 Error raised when MFA verification fails.
 
 Returned by verification operations when validating MFA codes fails:
 - ``MFAClient/verify(oobCode:bindingCode:mfaToken:)`` - OOB verification (SMS/email)
 - ``MFAClient/verify(otp:mfaToken:)`` - OTP verification (TOTP)
 - ``MFAClient/verify(recoveryCode:mfaToken:)`` - Recovery code verification
 
 ## Common Error Codes
 
 - `invalid_grant`: Verification code is incorrect or expired
 - `invalid_token`: MFA token is invalid or expired
 - `invalid_oob_code`: Out-of-band code is invalid
 - `invalid_binding_code`: Binding code (SMS/email code) is incorrect
 - `expired_token`: Verification code has expired
 
 ## See Also
 
 - ``MFAClient``
 - ``Credentials``
 - [MFA API Documentation](https://auth0.com/docs/api/authentication#multi-factor-authentication)
 */
public struct MFAVerifyError: Auth0APIError {
    /**
     Creates an MFA verification error from the API response.
     
     - Parameters:
       - info: Additional error information from the API response.
       - statusCode: HTTP status code from the response.
     */
    public init(info: [String: Any], statusCode: Int = 0) {
        code = (info["error"] as? String) ?? "mfa_verify_error"
        self.info = info
        self.statusCode = statusCode
    }

    /// Additional error information from the API response.
    public var info: [String: Any]

    /// The error code identifying the type of failure.
    public var code: String

    /// HTTP status code from the API response, or 0 if not applicable.
    public var statusCode: Int

    /// A textual representation for debugging purposes.
    public var debugDescription: String {
        return "MFAVerifyError(code: \(code), message: \(message), statusCode: \(statusCode))"
    }

    /// A user-facing description of what went wrong.
    var message: String {
        if let description = self.info[apiErrorDescription] as? String ?? self.info["error_description"] as? String {
            return description
        }

        if self.code == unknownError {
            return "Failed with unknown error: \(self.info)."
        }

        return "Failed to verify MFA code"
    }
}
