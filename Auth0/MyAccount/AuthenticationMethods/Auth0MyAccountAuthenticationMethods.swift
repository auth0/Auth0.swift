import Foundation

struct Auth0MyAccountAuthenticationMethods: MyAccountAuthenticationMethods {
    let url: URL
    let session: URLSession
    let token: String

    var auth0ClientInfo: Auth0ClientInfo
    var logger: Logger?
    var dpop: DPoP?

    init(token: String,
         url: URL,
         session: URLSession = .shared,
         auth0ClientInfo: Auth0ClientInfo = Auth0ClientInfo(),
         logger: Logger? = nil,
         dpop: DPoP? = nil) {
        self.token = token
        self.url = url
        self.session = session
        self.auth0ClientInfo = auth0ClientInfo
        self.logger = logger
        self.dpop = dpop
    }

    // MARK: - Passkey Enrollment

    #if PASSKEYS_PLATFORM
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyEnrollmentChallenge(userIdentityId: String?,
                                    connection: String?) -> any Requestable<PasskeyEnrollmentChallenge, MyAccountError> {
        var payload: [String: Any] = ["type": "passkey"]
        payload["identity_user_id"] = userIdentityId
        payload["connection"] = connection

        return Request(session: session,
                       url: self.url.appending("authentication-methods"),
                       method: "POST",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: self.logger,
                       auth0ClientInfo: self.auth0ClientInfo,
                       dpop: self.dpop)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func enroll(passkey: NewPasskey,
                challenge: PasskeyEnrollmentChallenge) -> any Requestable<PasskeyAuthenticationMethod, MyAccountError> {
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
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: self.logger,
                       auth0ClientInfo: self.auth0ClientInfo,
                       dpop: self.dpop)
    }
    #endif

    func enrollRecoveryCode() -> any Requestable<RecoveryCodeEnrollmentChallenge, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["type"] = "recovery-code"
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "POST",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func enrollTOTP() -> any Requestable<TOTPEnrollmentChallenge, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["type"] = "totp"
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "POST",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func enrollPushNotification() -> any Requestable<PushEnrollmentChallenge, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["type"] = "push-notification"
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "POST",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func enrollEmail(emailAddress: String) -> any Requestable<EmailEnrollmentChallenge, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["type"] = "email"
        payload["email"] = emailAddress
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "POST",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func enrollPhone(phoneNumber: String,
                     preferredAuthenticationMethod: PreferredAuthenticationMethod?) -> any Requestable<PhoneEnrollmentChallenge, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["type"] = "phone"
        payload["phone_number"] = phoneNumber
        payload["preferred_authentication_method"] = preferredAuthenticationMethod?.rawValue
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "POST",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func confirmTOTPEnrollment(id: String,
                               authSession: String,
                               otpCode: String) -> any Requestable<AuthenticationMethod, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["auth_session"] = authSession
        payload["otp_code"] = otpCode
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id).appending("verify"),
                       method: "POST",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func confirmEmailEnrollment(id: String,
                                authSession: String,
                                otpCode: String) -> any Requestable<AuthenticationMethod, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["auth_session"] = authSession
        payload["otp_code"] = otpCode
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id).appending("verify"),
                       method: "POST",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func confirmPushNotificationEnrollment(id: String,
                                           authSession: String) -> any Requestable<AuthenticationMethod, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["auth_session"] = authSession

        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id).appending("verify"),
                       method: "POST",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func confirmPhoneEnrollment(id: String,
                                authSession: String,
                                otpCode: String) -> any Requestable<AuthenticationMethod, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["auth_session"] = authSession
        payload["otp_code"] = otpCode
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id).appending("verify"),
                       method: "POST",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func confirmRecoveryCodeEnrollment(id: String,
                                       authSession: String) -> any Requestable<AuthenticationMethod, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["auth_session"] = authSession
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id).appending("verify"),
                       method: "POST",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func deleteAuthenticationMethod(by id: String) -> any Requestable<Void, MyAccountError> {
        return Request(session: session,
                       url: self.url.appending("authentication-methods").appending(id),
                       method: "DELETE",
                       handle: { @Sendable result, callback in myAccountDecodableNoBody(from: result, callback: callback) },
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func getAuthenticationMethods(type: AuthenticationMethodType?) -> any Requestable<[AuthenticationMethod], MyAccountError> {
        var parameters: [String: Any] = [:]
        if let type {
            parameters["type"] = type.rawValue
        }
        return Request(session: session,
                       url: url.appending("authentication-methods"),
                       method: "GET",
                       handle: { @Sendable result, callback in getAuthMethodsDecodable(from: result, callback: callback) },
                       parameters: parameters,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func getFactors() -> any Requestable<[Factor], MyAccountError> {
        return Request(session: session,
                       url: url.appending("factors"),
                       method: "GET",
                       handle: { @Sendable result, callback in getFactorsDecodable(from: result, callback: callback) },
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func getAuthenticationMethod(by id: String) -> any Requestable<AuthenticationMethod, MyAccountError> {
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id),
                       method: "GET",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func updateAuthenticationMethod(by id: String,
                                    name: String?,
                                    preferredAuthenticationMethod: PreferredAuthenticationMethod?) -> any Requestable<AuthenticationMethod, MyAccountError> {
        var payload: [String: Any] = [:]
        payload["name"] = name
        payload["preferred_authentication_method"] = preferredAuthenticationMethod?.rawValue
        return Request(session: session,
                       url: url.appending("authentication-methods").appending(id),
                       method: "PATCH",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }
}
