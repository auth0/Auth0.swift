import Foundation
import Quick
import Nimble

@testable import Auth0

class MyAccountErrorSpec: QuickSpec {

    override class func spec() {

        describe("init") {

            it("should initialize with info") {
                let info: [String: Any] = ["foo": "bar"]
                let error = MyAccountError(info: info)

                expect(error.info["foo"] as? String) == "bar"
                expect(error.info.count) == 1
                expect(error.statusCode) == 0
                expect(error.cause).to(beNil())
            }

            it("should initialize with info and status code") {
                let info: [String: Any] = ["foo": "bar"]
                let statusCode = 400
                let error = MyAccountError(info: info, statusCode: statusCode)

                expect(error.statusCode) == statusCode
            }

            it("should initialize with cause") {
                let cause = NSError(domain: "com.auth0", code: -99999, userInfo: nil)
                let error = MyAccountError(cause: cause)

                expect(error.cause).to(matchError(cause))
                expect(error.statusCode) == 0
            }

            it("should initialize with cause and status code") {
                let cause = NSError(domain: "com.auth0", code: -99999, userInfo: nil)
                let statusCode = 400
                let error = MyAccountError(cause: cause, statusCode: statusCode)

                expect(error.statusCode) == statusCode
            }

            it("should initialize with description") {
                let description = "foo"
                let error = MyAccountError(description: description)

                expect(error.localizedDescription) == "\(description)."
                expect(error.statusCode) == 0
                expect(error.cause).to(beNil())
            }

            it("should initialize with description and status code") {
                let description = "foo"
                let statusCode = 400
                let error = MyAccountError(description: description, statusCode: statusCode)

                expect(error.statusCode) == statusCode
            }

            it("should initialize with response") {
                let description = "foo"
                let data = description.data(using: .utf8)!
                let response = Response<MyAccountError>(data: data, response: nil, error: nil)
                let error = MyAccountError(from: response)

                expect(error.localizedDescription) == "\(description)."
                expect(error.statusCode) == 0
                expect(error.cause).to(beNil())
            }

            it("should initialize with response and status code") {
                let description = "foo"
                let data = description.data(using: .utf8)!
                let statusCode = 400
                let httpResponse = HTTPURLResponse(url: URL(string: "example.com")!,
                                                   statusCode: statusCode,
                                                   httpVersion: nil,
                                                   headerFields: nil)
                let response = Response<MyAccountError>(data: data, response: httpResponse, error: nil)
                let error = MyAccountError(from: response)

                expect(error.localizedDescription) == "\(description)."
                expect(error.statusCode) == statusCode
            }

            it("should initialize with cause") {
                let cause = MockError()
                let description = "Unable to complete the operation. CAUSE: \(cause.localizedDescription)."
                let error = MyAccountError(cause: cause)

                expect(error.cause).toNot(beNil())
                expect(error.localizedDescription) == description
                expect(error.statusCode) == 0
            }

            it("should initialize with cause and status code") {
                let statusCode = 400
                let error = MyAccountError(cause: MockError(), statusCode: statusCode)

                expect(error.statusCode) == statusCode
            }

        }

        describe("operators") {

            it("should be equal") {
                let info: [String: Any] = ["type": "foo", "title": "bar", "detail": "baz"]
                let statusCode = 400
                let error = MyAccountError(info: info, statusCode: statusCode)

                expect(error) == MyAccountError(info: info, statusCode: statusCode)
            }

            it("should not be equal to an error with a different type") {
                let title = "bar"
                let detail = "baz"
                let statusCode = 400
                let error = MyAccountError(info: ["type": "foo", "title": title, "detail": detail],
                                           statusCode: statusCode)

                expect(error) != MyAccountError(info: ["type": "qux", "title": title, "detail": detail],
                                                statusCode: statusCode)
            }

            it("should not be equal to an error with a different title") {
                let type = "foo"
                let detail = "baz"
                let statusCode = 400
                let error = MyAccountError(info: ["type": type, "title": "bar", "detail": detail],
                                           statusCode: statusCode)

                expect(error) != MyAccountError(info: ["type": type, "title": "qux", "detail": detail],
                                                statusCode: statusCode)
            }

            it("should not be equal to an error with a different detail") {
                let type = "foo"
                let title = "bar"
                let statusCode = 400
                let error = MyAccountError(info: ["type": type, "title": title, "detail": "baz"],
                                           statusCode: statusCode)

                expect(error) != MyAccountError(info: ["type": type, "title": title, "detail": "qux"],
                                                statusCode: statusCode)
            }

            it("should not be equal to an error with a different status code") {
                let info: [String: Any] = ["type": "foo", "title": "bar", "detail": "baz"]
                let error = MyAccountError(info: info, statusCode: 400)

                expect(error) != MyAccountError(info: info, statusCode: 500)
            }

            it("should access the internal info dictionary") {
                let info: [String: Any] = ["foo": "bar"]
                let error = MyAccountError(info: info)

                expect(error.info["foo"] as? String) == "bar"
            }

        }

        describe("error code") {

            it("should return the type") {
                let type = "foo"
                let info: [String: Any] = ["type": type]
                let error = MyAccountError(info: info)

                expect(error.code) == type
            }

            it("should return the code") {
                let code = "foo"
                let info: [String: Any] = ["code": code]
                let error = MyAccountError(info: info)

                expect(error.code) == code
            }

            it("should return the default code") {
                let error = MyAccountError(info: [:])

                expect(error.code) == unknownError
            }

        }

        describe("error title") {

            it("should return the title") {
                let title = "foo"
                let info: [String: Any] = ["title": title]
                let error = MyAccountError(info: info)

                expect(error.title) == title
            }

            it("should return the description") {
                let description = "foo"
                let info: [String: Any] = ["description": description]
                let error = MyAccountError(info: info)

                expect(error.title) == description
            }

            it("should return an empty title") {
                let info: [String: Any] = [:]
                let error = MyAccountError(info: info)

                expect(error.title).to(beEmpty())
            }

        }

        describe("error detail") {

            it("should return the title") {
                let detail = "foo"
                let info: [String: Any] = ["detail": detail]
                let error = MyAccountError(info: info)

                expect(error.detail) == detail
            }

            it("should return an empty detail") {
                let info: [String: Any] = [:]
                let error = MyAccountError(info: info)

                expect(error.detail).to(beEmpty())
            }

        }

        describe("error message") {

            it("should return the title and detail") {
                let title = "foo"
                let detail = "bar."
                let info: [String: Any] = ["title": title, "detail": detail, "type": "baz"]
                let error = MyAccountError(info: info)

                expect(error.localizedDescription) == "\(title): \(detail)"
            }

            it("should return the title and detail adding a period") {
                let title = "foo"
                let detail = "bar"
                let info: [String: Any] = ["title": title, "detail": detail, "type": "baz"]
                let error = MyAccountError(info: info)

                expect(error.localizedDescription) == "\(title): \(detail)."
            }

            it("should return the title") {
                let title = "foo."
                let info: [String: Any] = ["title": title, "type": "bar"]
                let error = MyAccountError(info: info)

                expect(error.localizedDescription) == "\(title)"
            }

            it("should return the title adding period") {
                let title = "foo"
                let info: [String: Any] = ["title": title, "type": "bar"]
                let error = MyAccountError(info: info)

                expect(error.localizedDescription) == "\(title)."
            }

            it("should return the default message") {
                let info: [String: Any] = [:]
                let message = "Failed with unknown error: \(info)."
                let error = MyAccountError(info: info)

                expect(error.localizedDescription) == message
            }

        }

        describe("validation errors") {

            it("should return the validation errors") {
                let expectedValidationErrors: [(json: [String: String], error: MyAccountError.ValidationError)] = [
                    (json: ["detail": ""], error: .init(detail: "", pointer: nil)),
                    (json: ["detail": "foo"], error: .init(detail: "foo", pointer: nil)),
                    (json: ["detail": "foo", "pointer": ""], error: .init(detail: "foo", pointer: nil)),
                    (json: ["detail": "foo", "pointer": "baz"], error: .init(detail: "foo", pointer: "baz")),
                ]
                let info: [String: Any] = ["validation_errors": expectedValidationErrors.map(\.json)]
                let error = MyAccountError(info: info)

                expect(error.validationErrors).to(haveCount(4))

                for (index, actualError) in error.validationErrors!.enumerated() {
                    let expectedError = expectedValidationErrors[index].error
                    expect(actualError.detail) == expectedError.detail

                    if (expectedError.pointer == nil) {
                        expect(actualError.pointer).to(beNil())
                    } else {
                        expect(actualError.pointer) == expectedError.pointer
                    }
                }
            }

            it("should return nil when there are no validation errors") {
                let info: [String: Any] = [:]
                let error = MyAccountError(info: info)

                expect(error.validationErrors).to(beNil())
            }

        }

        describe("error cases") {

            it("should detect network error") {
                for errorCode in MyAccountError.networkErrorCodes {
                    expect(MyAccountError(cause: URLError.init(errorCode)).isNetworkError) == true
                }
            }

        }

    }

}
