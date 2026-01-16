import Foundation

public struct Auth0MFAClient: MFAClient {
    public var dpop: DPoP?
    let clientId: String
    let url: URL
    public var telemetry: Telemetry
    public var logger: Logger?
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

    public func getAuthenticators(mfaToken: String, factorsAllowed: [String]) -> Request<[Authenticator], AuthenticationError> {
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

    public func enroll(mfaToken: String, phoneNumber: String) -> Request<MFAEnrollmentChallenge, AuthenticationError> {
        let url = URL(string: "mfa/associate", relativeTo: self.url)!
        var payload: [String: Any] = [:]
        payload["authenticator_types"] = ["oob"]
        payload["oob_channels"] = ["sms"]
        payload["phone_number"] = phoneNumber
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: mfaDecodable,
                       parameters: payload,
                       headers: baseHeaders(accessToken: mfaToken, tokenType: "Bearer"),
                       logger: logger,
                       telemetry: telemetry)
    }

    public func challenge(with authenticatorId: String, mfaToken: String) -> Request<MFAChallenge, AuthenticationError> {
        let url = URL(string: "mfa/challenge", relativeTo: self.url)!
        var payload: [String: Any] = [:]
        payload["client_id"] = clientId
        payload["challenge_type"] = "oob"
        payload["authenticator_id"] = authenticatorId
        payload["mfa_token"] = mfaToken
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: mfaDecodable,
                       parameters: payload,
                       logger: logger,
                       telemetry: telemetry)
    }

    public func verify(oobCode: String,
                       bindingCode: String?,
                       mfaToken: String) -> Request<Credentials, AuthenticationError> {
        var parameters: [String: Any] = [:]
        parameters["oob_code"] = oobCode
        parameters["binding_code"] = bindingCode
        parameters["grant_type"] = "http://auth0.com/oauth/grant-type/mfa-oob"
        parameters["mfa_token"] = mfaToken
        return self.token()
            .parameters(parameters)
    }

    public func enroll(mfaToken: String) -> Request<OTPMFAEnrollmentChallenge, AuthenticationError> {
        let url = URL(string: "mfa/associate", relativeTo: self.url)!
        var payload: [String: Any] = [:]
        payload["authenticator_types"] = ["otp"]
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: mfaDecodable,
                       parameters: payload,
                       headers: baseHeaders(accessToken: mfaToken, tokenType: "Bearer"),
                       logger: logger,
                       telemetry: telemetry)
    }

    public func verify(otp: String,
                       mfaToken: String) -> Request<Credentials, AuthenticationError> {
        var payload: [String: Any] = [:]
        payload["otp"] = otp
        payload["grant_type"] = "http://auth0.com/oauth/grant-type/mfa-otp"
        payload["mfa_token"] = mfaToken
        return self.token().parameters(payload)
    }

    public func verify(recoveryCode: String,
                       mfaToken: String) -> Request<Credentials, AuthenticationError> {
        var payload: [String: Any] = [:]
        payload["recovery_code"] = recoveryCode
        payload["mfa_token"] = mfaToken
        payload["grant_type"] = "http://auth0.com/oauth/grant-type/mfa-recovery-code"
        payload["client_id"] = clientId
        return token().parameters(payload)
    }

    public func enroll(mfaToken: String) -> Request<PushMFAEnrollmentChallenge, AuthenticationError> {
        let url = URL(string: "mfa/associate", relativeTo: self.url)!
        var payload: [String: Any] = [:]
        payload["authenticator_types"] = ["oob"]
        payload["oob_channels"] = ["auth0"]
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: mfaDecodable,
                       parameters: payload,
                       headers: baseHeaders(accessToken: mfaToken, tokenType: "Bearer"),
                       logger: logger,
                       telemetry: telemetry)
    }

    public func enroll(mfaToken: String, email: String) -> Request<MFAEnrollmentChallenge, AuthenticationError> {
        let url = URL(string: "mfa/associate", relativeTo: url)!
        var payload: [String: Any] = [:]
        payload["authenticator_types"] = ["oob"]
        payload["oob_channels"] = ["email"]
        payload["email"] = email
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: mfaDecodable,
                       parameters: payload,
                       logger: logger,
                       telemetry: telemetry)
    }
}

private extension Auth0MFAClient {
    func token<T: Codable>() -> Request<T, AuthenticationError> {
        let token = URL(string: "oauth/token", relativeTo: self.url)!
        let payload: [String: Any] = ["client_id": self.clientId]

        return Request(session: session,
                       url: token,
                       method: "POST",
                       handle: mfaDecodable,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry,
                       dpop: self.dpop)
    }
}
