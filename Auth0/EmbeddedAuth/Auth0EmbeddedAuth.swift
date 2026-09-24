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

// MARK: - Wire types (Decodable)

struct DiscoveryResponse: Decodable {
    let alternatives: [DiscoveryAlternativePayload]
}

struct DiscoveryAlternativePayload: Decodable {

    let grantType: String
    let connection: String?
    let type: String?
    let subjectTokenType: String?
    let identifierTypes: [String]?
    let realm: String?

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case connection
        case type
        case subjectTokenType = "subject_token_type"
        case identifierTypes = "identifier_types"
        case realm
    }

    var loginOption: LoginOption? {
        switch grantType {
        case GrantTypeValue.authorizationCode:
            if let connection {
                return .authorizationCode(connection: connection, type: type)
            }
        case GrantTypeValue.tokenExchange:
            if let subjectTokenType {
                return .nativeSocial(subjectTokenType: subjectTokenType)
            }
        case GrantTypeValue.password:
            return .password
        case GrantTypeValue.webAuthn:
            if let connection {
                return .passkey(connection: connection)
            }
        case GrantTypeValue.passwordlessOTP:
            if let identifierTypes, let connection = connection {
                let identifiers: [PasswordlessIdentifier] = (identifierTypes).compactMap {
                    switch $0 {
                    case IdentifierTypeValue.email:       return .email
                    case IdentifierTypeValue.phoneNumber: return .phoneNumber
                    default:                              return nil
                    }
                }
                return .passwordlessOtp(connection: connection,
                                        identifiers: identifiers,
                                        type: type == TypeValue.auth0 ? .auth0 : .legacy)
            }
        case GrantTypeValue.passwordRealm:
            if let realm {
                return .passwordRealm(realm: realm)
            }
        default:
            return .unknown(rawGrantType: grantType, connection: connection)
        }
        return nil
    }

}
