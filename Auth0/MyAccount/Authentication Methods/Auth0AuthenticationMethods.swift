import Foundation

struct Auth0AuthenticationMethods: MyAccountAuthenticationMethods {

    let url: URL
    let session: URLSession
    let token: String

    var telemetry: Telemetry
    var logger: Logger?

    init(url: URL, session: URLSession, token: String, telemetry: Telemetry, logger: Logger? = nil) {
        self.url = url
        self.session = session
        self.token = token
        self.telemetry = telemetry
        self.logger = logger
    }

    // MARK: - Passkeys Enrollment

    #if PASSKEYS_PLATFORM
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func enroll(passkey: NewPasskey,
                challenge: PasskeyEnrollmentChallenge) -> Request<PasskeyAuthenticationMethod, MyAccountError> {
        let url = self.url.appending("authentication-methods/\(challenge.authenticationMethodId)/verify")
        let id = passkey.credentialID.encodeBase64URLSafe()

        var authenticatorResponse: [String: Any] = [
            "id": id,
            "rawId": id,
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
                       url: url,
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyEnrollmentChallenge(userIdentityId: String?,
                                    connection: String?) -> Request<PasskeyEnrollmentChallenge, MyAccountError> {
        let url = self.url.appending("authentication-methods")

        var payload: [String: Any] = ["type": "passkey"]
        payload["identity_user_id"] = userIdentityId
        payload["connection"] = connection

        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: myAcccountDecodable,
                       parameters: payload,
                       headers: defaultHeaders,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }
    #endif

}
