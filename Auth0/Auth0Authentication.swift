import Foundation

struct Auth0Authentication: Authentication {

    let clientId: String
    let url: URL
    var telemetry: Telemetry
    var logger: Logger?

    let session: URLSession

    init(clientId: String, url: URL, session: URLSession = URLSession.shared, telemetry: Telemetry = Telemetry()) {
        self.clientId = clientId
        self.url = url
        self.session = session
        self.telemetry = telemetry
    }

    func login(email: String, code: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError> {
        return login(username: email, otp: code, realm: "email", audience: audience, scope: scope)
    }

    func login(phoneNumber: String, code: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError> {
        return login(username: phoneNumber, otp: code, realm: "sms", audience: audience, scope: scope)
    }

    func login(usernameOrEmail username: String, password: String, realmOrConnection realm: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError> {
        let url = URL(string: "oauth/token", relativeTo: self.url)!
        var payload: [String: Any] = [
            "username": username,
            "password": password,
            "grant_type": "http://auth0.com/oauth/grant-type/password-realm",
            "client_id": self.clientId,
            "realm": realm
        ]
        payload["audience"] = audience
        payload["scope"] = includeRequiredScope(in: scope)
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: codable,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func loginDefaultDirectory(withUsername username: String, password: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError> {
        let url = URL(string: "oauth/token", relativeTo: self.url)!
        var payload: [String: Any] = [
            "username": username,
            "password": password,
            "grant_type": "password",
            "client_id": self.clientId
        ]
        payload["audience"] = audience
        payload["scope"] = includeRequiredScope(in: scope)
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: codable,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func login(withOTP otp: String, mfaToken: String) -> Request<Credentials, AuthenticationError> {
        let url = URL(string: "oauth/token", relativeTo: self.url)!
        let payload: [String: Any] = [
            "otp": otp,
            "mfa_token": mfaToken,
            "grant_type": "http://auth0.com/oauth/grant-type/mfa-otp",
            "client_id": self.clientId
        ]
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: codable,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func login(withOOBCode oobCode: String, mfaToken: String, bindingCode: String?) -> Request<Credentials, AuthenticationError> {
        let url = URL(string: "oauth/token", relativeTo: self.url)!
        var payload: [String: Any] = [
            "oob_code": oobCode,
            "mfa_token": mfaToken,
            "grant_type": "http://auth0.com/oauth/grant-type/mfa-oob",
            "client_id": self.clientId
        ]

        if let bindingCode = bindingCode {
            payload["binding_code"] = bindingCode
        }

        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: codable,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func login(withRecoveryCode recoveryCode: String, mfaToken: String) -> Request<Credentials, AuthenticationError> {
        let url = URL(string: "oauth/token", relativeTo: self.url)!
        let payload: [String: Any] = [
            "recovery_code": recoveryCode,
            "mfa_token": mfaToken,
            "grant_type": "http://auth0.com/oauth/grant-type/mfa-recovery-code",
            "client_id": self.clientId
        ]

        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: codable,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func multifactorChallenge(mfaToken: String, types: [String]?, authenticatorId: String?) -> Request<Challenge, AuthenticationError> {
        let url = URL(string: "mfa/challenge", relativeTo: self.url)!
        var payload: [String: String] = [
            "mfa_token": mfaToken,
            "client_id": self.clientId
        ]

        if let types = types {
            payload["challenge_type"] = types.joined(separator: " ")
        }

        if let authenticatorId = authenticatorId {
            payload["authenticator_id"] = authenticatorId
        }

        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: codable,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func login(appleAuthorizationCode authorizationCode: String, fullName: PersonNameComponents?, profile: [String: Any]?, audience: String?, scope: String) -> Request<Credentials, AuthenticationError> {
        var parameters: [String: Any] = [:]
        var profile: [String: Any] = profile ?? [:]

        if let fullName = fullName {
            let name = ["firstName": fullName.givenName, "lastName": fullName.familyName].compactMapValues { $0 }
            if !name.isEmpty {
                profile["name"] = name
            }
        }

        if !profile.isEmpty, let jsonData = try? JSONSerialization.data(withJSONObject: profile, options: []),
            let json = String(data: jsonData, encoding: .utf8) {
            parameters["user_profile"] = json
        }

        return self.tokenExchange(subjectToken: authorizationCode,
                                  subjectTokenType: "http://auth0.com/oauth/token-type/apple-authz-code",
                                  scope: scope,
                                  audience: audience,
                                  parameters: parameters)
    }

    func login(facebookSessionAccessToken sessionAccessToken: String, profile: [String: Any], audience: String?, scope: String) -> Request<Credentials, AuthenticationError> {
        var parameters: [String: String] = [:]
        if let jsonData = try? JSONSerialization.data(withJSONObject: profile, options: []),
            let json = String(data: jsonData, encoding: .utf8) {
            parameters["user_profile"] = json
        }
        return self.tokenExchange(subjectToken: sessionAccessToken,
                                  subjectTokenType: "http://auth0.com/oauth/token-type/facebook-info-session-access-token",
                                  scope: scope,
                                  audience: audience,
                                  parameters: parameters)
    }

    func signup(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: Any]? = nil, rootAttributes: [String: Any]? = nil) -> Request<DatabaseUser, AuthenticationError> {
        var payload: [String: Any] = [
            "email": email,
            "password": password,
            "connection": connection,
            "client_id": self.clientId
        ]
        payload["username"] = username
        payload["user_metadata"] = userMetadata
        if let rootAttributes = rootAttributes {
            rootAttributes.forEach { (key, value) in
                if payload[key] == nil { payload[key] = value }
            }
        }

        let signup = URL(string: "dbconnections/signup", relativeTo: self.url)!
        return Request(session: session,
                       url: signup,
                       method: "POST",
                       handle: databaseUser,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func resetPassword(email: String, connection: String) -> Request<Void, AuthenticationError> {
        let payload = [
            "email": email,
            "connection": connection,
            "client_id": self.clientId
        ]
        let resetPassword = URL(string: "dbconnections/change_password", relativeTo: self.url)!
        return Request(session: session,
                       url: resetPassword,
                       method: "POST",
                       handle: noBody,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func startPasswordless(email: String, type: PasswordlessType, connection: String) -> Request<Void, AuthenticationError> {
        let payload: [String: Any] = [
            "email": email,
            "connection": connection,
            "send": type.rawValue,
            "client_id": self.clientId
        ]

        let start = URL(string: "passwordless/start", relativeTo: self.url)!
        return Request(session: session,
                       url: start,
                       method: "POST",
                       handle: noBody,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func startPasswordless(phoneNumber: String, type: PasswordlessType, connection: String) -> Request<Void, AuthenticationError> {
        let payload: [String: Any] = [
            "phone_number": phoneNumber,
            "connection": connection,
            "send": type.rawValue,
            "client_id": self.clientId
        ]
        let start = URL(string: "passwordless/start", relativeTo: self.url)!
        return Request(session: session,
                       url: start,
                       method: "POST",
                       handle: noBody,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func userInfo(withAccessToken accessToken: String) -> Request<UserInfo, AuthenticationError> {
        let userInfo = URL(string: "userinfo", relativeTo: self.url)!
        return Request(session: session,
                       url: userInfo,
                       method: "GET",
                       handle: authenticationObject,
                       headers: ["Authorization": "Bearer \(accessToken)"],
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func codeExchange(withCode code: String, codeVerifier: String, redirectURI: String) -> Request<Credentials, AuthenticationError> {
        return self.token().parameters([
            "code": code,
            "code_verifier": codeVerifier,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
        ])
    }

    func renew(withRefreshToken refreshToken: String, scope: String? = nil) -> Request<Credentials, AuthenticationError> {
        var payload: [String: Any] = [
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
            "client_id": self.clientId
        ]
        payload["scope"] = scope
        let oauthToken = URL(string: "oauth/token", relativeTo: self.url)!
        return Request(session: session,
                       url: oauthToken,
                       method: "POST",
                       handle: codable,
                       parameters: payload, // Initializer does not enforce 'openid' scope
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func revoke(refreshToken: String) -> Request<Void, AuthenticationError> {
        let payload: [String: Any] = [
            "token": refreshToken,
            "client_id": self.clientId
        ]
        let oauthToken = URL(string: "oauth/revoke", relativeTo: self.url)!
        return Request(session: session,
                       url: oauthToken,
                       method: "POST",
                       handle: noBody,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func jwks() -> Request<JWKS, AuthenticationError> {
        let jwks = URL(string: ".well-known/jwks.json", relativeTo: self.url)!
        return Request(session: session,
                       url: jwks,
                       method: "GET",
                       handle: codable,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

}

// MARK: - Private Methods

private extension Auth0Authentication {

    func login(username: String, otp: String, realm: String, audience: String?, scope: String) -> Request<Credentials, AuthenticationError> {
        let url = URL(string: "oauth/token", relativeTo: self.url)!
        var payload: [String: Any] = [
            "username": username,
            "otp": otp,
            "realm": realm,
            "grant_type": "http://auth0.com/oauth/grant-type/passwordless/otp",
            "client_id": self.clientId
        ]
        payload["audience"] = audience
        payload["scope"] = includeRequiredScope(in: scope)
        return Request(session: session,
                       url: url,
                       method: "POST",
                       handle: codable,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func token() -> Request<Credentials, AuthenticationError> {
        let payload: [String: Any] = [
            "client_id": self.clientId
        ]
        let token = URL(string: "oauth/token", relativeTo: self.url)!
        return Request(session: session,
                       url: token,
                       method: "POST",
                       handle: codable,
                       parameters: payload,
                       logger: self.logger,
                       telemetry: self.telemetry)
    }

    func tokenExchange(subjectToken: String, subjectTokenType: String, scope: String, audience: String?, parameters: [String: Any] = [:]) -> Request<Credentials, AuthenticationError> {
        var parameters: [String: Any] = parameters
        parameters["grant_type"] = "urn:ietf:params:oauth:grant-type:token-exchange"
        parameters["subject_token"] = subjectToken
        parameters["subject_token_type"] = subjectTokenType
        parameters["audience"] = audience
        parameters["scope"] = scope
        return self.token().parameters(parameters) // parameters() enforces 'openid' scope
    }

}
