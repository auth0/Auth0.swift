import Foundation
import Quick
import Nimble

@testable import Auth0

private let ClientId = "CLIENT_ID"
private let Domain = "samples.auth0.com"
private let Token = "TOKEN"

class Auth0Spec: QuickSpec {

    override func spec() {

        describe("global functions") {

            context("authentication") {

                it("should return authentication client with client id & domain") {
                    let authentication = Auth0.authentication(clientId: ClientId,
                                                              domain: Domain)
                    expect(authentication.clientId) == ClientId
                    expect(authentication.url.absoluteString) == "https://\(Domain)/"
                }

                it("should return authentication client with client id, domain & session") {
                    let session = URLSession(configuration: URLSession.shared.configuration)
                    let authentication = Auth0.authentication(clientId: ClientId,
                                                              domain: Domain,
                                                              session: session) as! Auth0Authentication
                    expect(authentication.session).to(be(session))
                }

            }

            context("users") {

                it("should return users client with token & domain") {
                    let users = Auth0.users(token: Token, domain: Domain)
                    expect(users.token) == Token
                    expect(users.url.absoluteString) == "https://\(Domain)/"
                }

                it("should return users client with token, domain & session") {
                    let session = URLSession(configuration: URLSession.shared.configuration)
                    let users = Auth0.users(token: Token,
                                            domain: Domain,
                                            session: session) as! Management
                    expect(users.session).to(be(session))
                }

            }

            #if WEB_AUTH_PLATFORM
            context("web auth") {

                it("should return web auth client with client id & domain") {
                    let webAuth = Auth0.webAuth(clientId: ClientId, domain: Domain)
                    expect(webAuth.clientId) == ClientId
                    expect(webAuth.url.absoluteString) == "https://\(Domain)/"
                }

                it("should return web auth client with client id, domain & session") {
                    let session = URLSession(configuration: URLSession.shared.configuration)
                    let webAuth = Auth0.webAuth(clientId: ClientId,
                                                domain: Domain,
                                                session: session) as! Auth0WebAuth
                    expect(webAuth.session).to(be(session))
                }

            }
            #endif

            #if !SWIFT_PACKAGE
            describe("plist loading") {

                let bundle = Bundle(for: Auth0Spec.self)

                it("should return authentication client with bundle") {
                    let auth = Auth0.authentication(bundle: bundle)
                    expect(auth.url.absoluteString) == "https://\(Domain)/"
                    expect(auth.clientId) == ClientId
                }

                it("should return authentication client with bundle & session") {
                    let session = URLSession(configuration: URLSession.shared.configuration)
                    let authentication = Auth0.authentication(session: session, bundle: bundle) as! Auth0Authentication
                    expect(authentication.session).to(be(session))
                }

                it("should return users client with bundle") {
                    let users = Auth0.users(token: Token, bundle: bundle)
                    expect(users.url.absoluteString) == "https://\(Domain)/"
                }

                #if WEB_AUTH_PLATFORM
                it("should return web auth client with bundle") {
                    let auth = Auth0.webAuth(bundle: bundle)
                    expect(auth.url.absoluteString) == "https://\(Domain)/"
                    expect(auth.clientId) == ClientId
                }

                it("should return web auth client with bundle & session") {
                    let session = URLSession(configuration: URLSession.shared.configuration)
                    let webAuth = Auth0.webAuth(session: session, bundle: bundle) as! Auth0WebAuth
                    expect(webAuth.session).to(be(session))
                }
                #endif

            }
            #endif

        }

        describe("logging") {

            it("should have no logging for auth by default") {
                expect(Auth0.authentication(clientId: ClientId, domain: Domain).logger).to(beNil())
            }

            it("should have no logging for management by default") {
                expect(Auth0.users(token: "token", domain: Domain).logger).to(beNil())
            }

            it("should enable default logger for auth") {
                let auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                expect(auth.logging(enabled: true).logger).toNot(beNil())
            }

            it("should not enable default logger for auth") {
                let auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                expect(auth.logging(enabled: false).logger).to(beNil())
            }

            it("should enable default logger for users") {
                let users = Auth0.users(token: "token", domain: Domain)
                expect(users.logging(enabled: true).logger).toNot(beNil())
            }

            it("should not enable default logger for users") {
                let users = Auth0.users(token: "token", domain: Domain)
                expect(users.logging(enabled: false).logger).to(beNil())
            }

            it("should enable custom logger for auth") {
                let logger = MockLogger()
                let auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                expect(auth.using(logger: logger).logger).toNot(beNil())
            }

            it("should enable custom logger for users") {
                let logger = MockLogger()
                let users = Auth0.users(token: "token", domain: Domain)
                expect(users.using(logger: logger).logger).toNot(beNil())
            }

        }

        describe("endpoints") {

            context("without trailing slash") {

                it("should return authentication endpoint with clientId and domain") {
                    let auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                    expect(auth).toNot(beNil())
                    expect(auth.clientId) ==  ClientId
                    expect(auth.url.absoluteString) == "https://\(Domain)/"
                }

                it("should return authentication endpoint with domain url") {
                    let domain = "https://mycustomdomain.com"
                    let auth = Auth0.authentication(clientId: ClientId, domain: domain)
                    expect(auth.url.absoluteString) == "\(domain)/"
                }

                it("should return authentication endpoint with domain url and a subpath") {
                    let domain = "https://mycustomdomain.com/foo"
                    let auth = Auth0.authentication(clientId: ClientId, domain: domain)
                    expect(auth.url.absoluteString) == "\(domain)/"
                }

                it("should return authentication endpoint with domain url and subpaths") {
                    let domain = "https://mycustomdomain.com/foo/bar"
                    let auth = Auth0.authentication(clientId: ClientId, domain: domain)
                    expect(auth.url.absoluteString) == "\(domain)/"
                }

                it("should return users endpoint") {
                    let users = Auth0.users(token: "token", domain: Domain)
                    expect(users.token) == "token"
                    expect(users.url.absoluteString) == "https://\(Domain)/"
                }

            }

            context("with trailing slash") {

                it("should return authentication endpoint with clientId and domain") {
                    let auth = Auth0.authentication(clientId: ClientId, domain: "\(Domain)/")
                    expect(auth).toNot(beNil())
                    expect(auth.clientId) ==  ClientId
                    expect(auth.url.absoluteString) == "https://\(Domain)/"
                }

                it("should return authentication endpoint with domain url") {
                    let domain = "https://mycustomdomain.com/"
                    let auth = Auth0.authentication(clientId: ClientId, domain: domain)
                    expect(auth.url.absoluteString) == domain
                }

                it("should return authentication endpoint with domain url with a subpath") {
                    let domain = "https://mycustomdomain.com/foo/"
                    let auth = Auth0.authentication(clientId: ClientId, domain: domain)
                    expect(auth.url.absoluteString) == domain
                }

                it("should return authentication endpoint with domain url with subpaths") {
                    let domain = "https://mycustomdomain.com/foo/bar/"
                    let auth = Auth0.authentication(clientId: ClientId, domain: domain)
                    expect(auth.url.absoluteString) == domain
                }

                it("should return users endpoint") {
                    let users = Auth0.users(token: "token", domain: Domain)
                    expect(users.token) == "token"
                    expect(users.url.absoluteString) == "https://\(Domain)/"
                }

            }

        }

    }

}

class MockLogger: Logger {

    func trace(url: URL, source: String?) {

    }

    func trace(response: URLResponse, data: Data?) {

    }

    func trace(request: URLRequest, session: URLSession) {

    }
}
