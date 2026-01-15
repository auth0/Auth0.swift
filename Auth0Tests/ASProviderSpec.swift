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
            
            it("should clear currentSession after finish with success") {
                let provider = WebAuthentication.asProvider(redirectURL: CustomSchemeRedirectURL)
                let userAgent = provider(AuthorizeURL, { _ in }) as? ASUserAgent
                
                // Verify session is set during initialization
                expect(ASUserAgent.currentSession).toNot(beNil())
                
                // Finish the authentication
                userAgent?.finish(with: .success(()))
                
                // Verify currentSession is cleared to prevent memory leak
                expect(ASUserAgent.currentSession).to(beNil())
            }
            
            it("should clear currentSession after finish with failure") {
                let provider = WebAuthentication.asProvider(redirectURL: CustomSchemeRedirectURL)
                let userAgent = provider(AuthorizeURL, { _ in }) as? ASUserAgent
                
                // Verify session is set during initialization
                expect(ASUserAgent.currentSession).toNot(beNil())
                
                // Finish the authentication with error
                userAgent?.finish(with: .failure(.userCancelled))
                
                // Verify currentSession is cleared to prevent memory leak
                expect(ASUserAgent.currentSession).to(beNil())
            }
            
            it("should not leak sessions across multiple authentication cycles") {
                // First authentication cycle
                let provider1 = WebAuthentication.asProvider(redirectURL: CustomSchemeRedirectURL)
                let userAgent1 = provider1(AuthorizeURL, { _ in }) as? ASUserAgent
                let firstSession = ASUserAgent.currentSession
                expect(firstSession).toNot(beNil())
                
                // Complete first authentication
                userAgent1?.finish(with: .success(()))
                expect(ASUserAgent.currentSession).to(beNil())
                
                // Second authentication cycle
                let provider2 = WebAuthentication.asProvider(redirectURL: CustomSchemeRedirectURL)
                let userAgent2 = provider2(AuthorizeURL, { _ in }) as? ASUserAgent
                let secondSession = ASUserAgent.currentSession
                expect(secondSession).toNot(beNil())
                
                // Verify sessions are different instances
                expect(firstSession).toNot(be(secondSession))
                
                // Complete second authentication
                userAgent2?.finish(with: .success(()))
                expect(ASUserAgent.currentSession).to(beNil())
            }
        }
        
    }
    
}
