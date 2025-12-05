import Foundation

struct Auth0MyAccountAuthenticationMethods: MyAccountAuthenticationMethods {
    let url: URL
    let session: URLSession
    let token: String

    var telemetry: Telemetry
    var logger: Logger?

    init(token: String,
         url: URL,
         session: URLSession = .shared,
         telemetry: Telemetry = Telemetry(),
         logger: Logger? = nil) {
        self.token = token
        self.url = url
        self.session = session
        self.telemetry = telemetry
        self.logger = logger
    }

    // MARK: - Passkey Enrollment

    #if PASSKEYS_PLATFORM
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyEnrollmentChallenge(userIdentityId: String?,
                                    connection: String?) -> Request<PasskeyEnrollmentChallenge, MyAccountError> {
        var payload: [String: Any] = ["type": "passkey"]
        payload["identity_user_id"] = userIdentityId
        payload["connection"] = connection

        return Request(session: session,
                       url: self.url.appending("authentication-methods"),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func enroll(passkey: NewPasskey,
                challenge: PasskeyEnrollmentChallenge) -> Request<PasskeyAuthenticationMethod, MyAccountError> {
        let resourceId = challenge.authenticationMethodId.removingPercentEncoding!
        let path = "\(resourceId)/verify"
        let credentialId = passkey.credentialID.encodeBase64URLSafe()

        var authenticatorResponse: [String: Any] = [
            "id": credentialId,
            "rawId": credentialId,
            "type": "public-key",
            "response": [
                "clientDataJSON": passkey.rawClientDataJSON.encodeBase64URLSafe(),
                "attestationObject": passkey.rawAttestationObject!.encodeBase64URLSafe()
            ]
        ]

        authenticatorResponse["authenticatorAttachment"] = passkey.attachment.stringValue

        let payload: [String: Any] = [
            "auth_session": challenge.authenticationSession,
            "authn_response": authenticatorResponse
        ]

        return Request(session: session,
                       url: self.url.appending("authentication-methods").appending(path),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }
    #endif

    func enrollRecoveryCode() -> Request<RecoveryCodeEnrollmentChallenge, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["type"] = "recovery-code"
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func enrollTOTP() -> Request<TOTPEnrollmentChallenge, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["type"] = "totp"
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func enrollPushNotification() -> Request<PushEnrollmentChallenge, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["type"] = "push-notification"
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func enrollEmail(emailAddress: String) -> Request<EmailEnrollmentChallenge, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["type"] = "email"
        payload["email"] = emailAddress
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func enrollPhone(phoneNumber: String,
                     preferredAuthenticationMethod: PreferredAuthenticationMethod?) -> Request<PhoneEnrollmentChallenge, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["type"] = "phone"
        payload["phone_number"] = phoneNumber
        payload["preferred_authentication_method"] = preferredAuthenticationMethod?.rawValue
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func confirmTOTPEnrollment(id: String,
                               authSession: String,
                               otpCode: String) -> Request<AuthenticationMethod, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["auth_session"] = authSession
        payload["otp_code"] = otpCode
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id).appending("verify"),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func confirmEmailEnrollment(id: String,
                                authSession: String,
                                otpCode: String) -> Request<AuthenticationMethod, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["auth_session"] = authSession
        payload["otp_code"] = otpCode
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id).appending("verify"),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func confirmPushNotificationEnrollment(id: String,
                                           authSession: String) -> Request<AuthenticationMethod, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["auth_session"] = authSession

        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id).appending("verify"),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func confirmPhoneEnrollment(id: String,
                                authSession: String,
                                otpCode: String) -> Request<AuthenticationMethod, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["auth_session"] = authSession
        payload["otp_code"] = otpCode
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id).appending("verify"),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func confirmRecoveryCodeEnrollment(id: String,
                                       authSession: String) -> Request<AuthenticationMethod, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["auth_session"] = authSession
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id).appending("verify"),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func deleteAuthenticationMethod(by id: String) -> Request<Void, MyAccountError> {
        return Request(session: session,
                       url: self.url.appending("authentication-methods").appending(id),
                       method: "DELETE",
                       handle: myAccountDecodableNoBody,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func getAuthenticationMethods() -> Request<[AuthenticationMethod], MyAccountError> {
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "GET",
                       handle: getAuthMethodsDecodable,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func getFactors() -> Request<[Factor], MyAccountError> {
        return Request(session: session,
                       url: url.appending("factors"),
                       method: "GET",
                       handle: getFactorsDecodable,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func getAuthenticationMethod(by id: String) -> Request<AuthenticationMethod, MyAccountError> {
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id),
                       method: "GET",
                       handle: myAcccountDecodable,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }
}
