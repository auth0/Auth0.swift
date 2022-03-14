import Foundation
import Quick
import Nimble

@testable import Auth0

private let URL = Foundation.URL(string: "https://samples.auth0.com")!
private let JSONData = try! JSONSerialization.data(withJSONObject: ["attr": "value"], options: [])

private func http(_ statusCode: Int, url: Foundation.URL = URL) -> HTTPURLResponse {
    return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "1.0", headerFields: [:])!
}

class ResponseSpec: QuickSpec {
    override func spec() {

        describe("successful response") {

            it("should handle HTTP 204 responses") {
                let response = Response<AuthenticationError>(data: nil, response: http(204), error: nil)
                expect(try! response.result()).to(beNil())
            }

            it("should handle valid JSON") {
                let response = Response<AuthenticationError>(data: JSONData, response: http(200), error: nil)
                expect(try? response.result()).toNot(beNil())
            }

            it("should handle string as json for reset password") {
                let data = "A simple String".data(using: .utf8)
                let response = Response<AuthenticationError>(data: data, response: http(200, url: Foundation.URL(string: "https://samples.auth0.com/dbconnections/change_password")!), error: nil)
                expect(try! response.result()).to(beNil())
            }
        }

        describe("failed response") {

            it("should fail with empty response") {
                let response = Response<AuthenticationError>(data: nil, response: nil, error: nil)
                expect(try? response.result()).to(beNil())
            }

            it("should fail with code lesser than 200") {
                let response = Response<AuthenticationError>(data: nil, response: http(199), error: nil)
                expect(try? response.result()).to(beNil())
            }

            it("should fail with code greater than 200") {
                let response = Response<AuthenticationError>(data: nil, response: http(300), error: nil)
                expect(try? response.result()).to(beNil())
            }

            it("should fail with empty HTTP 200 responses") {
                let response = Response<AuthenticationError>(data: nil, response: http(200), error: nil)
                expect(try? response.result()).to(beNil())
            }

            it("should fail with invalid JSON") {
                let data = "A simple String".data(using: .utf8)
                let response = Response<AuthenticationError>(data: data, response: http(200), error: nil)
                expect(try? response.result()).to(beNil())
            }

            it("should fail with NSError") {
                let error = NSError(domain: "com.auth0", code: -99999, userInfo: nil)
                let response = Response<AuthenticationError>(data: nil, response: http(200), error: error)
                expect(try? response.result()).to(beNil())
            }

        }
    }
}
