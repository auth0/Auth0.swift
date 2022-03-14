#if WEB_AUTH_PLATFORM
import Foundation

struct IDTokenValidatorContext: IDTokenSignatureValidatorContext, IDTokenClaimsValidatorContext {
    let issuer: String
    let audience: String
    let jwksRequest: Request<JWKS, AuthenticationError>
    let leeway: Int
    let maxAge: Int?
    let nonce: String?
    let organization: String?
}

extension IDTokenValidatorContext {

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
