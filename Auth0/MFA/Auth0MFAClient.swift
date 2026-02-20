import Foundation

struct Auth0MFAClient: MFAClient {
    var dpop: DPoP?
    let clientId: String
    let url: URL
    var telemetry: Telemetry
    var logger: Logger?
    let session: URLSession

    init(clientId: String,
         url: URL,
         session: URLSession = URLSession.shared,
         telemetry: Telemetry = Telemetry()) {
        self.clientId = clientId
        self.url = url
        self.session = session
        self.telemetry = telemetry
    }

    func getAuthenticators(mfaToken: String, factorsAllowed: [String]) -> any Requestable<[Authenticator], MfaListAuthenticatorsError> {
        let url = URL(string: "/mfa/authenticators", relativeTo: self.url)!
        return Request(session: session,
                       url: url,
                       method: "GET",
                       handle: { result, callback in
            listAuthenticatorsResponseMapper(factorsAllowed: factorsAllowed, result: result, callback: callback)
        }, headers: baseHeaders(accessToken: mfaToken, tokenType: "Bearer"),
                       logger: logger,
                       telemetry: telemetry)
        .requestValidators([ListAuthenticatorsValidator(factorsAllowed: factorsAllowed)])
    }

    func enroll(mfaToken: String, phoneNumber: String) -> any Requestable<MFAEnrollmentChallenge, MfaEnrollmentError> {
        let url = URL(string: "mfa/associate", relativeTo: self.url)!
        var payload: [String: Any] = [:]
        payload["authenticator_types"] = ["oob"]
        payload["oob_channels"] = ["sms"]
        payload["phone_number"] = phoneNumber
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: mfaEnrollDecodable,
                       parameters: payload,
                       headers: baseHeaders(accessToken: mfaToken, tokenType: "Bearer"),
                       logger: logger,
                       telemetry: telemetry)
    }

    func challenge(with authenticatorId: String, mfaToken: String) -> any Requestable<MFAChallenge, MfaChallengeError> {
        let url = URL(string: "mfa/challenge", relativeTo: self.url)!
        var payload: [String: Any] = [:]
        payload["client_id"] = clientId
        payload["challenge_type"] = "oob"
        payload["authenticator_id"] = authenticatorId
        payload["mfa_token"] = mfaToken
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: mfaChallengeDecodable,
                       parameters: payload,
                       logger: logger,
                       telemetry: telemetry)
    }

    func verify(oobCode: String,
                bindingCode: String?,
                mfaToken: String) -> any Requestable<Credentials, MFAVerifyError> {
        var parameters: [String: Any] = [:]
        parameters["oob_code"] = oobCode
        parameters["binding_code"] = bindingCode
        parameters["grant_type"] = "http://auth0.com/oauth/grant-type/mfa-oob"
        parameters["mfa_token"] = mfaToken
        return self.token()
            .parameters(parameters)
    }

    func enroll(mfaToken: String) -> any Requestable<OTPMFAEnrollmentChallenge, MfaEnrollmentError> {
        let url = URL(string: "mfa/associate", relativeTo: self.url)!
        var payload: [String: Any] = [:]
        payload["authenticator_types"] = ["otp"]
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: mfaEnrollDecodable,
                       parameters: payload,
                       headers: baseHeaders(accessToken: mfaToken, tokenType: "Bearer"),
                       logger: logger,
                       telemetry: telemetry)
    }

    func verify(otp: String,
                mfaToken: String) -> any Requestable<Credentials, MFAVerifyError> {
        var payload: [String: Any] = [:]
        payload["otp"] = otp
        payload["grant_type"] = "http://auth0.com/oauth/grant-type/mfa-otp"
        payload["mfa_token"] = mfaToken
        return self.token().parameters(payload)
    }

    func verify(recoveryCode: String,
                mfaToken: String) -> any Requestable<Credentials, MFAVerifyError> {
        var payload: [String: Any] = [:]
        payload["recovery_code"] = recoveryCode
        payload["mfa_token"] = mfaToken
        payload["grant_type"] = "http://auth0.com/oauth/grant-type/mfa-recovery-code"
        payload["client_id"] = clientId
        return token().parameters(payload)
    }

    func enroll(mfaToken: String) -> any Requestable<PushMFAEnrollmentChallenge, MfaEnrollmentError> {
        let url = URL(string: "mfa/associate", relativeTo: self.url)!
        var payload: [String: Any] = [:]
        payload["authenticator_types"] = ["oob"]
        payload["oob_channels"] = ["auth0"]
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: mfaEnrollDecodable,
                       parameters: payload,
                       headers: baseHeaders(accessToken: mfaToken, tokenType: "Bearer"),
                       logger: logger,
                       telemetry: telemetry)
    }

    func enroll(mfaToken: String, email: String) -> any Requestable<MFAEnrollmentChallenge, MfaEnrollmentError> {
        let url = URL(string: "mfa/associate", relativeTo: url)!
        var payload: [String: Any] = [:]
        payload["authenticator_types"] = ["oob"]
        payload["oob_channels"] = ["email"]
        payload["email"] = email
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: mfaEnrollDecodable,
                       parameters: payload,
                       headers: baseHeaders(accessToken: mfaToken, tokenType: "Bearer"),
                       logger: logger,
                       telemetry: telemetry)
    }
}

private extension Auth0MFAClient {
    func token<T: Codable>() -> any Requestable<T, MFAVerifyError> {
        let token = URL(string: "oauth/token", relativeTo: self.url)!
        let payload: [String: Any] = ["client_id": self.clientId]

        return Request(session: session,
                       url: token,
                       method: "POST",
                       handle: mfaVerifyDecodable,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry,
                       dpop: self.dpop)
    }
}
