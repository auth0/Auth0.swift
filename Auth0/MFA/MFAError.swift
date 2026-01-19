public protocol MFAError: Auth0APIError {
    func getDescription() -> String
}

public struct MfaListAuthenticatorsError: MFAError {
    public init(info: [String: Any], statusCode: Int = 0) {
        self.info = info
        self.statusCode = statusCode
        code = (info["error"] as? String) ?? "mfa_list_authenticators_error"
    }

    public var info: [String: Any]

    public var code: String

    public var statusCode: Int

    public var debugDescription: String {
        return ""
    }

    public func getDescription() -> String {
        return (info["error_description"] as? String) ?? "Failed to list authenticators"
    }
}

public struct MfaEnrollmentError: MFAError {
    public init(info: [String: Any], statusCode: Int = 0) {
        self.info = info
        self.statusCode = statusCode
        code = (info["error"] as? String) ?? "mfa_enrollment_error"
    }

    public var info: [String: Any]

    public var code: String

    public var statusCode: Int

    public var debugDescription: String {
        return ""
    }

    public func getDescription() -> String {
        return (info["error_description"] as? String) ?? "Failed to enroll MFA authenticator"
    }
}

public struct MfaChallengeError: MFAError {
    public init(info: [String: Any], statusCode: Int = 0) {
        self.info = info
        self.statusCode = statusCode
        code = (info["error"] as? String) ?? "mfa_challenge_error"
    }

    public var info: [String: Any]

    public var code: String

    public var statusCode: Int

    public var debugDescription: String {
        return ""
    }

    public func getDescription() -> String {
        return (info["error_description"] as? String) ?? "Failed to initiate MFA challenge"
    }
}

public struct MFAVerifyError: MFAError {
    public init(info: [String: Any], statusCode: Int = 0) {
        code = (info["error"] as? String) ?? "mfa_verify_error"
        self.info = info
        self.statusCode = statusCode
    }

    public var info: [String: Any]

    public var code: String

    public var statusCode: Int

    public var debugDescription: String {
        return ""
    }

    public func getDescription() -> String {
        return (info["error_description"] as? String) ?? "Failed to verify MFA code"
    }
}
