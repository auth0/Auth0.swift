import Foundation
import Quick
import Nimble

@testable import Auth0

private let Domain = "samples.auth0.com"
private let Token = "TOKEN"

class MyAccountSpec: QuickSpec {

    override class func spec() {

        describe("global functions") {

            it("should return my account client with token and domain") {
                let myAccount = Auth0.myAccount(token: Token, domain: Domain)

                expect(myAccount.token) == Token
                expect(myAccount.url.absoluteString) == "https://\(Domain)/me/v1"
            }

            it("should return my account client with token, domain, and session") {
                let session = URLSession(configuration: URLSession.shared.configuration)
                let myAccount = Auth0.myAccount(token: Token, domain: Domain, session: session) as! Auth0MyAccount

                expect(myAccount.session).to(be(session))
            }
  
            #if !SWIFT_PACKAGE
            it("should return my account client with bundle") {
                let bundle = Bundle(for: Auth0Spec.self)
                let myAccount = Auth0.myAccount(token: Token, bundle: bundle)

                expect(myAccount.url.absoluteString) == "https://\(Domain)/me/v1"
            }
            #endif

        }

        describe("endpoint") {

            it("should return my account endpoint without trailing slash") {
                let myAccount = Auth0.myAccount(token: Token, domain: Domain)

                expect(myAccount.url.absoluteString) == "https://\(Domain)/me/v1"
            }

            it("should return my account endpoint with trailing slash") {
                let myAccount = Auth0.myAccount(token: Token, domain: "\(Domain)/")

                expect(myAccount.url.absoluteString) == "https://\(Domain)/me/v1"
            }

        }

        describe("logging") {

            it("should have no logging by default") {
                let myAccount = Auth0.myAccount(token: Token, domain: Domain)

                expect(myAccount.logger).to(beNil())
            }

            it("should enable default logger") {
                let myAccount = Auth0.myAccount(token: Token, domain: Domain)

                expect(myAccount.logging(enabled: true).logger).toNot(beNil())
            }

            it("should not enable default logger") {
                let myAccount = Auth0.myAccount(token: Token, domain: Domain)

                expect(myAccount.logging(enabled: false).logger).to(beNil())
            }

            it("should enable custom logger") {
                let logger = MockLogger()
                let myAccount = Auth0.myAccount(token: Token, domain: Domain)

                expect(myAccount.using(logger: logger).logger).toNot(beNil())
            }

        }

        describe("authentication methods sub-client") {

            it("should return authentication methods sub-client") {
                let session = URLSession(configuration: URLSession.shared.configuration)
                let myAccount = Auth0.myAccount(token: Token, domain: Domain, session: session)
                let authenticationMethods = myAccount.authenticationMethods as! Auth0AuthenticationMethods

                expect(authenticationMethods.token) == Token
                expect(authenticationMethods.url.absoluteString) == myAccount.url.absoluteString
                expect(authenticationMethods.session).to(be(session))
            }

            context("endpoint") {

                it("should return my account endpoint without trailing slash") {
                    let myAccount = Auth0.myAccount(token: Token, domain: Domain)

                    expect(myAccount.authenticationMethods.url.absoluteString) == "https://\(Domain)/me/v1"
                }

                it("should return my account endpoint with trailing slash") {
                    let myAccount = Auth0.myAccount(token: Token, domain: "\(Domain)/")

                    expect(myAccount.authenticationMethods.url.absoluteString) == "https://\(Domain)/me/v1"
                }

            }

            context("logging") {

                it("should have no logging by default") {
                    let myAccount = Auth0.myAccount(token: Token, domain: Domain)

                    expect(myAccount.authenticationMethods.logger).to(beNil())
                }

                it("should enable default logger") {
                    let myAccount = Auth0.myAccount(token: Token, domain: Domain)

                    expect(myAccount.authenticationMethods.logging(enabled: true).logger).toNot(beNil())
                }

                it("should not enable default logger") {
                    let myAccount = Auth0.myAccount(token: Token, domain: Domain)

                    expect(myAccount.authenticationMethods.logging(enabled: false).logger).to(beNil())
                }

                it("should enable custom logger") {
                    let logger = MockLogger()
                    let myAccount = Auth0.myAccount(token: Token, domain: Domain)

                    expect(myAccount.authenticationMethods.using(logger: logger).logger).toNot(beNil())
                }

            }

        }

    }

}
