import Foundation
import Quick
import Nimble

@testable import Auth0

private let Domain = "samples.auth0.com"
private let Token = UUID().uuidString
private let DomainURL = URL(string: "https://\(Domain)")!

class ManagementSpec: QuickSpec {
    override func spec() {

        describe("init") {

            it("should init with token & url") {
                let management = Management(token: Token, url: DomainURL)
                expect(management).toNot(beNil())
            }

            it("should init with token, url & session") {
                let management = Management(token: Token, url: DomainURL, session: URLSession.shared)
                expect(management).toNot(beNil())
            }

            it("should have bearer token in authorization header") {
                let management = Management(token: Token, url: DomainURL)
                expect(management.defaultHeaders["Authorization"]) == "Bearer \(Token)"
            }
        }

        describe("object response handling") {
            let management = Management(token: Token, url: URL(string: "https://\(Domain)")!)

            context("success") {
                let data = "{\"key\": \"value\"}".data(using: .utf8)!
                let http = HTTPURLResponse(url: DomainURL, statusCode: 200, httpVersion: nil, headerFields: nil)

                it("should yield success with payload") {
                    let response = Response<ManagementError>(data: data, response: http, error: nil)
                    var actual: Auth0Result<ManagementObject>? = nil
                    management.managementObject(response: response) { actual = $0 }
                    expect(actual).toEventually(haveObjectWithAttributes(["key"]))
                }
            }

            context("failure") {

                it("should yield invalid json response") {
                    let data = "NOT JSON".data(using: .utf8)!
                    let http = HTTPURLResponse(url: DomainURL, statusCode: 200, httpVersion: nil, headerFields: nil)
                    let response = Response<ManagementError>(data: data, response: http, error: nil)
                    var actual: Auth0Result<ManagementObject>? = nil
                    management.managementObject(response: response) { actual = $0 }
                    expect(actual).toEventually(beFailure())
                }

                it("should yield invalid response") {
                    let data = "[{\"key\": \"value\"}]".data(using: .utf8)!
                    let http = HTTPURLResponse(url: DomainURL, statusCode: 200, httpVersion: nil, headerFields: nil)
                    let response = Response<ManagementError>(data: data, response: http, error: nil)
                    var actual: Auth0Result<ManagementObject>? = nil
                    management.managementObject(response: response) { actual = $0 }
                    expect(actual).toEventually(beFailure())
                }

                it("should yield generic failure when error response is unknown") {
                    let data = "[{\"key\": \"value\"}]".data(using: .utf8)!
                    let http = HTTPURLResponse(url: DomainURL, statusCode: 400, httpVersion: nil, headerFields: nil)
                    let response = Response<ManagementError>(data: data, response: http, error: nil)
                    var actual: Auth0Result<ManagementObject>? = nil
                    management.managementObject(response: response) { actual = $0 }
                    expect(actual).toEventually(beFailure())
                }

                it("should yield server error") {
                    let error = ["error": "error", "description": "description", "code": "code", "statusCode": 400] as [String : Any]
                    let data = try? JSONSerialization.data(withJSONObject: error, options: [])
                    let http = HTTPURLResponse(url: DomainURL, statusCode: 400, httpVersion: nil, headerFields: nil)
                    let response = Response<ManagementError>(data: data, response: http, error: nil)
                    var actual: Auth0Result<ManagementObject>? = nil
                    management.managementObject(response: response) { actual = $0 }
                    expect(actual).toEventually(haveManagementError("error", description: "description", code: "code", statusCode: 400))
                }

                it("should yield generic failure when no payload") {
                    let http = HTTPURLResponse(url: DomainURL, statusCode: 400, httpVersion: nil, headerFields: nil)
                    let response = Response<ManagementError>(data: nil, response: http, error: nil)
                    var actual: Auth0Result<ManagementObject>? = nil
                    management.managementObject(response: response) { actual = $0 }
                    expect(actual).toEventually(beFailure())
                }

                it("should yield generic failure") {
                    let response = Response<ManagementError>(data: nil, response: nil, error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
                    var actual: Auth0Result<ManagementObject>? = nil
                    management.managementObject(response: response) { actual = $0 }
                    expect(actual).toEventually(beFailure())
                }

            }

        }
    }
}
