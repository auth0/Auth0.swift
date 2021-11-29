import Foundation

protocol OAuth2Grant {
    var defaults: [String: String] { get }
    func credentials(from values: [String: String], callback: @escaping (Auth0Result<Credentials>) -> Void)
    func values(fromComponents components: URLComponents) -> [String: String]
}

struct PKCE: OAuth2Grant {

    let authentication: Authentication
    let redirectURL: URL
    let defaults: [String: String]
    let verifier: String
    let issuer: String
    let leeway: Int
    let maxAge: Int?
    let organization: String?

    init(authentication: Authentication,
         generator: ChallengeGenerator = ChallengeGenerator(),
         redirectURL: URL,
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
         issuer: String,
         leeway: Int,
         maxAge: Int? = nil,
         nonce: String? = nil,
         organization: String? = nil) {
        self.authentication = authentication
        self.redirectURL = redirectURL
        self.verifier = verifier
        self.issuer = issuer
        self.leeway = leeway
        self.maxAge = maxAge
        self.organization = organization
        var newDefaults: [String: String] = [
            "code_challenge": challenge,
            "code_challenge_method": method
        ]
        newDefaults["nonce"] = nonce
        self.defaults = newDefaults
    }

    func credentials(from values: [String: String], callback: @escaping (Auth0Result<Credentials>) -> Void) {
        guard let code = values["code"] else {
            let string = "No code found in parameters \(values)"
            return callback(.failure(AuthenticationError(description: string)))
        }
        let authentication = self.authentication
        let verifier = self.verifier
        let redirectUrlString = self.redirectURL.absoluteString
        let validatorContext = IDTokenValidatorContext(authentication: authentication,
                                                       issuer: self.issuer,
                                                       leeway: self.leeway,
                                                       maxAge: self.maxAge,
                                                       nonce: self.defaults["nonce"],
                                                       organization: self.organization)
        authentication
            .tokenExchange(withCode: code, codeVerifier: verifier, redirectURI: redirectUrlString)
            .start { result in
                switch result {
                case .failure(let error as AuthenticationError) where error.localizedDescription == "Unauthorized":
                    // Special case for PKCE when the correct method for token endpoint authentication is not set (it should be None)
                    return callback(.failure(WebAuthError(code: .pkceNotAllowed)))
                case .failure(let error): return callback(.failure(WebAuthError(code: .other, cause: error)))
                case .success(let credentials):
                    validate(idToken: credentials.idToken, with: validatorContext) { error in
                        if let error = error {
                            return callback(.failure(WebAuthError(code: .idTokenValidationFailed, cause: error)))
                        }
                        callback(result)
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
