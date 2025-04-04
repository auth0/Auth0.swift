import Foundation
import AuthenticationServices
import Quick
import Nimble

@testable import Auth0

private let AuthorizeURL = URL(string: "https://auth0.com")!
private let HTTPSRedirectURL = URL(string: "https://auth0.com/callback")!
private let CustomSchemeRedirectURL = URL(string: "com.auth0.example://samples.auth0.com/callback")!
private let Timeout: NimbleTimeInterval = .seconds(2)

class ASProviderSpec: QuickSpec {
    
    override class func spec() {
        
        var session: ASWebAuthenticationSession!
        var userAgent: ASUserAgent!
        
        beforeEach {
            session = ASWebAuthenticationSession(url: AuthorizeURL, callbackURLScheme: nil, completionHandler: { _, _ in })
            userAgent = ASUserAgent(session: session, callback: { _ in })
        }
        
        afterEach {
            session.cancel()
        }
        
        describe("WebAuthentication extension") {
            
            it("should create a web authentication session provider") {
                let provider = WebAuthentication.asProvider(redirectURL: HTTPSRedirectURL)
                expect(provider(AuthorizeURL, {_ in })).to(beAKindOf(ASUserAgent.self))
            }

            #if compiler(>=5.10)
            if #available(iOS 17.4, macOS 14.4, visionOS 1.2, *) {
                context("custom headers when using an HTTPS redirect URL") {

                    it("should not use custom headers by default") {
                        let provider = WebAuthentication.asProvider(redirectURL: HTTPSRedirectURL)
                        userAgent = provider(AuthorizeURL, { _ in }) as? ASUserAgent
                        expect(ASUserAgent.currentSession?.additionalHeaderFields).to(beNil())
                    }
                    
                    it("should use custom headers") {
                        let headers = ["X-Foo": "Bar", "X-Baz": "Qux"]
                        let provider = WebAuthentication.asProvider(redirectURL: HTTPSRedirectURL, headers: headers)
                        userAgent = provider(AuthorizeURL, { _ in }) as? ASUserAgent
                        expect(ASUserAgent.currentSession?.additionalHeaderFields) == headers
                    }

                }
                
                context("custom headers when using a custom scheme redirect URL") {

                    it("should not use custom headers by default") {
                        let provider = WebAuthentication.asProvider(redirectURL: CustomSchemeRedirectURL)
                        userAgent = provider(AuthorizeURL, { _ in }) as? ASUserAgent
                        expect(ASUserAgent.currentSession?.additionalHeaderFields).to(beNil())
                    }
                    
                    it("should use custom headers") {
                        let headers = ["X-Foo": "Bar", "X-Baz": "Qux"]
                        let provider = WebAuthentication.asProvider(redirectURL: CustomSchemeRedirectURL, headers: headers)
                        userAgent = provider(AuthorizeURL, { _ in }) as? ASUserAgent
                        expect(ASUserAgent.currentSession?.additionalHeaderFields) == headers
                    }

                }
            }
            #endif

            context("ephemeral sesssions") {

                it("should not use an ephemeral session by default") {
                    let provider = WebAuthentication.asProvider(redirectURL: CustomSchemeRedirectURL)
                    userAgent = provider(AuthorizeURL, { _ in }) as? ASUserAgent
                    expect(ASUserAgent.currentSession?.prefersEphemeralWebBrowserSession) == false
                }
                
                it("should use an ephemeral session") {
                    let provider = WebAuthentication.asProvider(redirectURL: CustomSchemeRedirectURL, ephemeralSession: true)
                    userAgent = provider(AuthorizeURL, { _ in }) as? ASUserAgent
                    expect(ASUserAgent.currentSession?.prefersEphemeralWebBrowserSession) == true
                }

            }
            
        }
        
        describe("user agent") {
            
            it("should have a custom description") {
                expect(userAgent.description) == "ASWebAuthenticationSession"
            }
            
            it("should be the web authentication session's presentation context provider") {
                expect(session.presentationContextProvider).to(be(userAgent))
            }
            
            it("should call the callback with an error") {
                waitUntil(timeout: Timeout) { done in
                    let userAgent = ASUserAgent(session: session, callback: { result in
                        expect(result).to(beFailure())
                        done()
                    })
                    userAgent.finish(with: .failure(.userCancelled))
                }
            }
            
            it("should call the callback with success") {
                waitUntil(timeout: Timeout) { done in
                    let userAgent = ASUserAgent(session: session, callback: { result in
                        expect(result).to(beSuccessful())
                        done()
                    })
                    userAgent.finish(with: .success(()))
                }
            }
        }
        
    }
    
}
