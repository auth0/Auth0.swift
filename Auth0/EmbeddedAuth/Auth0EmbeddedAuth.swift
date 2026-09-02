import Foundation

struct Auth0EmbeddedAuth: EmbeddedAuth {

    let clientId: String
    let url: URL
    let session: URLSession

    var auth0ClientInfo: Auth0ClientInfo
    var logger: Logger?

    init(clientId: String,
         url: URL,
         session: URLSession = .shared,
         auth0ClientInfo: Auth0ClientInfo = Auth0ClientInfo()) {
        self.clientId = clientId
        self.url = url
        self.session = session
        self.auth0ClientInfo = auth0ClientInfo
    }

    func discover(connection: String?) -> Request<DiscoveryResult, EmbeddedAuthError> {
        var params: [String: Any] = ["client_id": clientId]
        if let connection {
            params["connection"] = connection
        }
        return Request(session: session,
                       url: url.appending("e/discovery"),
                       method: "GET",
                       handle: decodeDiscoveryResult,
                       parameters: params,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo)
    }

}

// MARK: - Response decoder

private func decodeDiscoveryResult(
    from result: Result<ResponseValue, EmbeddedAuthError>,
    callback: @Sendable (Result<DiscoveryResult, EmbeddedAuthError>) -> Void
) {
    switch result {
    case .failure(let error):
        callback(.failure(error))
    case .success(let response):
        guard let data = response.data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawAlternatives = json["alternatives"] as? [[String: Any]] else {
            callback(.failure(EmbeddedAuthError(from: response)))
            return
        }
        let options = rawAlternatives.map(LoginOption.init(from:))
        callback(.success(DiscoveryResult(options: options)))
    }
}

// MARK: - LoginOption decoding

private extension LoginOption {

    init(from dict: [String: Any]) {
        let grantType = dict["grant_type"] as? String ?? ""
        let connection = dict["connection"] as? String

        switch grantType {
        case "authorization_code":
            self = LoginOption.embeddedAuthorize(from: dict, grantType: grantType)
        case "urn:ietf:params:oauth:grant-type:token-exchange":
            let stt = dict["subject_token_type"] as? String ?? ""
            self = .nativeSocial(subjectTokenType: stt)
        case "password":
            self = .password
        case "urn:okta:params:oauth:grant-type:webauthn":
            self = LoginOption.passkey(from: dict, grantType: grantType)
        case "http://auth0.com/oauth/grant-type/passwordless/otp":
            self = LoginOption.passwordlessOtp(from: dict)
        case "http://auth0.com/oauth/grant-type/password-realm":
            let realm = dict["realm"] as? String ?? ""
            self = .passwordRealm(realm: realm)
        default:
            self = .unknown(rawGrantType: grantType, connection: connection)
        }
    }

    private static func embeddedAuthorize(from dict: [String: Any], grantType: String) -> LoginOption {
        guard let conn = dict["connection"] as? String else {
            return .unknown(rawGrantType: grantType, connection: nil)
        }
        return .embeddedAuthorize(connection: conn)
    }

    private static func passkey(from dict: [String: Any], grantType: String) -> LoginOption {
        guard let conn = dict["connection"] as? String else {
            return .unknown(rawGrantType: grantType, connection: nil)
        }
        return .passkey(connection: conn)
    }

    private static func passwordlessOtp(from dict: [String: Any]) -> LoginOption {
        let identifierStrings = dict["identifier_types"] as? [String] ?? []
        let identifiers: [PasswordlessIdentifier] = identifierStrings.compactMap {
            switch $0 {
            case "email":        return .email
            case "phone_number": return .phoneNumber
            default:             return nil
            }
        }
        let rawType = dict["type"] as? String ?? ""
        let flowType: OTPFlowType = rawType == "auth0" ? .auth0 : .legacy
        let conn = dict["connection"] as? String ?? ""
        return .passwordlessOtp(connection: conn, identifiers: identifiers, type: flowType)
    }

}
