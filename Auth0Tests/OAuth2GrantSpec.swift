import Quick
import Nimble
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif

@testable import Auth0

class OAuth2GrantSpec: QuickSpec {

    override func spec() {

        let domain = URL.httpsURL(from: "samples.auth0.com")
        let authentication = Auth0Authentication(clientId: "CLIENT_ID", url: domain)
        let idToken = generateJWT(iss: "\(domain.absoluteString)/", aud: [authentication.clientId]).string
        let nonce = "a1b2c3d4e5"
        let issuer = "\(domain.absoluteString)/"
        let leeway = 60 * 1000

        beforeEach {
            stub(condition: isHost(domain.host!)) { _ in catchAllResponse() }.name = "YOU SHALL NOT PASS!"
        }

        afterEach {
            HTTPStubs.removeAllStubs()
        }

        describe("Authorization Code w/PKCE") {

            let method = "S256"
            let redirectURL = URL(string: "https://samples.auth0.com/callback")!
            var verifier: String!
            var challenge: String!
            var pkce: PKCE!

            beforeEach {
                verifier = "\(arc4random())"
                challenge = "\(arc4random())"
                pkce = PKCE(authentication: authentication, redirectURL: redirectURL, verifier: verifier, challenge: challenge, method: method, issuer: issuer, leeway: leeway, nonce: nil)
            }


            it("shoud build credentials") {
                let token = UUID().uuidString
                let code = UUID().uuidString
                let values = ["code": code]
                stub(condition: isToken(domain.host!) && hasAtLeast(["code": code, "code_verifier": pkce.verifier, "grant_type": "authorization_code", "redirect_uri": pkce.redirectURL.absoluteString])) { _ in
                    return authResponse(accessToken: token, idToken: idToken)
                }.name = "Code Exchange Auth"
                stub(condition: isJWKSPath(domain.host!)) { _ in jwksResponse() }
                waitUntil { done in
                    pkce.credentials(from: values) {
                        expect($0).to(haveCredentials(token))
                        done()
                    }
                }
            }

            it("shoud report error to get credentials") {
                waitUntil { done in
                    pkce.credentials(from: [:]) {
                        expect($0).to(beFailure())
                        done()
                    }
                }
            }

            it("should specify pkce parameters") {
                expect(pkce.defaults["code_challenge_method"]) == "S256"
                expect(pkce.defaults["code_challenge"]) == challenge
            }

            it("should get values from generator") {
                let generator = ChallengeGenerator()
                let authentication = Auth0Authentication(clientId: "CLIENT_ID", url: domain)
                pkce = PKCE(authentication: authentication, generator: generator, redirectURL: redirectURL, issuer: issuer, leeway: leeway, nonce: nil)
                
                expect(pkce.defaults["code_challenge_method"]) == generator.method
                expect(pkce.defaults["code_challenge"]) == generator.challenge
                expect(pkce.verifier) == generator.verifier
            }
        }

        describe("Authorization Code w/PKCE and idToken") {

            let domain = URL.httpsURL(from: "samples.auth0.com")
            let method = "S256"
            let redirectURL = URL(string: "https://samples.auth0.com/callback")!
            var verifier: String!
            var challenge: String!
            var pkce: PKCE!
            var authentication: Auth0Authentication!

            beforeEach {
                verifier = "\(arc4random())"
                challenge = "\(arc4random())"
                authentication = Auth0Authentication(clientId: "CLIENT_ID", url: domain)
                pkce = PKCE(authentication: authentication, redirectURL: redirectURL, verifier: verifier, challenge: challenge, method: method, issuer: issuer, leeway: leeway, nonce: nonce)
            }

            it("shoud build credentials") {
                let token = UUID().uuidString
                let code = UUID().uuidString
                let values = ["code": code, "nonce": nonce]
                stub(condition: isToken(domain.host!) && hasAtLeast(["code": code, "code_verifier": pkce.verifier, "grant_type": "authorization_code", "redirect_uri": pkce.redirectURL.absoluteString])) { _ in return authResponse(accessToken: token, idToken: idToken) }.name = "Code Exchange Auth"
                stub(condition: isJWKSPath(domain.host!)) { _ in jwksResponse() }
                waitUntil { done in
                    pkce.credentials(from: values) {
                        expect($0).to(haveCredentials(token))
                        done()
                    }
                }
            }

            it("should produce id token validation failed error") {
                pkce = PKCE(authentication: authentication, redirectURL: redirectURL, verifier: verifier, challenge: challenge, method: method, issuer: issuer, leeway: leeway, nonce: nonce)
                let token = UUID().uuidString
                let code = UUID().uuidString
                let values = ["code": code, "nonce": nonce]
                let idToken = generateJWT(iss: nil, nonce: nonce).string
                let expectedError = WebAuthError(code: .idTokenValidationFailed, cause: IDTokenIssValidator.ValidationError.missingIss)
                stub(condition: isToken(domain.host!) && hasAtLeast(["code": code, "code_verifier": pkce.verifier, "grant_type": "authorization_code", "redirect_uri": pkce.redirectURL.absoluteString])) { _ in return authResponse(accessToken: token, idToken: idToken) }.name = "Code Exchange Auth"
                stub(condition: isJWKSPath(domain.host!)) { _ in jwksResponse() }
                waitUntil { done in
                    pkce.credentials(from: values) {
                        expect($0).to(haveWebAuthError(expectedError))
                        done()
                    }
                }
            }

            it("should produce pkce not allowed error") {
                pkce = PKCE(authentication: authentication, redirectURL: redirectURL, verifier: verifier, challenge: challenge, method: method, issuer: issuer, leeway: leeway, nonce: nonce)
                let code = UUID().uuidString
                let values = ["code": code, "nonce": nonce]
                let expectedError = WebAuthError(code: .pkceNotAllowed)
                stub(condition: isToken(domain.host!) && hasAtLeast(["code": code, "code_verifier": pkce.verifier, "grant_type": "authorization_code", "redirect_uri": pkce.redirectURL.absoluteString])) { _ in
                    return authFailure(error: "foo", description: "Unauthorized")
                }.name = "Failed Code Exchange Auth"
                waitUntil { done in
                    pkce.credentials(from: values) {
                        expect($0).to(haveWebAuthError(expectedError))
                        done()
                    }
                }
            }

            it("should produce other error") {
                pkce = PKCE(authentication: authentication, redirectURL: redirectURL, verifier: verifier, challenge: challenge, method: method, issuer: issuer, leeway: leeway, nonce: nonce)
                let code = UUID().uuidString
                let values = ["code": code, "nonce": nonce]
                let cause = AuthenticationError(info: ["error": "foo", "error_description": "bar"])
                let expectedError = WebAuthError(code: .other, cause: cause)
                stub(condition: isToken(domain.host!) && hasAtLeast(["code": code, "code_verifier": pkce.verifier, "grant_type": "authorization_code", "redirect_uri": pkce.redirectURL.absoluteString])) { _ in
                    return authFailure(error: "foo", description: "bar")
                }.name = "Failed Code Exchange Auth"
                waitUntil { done in
                    pkce.credentials(from: values) {
                        expect($0).to(haveWebAuthError(expectedError))
                        done()
                    }
                }
            }

            it("shoud report error to get credentials") {
                waitUntil { done in
                    pkce.credentials(from: [:]) {
                        expect($0).to(beFailure())
                        done()
                    }
                }
            }

            it("should specify pkce parameters") {
                expect(pkce.defaults["code_challenge_method"]) == "S256"
                expect(pkce.defaults["code_challenge"]) == challenge
            }

            it("should get values from generator") {
                let generator = ChallengeGenerator()
                let authentication = Auth0Authentication(clientId: "CLIENT_ID", url: domain)
                pkce = PKCE(authentication: authentication, generator: generator, redirectURL: redirectURL, issuer: issuer, leeway: leeway, nonce: nonce)

                expect(pkce.defaults["code_challenge_method"]) == generator.method
                expect(pkce.defaults["code_challenge"]) == generator.challenge
                expect(pkce.verifier) == generator.verifier
            }
        }
    }
    
}
