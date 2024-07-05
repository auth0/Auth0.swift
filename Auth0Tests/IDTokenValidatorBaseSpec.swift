import Foundation
import Quick

@testable import Auth0

class IDTokenValidatorBaseSpec: QuickSpec {
    static let domain = "tokens-test.auth0.com"
    static let clientId = "e31f6f9827c187e8aebdb0839a0c963a"
    static let nonce = "a1b2c3d4e5"
    static let leeway = 60 * 1000 // 60 seconds
    static let maxAge = 1000 // 1 second
    static let organization = "abc1234"
    
    // Can't override the initWithInvocation: initializer, because NSInvocation is not available in Swift
    static let authentication = Auth0.authentication(clientId: clientId, domain: domain)
    static let validatorContext = IDTokenValidatorContext(issuer: URL.httpsURL(from: domain).absoluteString,
                                                        audience: clientId,
                                                        jwksRequest: authentication.jwks(),
                                                        leeway: leeway,
                                                        maxAge: maxAge,
                                                        nonce: nonce,
                                                        organization: organization)
}
