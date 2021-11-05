#if WEB_AUTH_PLATFORM
import Foundation

struct IDTokenValidatorContext: IDTokenSignatureValidatorContext, IDTokenClaimsValidatorContext {
    let issuer: String
    let audience: String
    let jwksRequest: Request<JWKS, AuthenticationError>
    let nonce: String?
    let leeway: Int
    let maxAge: Int?
    let organization: String?

    init(issuer: String,
         audience: String,
         jwksRequest: Request<JWKS, AuthenticationError>,
         leeway: Int,
         maxAge: Int?,
         nonce: String?,
         organization: String?) {
        self.issuer = issuer
        self.audience = audience
        self.jwksRequest = jwksRequest
        self.leeway = leeway
        self.maxAge = maxAge
        self.nonce = nonce
        self.organization = organization
    }

    init(authentication: Authentication,
         issuer: String,
         leeway: Int,
         maxAge: Int?,
         nonce: String?,
         organization: String?) {
        self.init(issuer: issuer,
                  audience: authentication.clientId,
                  jwksRequest: authentication.jwks(),
                  leeway: leeway,
                  maxAge: maxAge,
                  nonce: nonce,
                  organization: organization)
    }
}
#endif
