import Foundation
import AuthenticationServices
import Quick
import Nimble

@testable import Auth0

private let Url = URL(string: "https://auth0.com")!
private let Timeout: DispatchTimeInterval = .seconds(2)

class ASProviderSpec: QuickSpec {

    override func spec() {

        var session: ASWebAuthenticationSession!
        var userAgent: ASUserAgent!

        beforeEach {
            session = ASWebAuthenticationSession(url: Url, callbackURLScheme: nil, completionHandler: { _, _ in })
            userAgent = ASUserAgent(session: session, callback: { _ in })
        }

        afterEach {
            session.cancel()
        }

        describe("WebAuthentication extension") {

            it("should create a web authentication session provider") {
                let provider = WebAuthentication.asProvider(urlScheme: Url.scheme!)
                expect(provider(Url, {_ in })).to(beAKindOf(ASUserAgent.self))
            }

            if #available(iOS 13.0, *) {
                it("should not use an ephemeral session by default") {
                    userAgent = WebAuthentication.asProvider(urlScheme: Url.scheme!)(Url, { _ in }) as? ASUserAgent
                    expect(userAgent.session.prefersEphemeralWebBrowserSession) == false
                }

                it("should use an ephemeral session") {
                    userAgent = WebAuthentication.asProvider(urlScheme: Url.scheme!,
                                                             ephemeralSession: true)(Url, { _ in }) as? ASUserAgent
                    expect(userAgent.session.prefersEphemeralWebBrowserSession) == true
                }
            }
        }

        describe("user agent") {

            it("should have a custom description") {
                expect(userAgent.description) == "ASWebAuthenticationSession"
            }

            if #available(iOS 13.0, *) {
                it("should be the web authentication session's presentation context provider") {
                    expect(session.presentationContextProvider).to(be(userAgent))
                }
            }

            if #available(iOS 13.4, macOS 10.15.4,  *) {
                it("should start the web authentication session") {
                    expect(session.canStart) == true
                    userAgent.start()
                    expect(session.canStart) == false
                }
            }

            it("should call the callback with an error") {
                waitUntil(timeout: Timeout) { done in
                    let userAgent = ASUserAgent(session: session, callback: { result in
                        expect(result).to(beFailure())
                        done()
                    })
                    let callback = userAgent.finish()
                    callback(.failure(.userCancelled))
                }
            }

            it("should call the callback with success") {
                waitUntil(timeout: Timeout) { done in
                    let userAgent = ASUserAgent(session: session, callback: { result in
                        expect(result).to(beSuccessful())
                        done()
                    })
                    let callback = userAgent.finish()
                    callback(.success(()))
                }
            }

        }

    }

}
