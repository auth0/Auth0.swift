import Foundation
import Quick
import Nimble

@testable import Auth0

private let URL = Foundation.URL(string: "https://samples.auth0.com")!
private let JSONData = try! JSONSerialization.data(withJSONObject: ["attr": "value"], options: [])

private func http(_ statusCode: Int, url: Foundation.URL = URL) -> HTTPURLResponse {
    return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "1.0", headerFields: ["Foo": "Bar"])!
}

class ResponseSpec: QuickSpec {
    override class func spec() {

        describe("successful response") {

            it("should handle empty HTTP 200 responses") {
                let response = Response<AuthenticationError>(data: nil, response: http(200), error: nil)
                let result = try response.result()
                expect(result.value.statusCode) == 200
                expect(result.data).to(beNil())
            }

            it("should handle HTTP 204 responses") {
                let response = Response<AuthenticationError>(data: nil, response: http(204), error: nil)
                let result = try response.result()
                expect(result.value.statusCode) == 204
                expect(result.data).to(beNil())
            }

            it("should handle valid JSON") {
                let response = Response<AuthenticationError>(data: JSONData, response: http(200), error: nil)
                let result: ResponseValue = try response.result()
                expect(result.value.statusCode) == 200
                expect(result.data) == JSONData
            }

            it("should handle plain text") {
                let data = "A simple String".data(using: .utf8)
                let response = Response<AuthenticationError>(data: data, response: http(200), error: nil)
                let result = try response.result()
                expect(result.value.statusCode) == 200
                expect(result.data) == data
            }

        }

        describe("failed response") {

            it("should fail with empty response") {
                let response = Response<AuthenticationError>(data: nil, response: nil, error: nil)
                expect({ try response.result() }).to(throwError())
            }

            it("should fail with empty data") {
                let response = Response<AuthenticationError>(data: nil, response: http(201), error: nil)
                expect({ try response.result() }).to(throwError())
            }

            it("should fail with NSError") {
                let error = NSError(domain: "com.auth0", code: -99999, userInfo: nil)
                let response = Response<AuthenticationError>(data: nil, response: http(200), error: error)
                expect({ try response.result() }).to(throwError())
            }

            it("should fail with code lesser than 200") {
                let response = Response<AuthenticationError>(data: nil, response: http(199), error: nil)
                expect({ try response.result() }).to(throwError())
            }

            it("should fail with code greater than 200") {
                let response = Response<AuthenticationError>(data: nil, response: http(300), error: nil)
                expect({ try response.result() }).to(throwError())
            }

        }

    }
}
