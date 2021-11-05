#if WEB_AUTH_PLATFORM
import Foundation
import JWTDecode
#if SWIFT_PACKAGE
import Auth0ObjectiveC
#endif

protocol OAuth2Grant {
    var defaults: [String: String] { get }
    func credentials(from values: [String: String], callback: @escaping (Result<Credentials>) -> Void)
    func values(fromComponents components: URLComponents) -> [String: String]
}

struct ImplicitGrant: OAuth2Grant {

    let authentication: Authentication
    let defaults: [String: String]
    let responseType: [ResponseType]
    let issuer: String
    let leeway: Int
    let maxAge: Int?
    let organization: String?

    init(authentication: Authentication,
         responseType: [ResponseType] = [.token],
         issuer: String,
         leeway: Int,
         maxAge: Int? = nil,
         nonce: String? = nil,
         organization: String? = nil) {
        self.authentication = authentication
        self.responseType = responseType
        self.issuer = issuer
        self.leeway = leeway
        self.maxAge = maxAge
        if let nonce = nonce {
            self.defaults = ["nonce": nonce]
        } else {
            self.defaults = [:]
        }
        self.organization = organization
    }

    func credentials(from values: [String: String], callback: @escaping (Result<Credentials>) -> Void) {
        let responseType = self.responseType
        let validatorContext = IDTokenValidatorContext(authentication: authentication,
                                                       issuer: issuer,
                                                       leeway: leeway,
                                                       maxAge: maxAge,
                                                       nonce: self.defaults["nonce"],
                                                       organization: self.organization)
        validateFrontChannelIDToken(idToken: values["id_token"], for: responseType, with: validatorContext) { error in
            if let error = error { return callback(.failure(error)) }
            guard !responseType.contains(.token) || values["access_token"] != nil else {
                return callback(.failure(WebAuthError.missingAccessToken))
            }
            callback(.success(Credentials(json: values as [String: Any])))
        }
    }

    func values(fromComponents components: URLComponents) -> [String: String] {
        return components.a0_fragmentValues
    }

}

struct PKCE: OAuth2Grant {

    let authentication: Authentication
    let redirectURL: URL
    let defaults: [String: String]
    let verifier: String
    let responseType: [ResponseType]
    let issuer: String
    let leeway: Int
    let maxAge: Int?
    let organization: String?

    init(authentication: Authentication,
         redirectURL: URL,
         generator: A0SHA256ChallengeGenerator = A0SHA256ChallengeGenerator(),
         responseType: [ResponseType] = [.code],
         issuer: String,
         leeway: Int,
         maxAge: Int? = nil,
         nonce: String? = nil,
         organization: String? = nil) {
        self.init(authentication: authentication,
                  redirectURL: redirectURL,
                  verifier: generator.verifier,
                  challenge: generator.challenge,
                  method: generator.method,
                  responseType: responseType,
                  issuer: issuer,
                  leeway: leeway,
                  maxAge: maxAge,
                  nonce: nonce,
                  organization: organization)
    }

    init(authentication: Authentication,
         redirectURL: URL,
         verifier: String,
         challenge: String,
         method: String,
         responseType: [ResponseType],
         issuer: String,
         leeway: Int,
         maxAge: Int? = nil,
         nonce: String? = nil,
         organization: String? = nil) {
        self.authentication = authentication
        self.redirectURL = redirectURL
        self.verifier = verifier
        self.responseType = responseType
        self.issuer = issuer
        self.leeway = leeway
        self.maxAge = maxAge
        self.organization = organization
        var newDefaults: [String: String] = [
            "code_challenge": challenge,
            "code_challenge_method": method
        ]
        if let nonce = nonce {
            newDefaults["nonce"] = nonce
        }
        self.defaults = newDefaults
    }

    func credentials(from values: [String: String], callback: @escaping (Result<Credentials>) -> Void) {
        guard let code = values["code"] else {
            let string = "No code found in parameters \(values)"
            return callback(.failure(AuthenticationError(string: string)))
        }
        let isFrontChannelIdTokenExpected = responseType.contains(.idToken)
        let frontChannelIdToken = values["id_token"]
        let responseType = self.responseType
        let authentication = self.authentication
        let verifier = self.verifier
        let redirectUrlString = self.redirectURL.absoluteString
        let clientId = authentication.clientId
        let validatorContext = IDTokenValidatorContext(authentication: authentication,
                                                       issuer: self.issuer,
                                                       leeway: self.leeway,
                                                       maxAge: self.maxAge,
                                                       nonce: self.defaults["nonce"],
                                                       organization: self.organization)
        validateFrontChannelIDToken(idToken: frontChannelIdToken, for: responseType, with: validatorContext) { error in
            if let error = error { return callback(.failure(error)) }
            authentication
                .tokenExchange(withCode: code, codeVerifier: verifier, redirectURI: redirectUrlString)
                .start { result in
                    switch result {
                    case .failure(let error as AuthenticationError) where error.description == "Unauthorized":
                        // Special case for PKCE when the correct method for token endpoint authentication is not set (it should be None)
                        let webAuthError = WebAuthError.pkceNotAllowed("Unable to complete authentication with PKCE. PKCE support can be enabled by setting Application Type to 'Native' and Token Endpoint Authentication Method to 'None' for this app at 'https://manage.auth0.com/#/applications/\(clientId)/settings'.")
                        return callback(.failure(webAuthError))
                    case .failure(let error): return callback(.failure(error))
                    case .success(let credentials):
                        guard isFrontChannelIdTokenExpected else {
                            return validate(idToken: credentials.idToken, with: validatorContext) { error in
                                if let error = error { return callback(.failure(error)) }
                                callback(result)
                            }
                        }
                        let newCredentials = Credentials(accessToken: credentials.accessToken,
                                                         tokenType: credentials.tokenType,
                                                         idToken: frontChannelIdToken!,
                                                         refreshToken: credentials.refreshToken,
                                                         expiresIn: credentials.expiresIn,
                                                         scope: credentials.scope)
                        return callback(.success(newCredentials))
                    }
            }
        }
    }

    func values(fromComponents components: URLComponents) -> [String: String] {
        var items = components.a0_fragmentValues
        components.a0_queryValues.forEach { items[$0] = $1 }
        return items
    }

}

// This method will skip the validation if the response type does not contain "id_token"
private func validateFrontChannelIDToken(idToken: String?,
                                         for responseType: [ResponseType],
                                         with context: IDTokenValidatorContext,
                                         callback: @escaping (LocalizedError?) -> Void) {
    guard responseType.contains(.idToken), let idToken = idToken else { return callback(nil) }
    validate(idToken: idToken, with: context) { error in
        if let error = error { return callback(error) }
        callback(nil)
    }
}
#endif
