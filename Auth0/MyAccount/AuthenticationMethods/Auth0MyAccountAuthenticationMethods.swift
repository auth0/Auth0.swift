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
            "authn_response": authenticatorResponse,
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

    func enrolRecoveryCode() -> Request<RecoveryCodeChallenge, MyAccountError> {
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

    func enrollTOTP() -> Request<TOTPPushEnrollmentChallenge, MyAccountError> {
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

    func enrollPushNotification() -> Request<TOTPPushEnrollmentChallenge, MyAccountError> {
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
    func enrollEmail(emailAddress: String) -> Request<PhoneEmailChallenge, MyAccountError> {
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

    func enrollPhone(phoneNumber: String, preferredAuthenticationMethod: String) -> Request<PhoneEmailChallenge, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["type"] = "phone"
        payload["phone_number"] = phoneNumber
        payload["preferred_authentication_method"] = preferredAuthenticationMethod
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func confirmTOTPEnrolment(id: String,
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

    func confirmEmailEnrolment(id: String,
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

    func confirmPushNotificationEnrolment(id: String,
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

    func confirmPhoneEnrolment(id: String,
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

    func confirmRecoveryCodeEnrolment(id: String,
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

    func deleteAuthenticationMethod(id: String) -> Request<Void, MyAccountError> {
        return Request(session: session,
                       url: self.url.appending("authentication-methods").appending(id),
                       method: "DELETE",
                       handle: myAccountDecodableNoBody,
                       headers: defaultHeaders,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func getAuthenticationMethods() -> Request<AuthenticationMethods, MyAccountError> {
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "GET",
                       handle: myAcccountDecodable,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func getFactorStatus() -> Request<[Factor], MyAccountError> {
        return Request(session: session,
                       url: url.appending("factors"),
                       method: "GET",
                       handle: myAcccountDecodable,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func getAuthenticationMethod(id: String) -> Request<AuthenticationMethod, MyAccountError> {
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id),
                       method: "GET",
                       handle: myAcccountDecodable,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }

    func updateAuthenticationMethod(id: String,
                                    name: String?,
                                    preferredAuthenticationMethod: String?) -> Request<AuthenticationMethod, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["name"] = name
        payload["preferred_authentication_method"] = preferredAuthenticationMethod
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id),
                       method: "PATCH",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       telemetry: telemetry)
    }
}
