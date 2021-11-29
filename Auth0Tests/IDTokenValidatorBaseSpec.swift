import Foundation
import Quick

@testable import Auth0

class IDTokenValidatorBaseSpec: QuickSpec {
    let domain = "tokens-test.auth0.com"
    let clientId = "e31f6f9827c187e8aebdb0839a0c963a"
    let nonce = "a1b2c3d4e5"
    let leeway = 60 * 1000 // 60 seconds
    let maxAge = 1000 // 1 second
    let organization = "abc1234"
    
    // Can't override the initWithInvocation: initializer, because NSInvocation is not available in Swift
    lazy var authentication = Auth0.authentication(clientId: clientId, domain: domain)
    lazy var validatorContext = IDTokenValidatorContext(issuer: URL.httpsURL(from: domain).absoluteString,
                                                        audience: clientId,
                                                        jwksRequest: authentication.jwks(),
                                                        leeway: leeway,
                                                        maxAge: maxAge,
                                                        nonce: nonce,
                                                        organization: organization)
}
