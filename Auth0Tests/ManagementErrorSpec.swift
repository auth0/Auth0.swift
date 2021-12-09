import Foundation
import Quick
import Nimble

@testable import Auth0

class ManagementErrorSpec: QuickSpec {

    override func spec() {

        describe("init") {

            it("should initialize with info") {
                let info: [String: Any] = ["foo": "bar"]
                let error = ManagementError(info: info)
                expect(error.info["foo"] as? String) == "bar"
                expect(error.info.count) == 2
                expect(error.statusCode) == 0
                expect(error.cause).to(beNil())
            }

            it("should initialize with info & status code") {
                let info: [String: Any] = ["foo": "bar"]
                let statusCode = 400
                let error = ManagementError(info: info, statusCode: statusCode)
                expect(error.statusCode) == statusCode
            }

            it("should initialize with cause") {
                let cause = NSError(domain: "com.auth0", code: -99999, userInfo: nil)
                let error = ManagementError(cause: cause)
                expect(error.cause).to(matchError(cause))
                expect(error.statusCode) == 0
            }

            it("should initialize with cause & status code") {
                let cause = NSError(domain: "com.auth0", code: -99999, userInfo: nil)
                let statusCode = 400
                let error = ManagementError(cause: cause, statusCode: statusCode)
                expect(error.statusCode) == statusCode
            }

            it("should initialize with description") {
                let description = "foo"
                let error = ManagementError(description: description)
                expect(error.localizedDescription) == description
                expect(error.statusCode) == 0
                expect(error.cause).to(beNil())
            }

            it("should initialize with description & status code") {
                let description = "foo"
                let statusCode = 400
                let error = ManagementError(description: description, statusCode: statusCode)
                expect(error.statusCode) == statusCode
            }

            it("should initialize with response") {
                let description = "foo"
                let data = description.data(using: .utf8)!
                let response = Response<ManagementError>(data: data, response: nil, error: nil)
                let error = ManagementError(from: response)
                expect(error.localizedDescription) == description
                expect(error.statusCode) == 0
                expect(error.cause).to(beNil())
            }

            it("should initialize with response & status code") {
                let description = "foo"
                let data = description.data(using: .utf8)!
                let statusCode = 400
                let httpResponse = HTTPURLResponse(url: URL(string: "example.com")!,
                                                   statusCode: statusCode,
                                                   httpVersion: nil,
                                                   headerFields: nil)
                let response = Response<ManagementError>(data: data, response: httpResponse, error: nil)
                let error = ManagementError(from: response)
                expect(error.localizedDescription) == description
                expect(error.statusCode) == statusCode
            }

        }

        describe("operators") {

            it("should be equal") {
                let info: [String: Any] = ["code": "foo", "description": "bar"]
                let statusCode = 400
                let error = ManagementError(info: info, statusCode: statusCode)
                expect(error) == ManagementError(info: info, statusCode: statusCode)
            }

            it("should not be equal to an error with a different code") {
                let description = "foo"
                let statusCode = 400
                let error = ManagementError(info: ["code": "bar", "description": description], statusCode: statusCode)
                expect(error) != ManagementError(info: ["code": "baz", "description": description], statusCode: statusCode)
            }

            it("should not be equal to an error with a different status code") {
                let info: [String: Any] = ["code": "foo", "description": "bar"]
                let error = ManagementError(info: info, statusCode: 400)
                expect(error) != ManagementError(info: info, statusCode: 500)
            }

            it("should not be equal to an error with a different description") {
                let code = "foo"
                let statusCode = 400
                let error = ManagementError(info: ["code": code, "description": "bar"], statusCode: statusCode)
                expect(error) != ManagementError(info: ["code": code, "description": "baz"], statusCode: statusCode)
            }

            it("should access the internal info dictionary") {
                let info: [String: Any] = ["foo": "bar"]
                let error = ManagementError(info: info)
                expect(error.info["foo"] as? String) == "bar"
            }

        }

        describe("error code") {

            it("should return the message") {
                let code = "foo"
                let info: [String: Any] = ["code": code]
                let error = ManagementError(info: info)
                expect(error.code) == code
            }

            it("should return the default code") {
                let error = ManagementError(info: [:])
                expect(error.code) == unknownError
            }

        }

        describe("error message") {

            it("should return the message") {
                let description = "foo"
                let info: [String: Any] = ["description": description]
                let error = ManagementError(info: info)
                expect(error.localizedDescription) == description
            }

            it("should return the default message") {
                let info: [String: Any] = ["foo": "bar", "statusCode": 0]
                let message = "Failed with unknown error \(info)"
                let error = ManagementError(info: info)
                expect(error.localizedDescription) == message
            }

        }

    }

}
