import Quick
import Nimble
import OHHTTPStubs

@testable import Auth0

private let ClientId = "CLIENT_ID"
private let Domain = "samples.auth0.com"

class Auth0Spec: QuickSpec {
    override func spec() {

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

            it("should enable default logger for users") {
                let users = Auth0.users(token: "token", domain: Domain)
                expect(users.logging(enabled: true).logger).toNot(beNil())
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

        #if !SWIFT_PACKAGE
        describe("plist loading") {

            let bundle = Bundle(for: Auth0Spec.self)

            it("should return authentication endpoint with account from plist") {
                let auth = Auth0.authentication(bundle: bundle)
                expect(auth.url.absoluteString) == "https://samples.auth0.com/"
                expect(auth.clientId) == "CLIENT_ID"
            }

            it("should return users endpoint with domain from plist") {
                let users = Auth0.users(token: "TOKEN", bundle: bundle)
                expect(users.url.absoluteString) == "https://samples.auth0.com/"
            }

        }
        #endif

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
