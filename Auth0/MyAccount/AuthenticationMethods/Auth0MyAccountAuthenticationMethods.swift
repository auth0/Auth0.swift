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
        self.url = url.appending("authentication-methods")
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
                       url: self.url,
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
                       url: self.url.appending(path),
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }
    #endif

}
