import Foundation
import Quick
import Nimble

@testable import Auth0

class EmbeddedAuthErrorSpec: QuickSpec {

    override class func spec() {

        describe("EmbeddedAuthError") {

            describe("init(info:statusCode:)") {

                it("reads error code from 'error' key") {
                    let error = EmbeddedAuthError(info: ["error": "invalid_request", "error_description": "bad input"], statusCode: 400)
                    expect(error.code) == "invalid_request"
                }

                it("falls back to unknown when error key is absent") {
                    let error = EmbeddedAuthError(info: [:], statusCode: 400)
                    expect(error.code) == unknownError
                }

                it("stores the statusCode") {
                    let error = EmbeddedAuthError(info: ["error": "invalid_client"], statusCode: 401)
                    expect(error.statusCode) == 401
                }

                it("stores raw info") {
                    let error = EmbeddedAuthError(info: ["error": "server_error", "error_description": "oops"], statusCode: 500)
                    expect(error.info["error"] as? String) == "server_error"
                }
            }

            describe("isInvalidRequest") {

                it("is true for invalid_request code") {
                    let error = EmbeddedAuthError(info: ["error": "invalid_request"], statusCode: 400)
                    expect(error.isInvalidRequest).to(beTrue())
                }

                it("is false for other codes") {
                    let error = EmbeddedAuthError(info: ["error": "invalid_client"], statusCode: 401)
                    expect(error.isInvalidRequest).to(beFalse())
                }
            }

            describe("isInvalidClient") {

                it("is true for invalid_client code") {
                    let error = EmbeddedAuthError(info: ["error": "invalid_client"], statusCode: 401)
                    expect(error.isInvalidClient).to(beTrue())
                }

                it("is false for other codes") {
                    let error = EmbeddedAuthError(info: ["error": "invalid_request"], statusCode: 400)
                    expect(error.isInvalidClient).to(beFalse())
                }
            }

            describe("isFeatureDisabled") {

                it("is true when statusCode is 404") {
                    let error = EmbeddedAuthError(info: [:], statusCode: 404)
                    expect(error.isFeatureDisabled).to(beTrue())
                }

                it("is false for other status codes") {
                    let error = EmbeddedAuthError(info: ["error": "invalid_request"], statusCode: 400)
                    expect(error.isFeatureDisabled).to(beFalse())
                }
            }

            describe("debugDescription") {

                it("contains the error code") {
                    let error = EmbeddedAuthError(info: ["error": "invalid_client", "error_description": "Unknown client"], statusCode: 401)
                    expect(error.debugDescription).to(contain("invalid_client"))
                }
            }

            describe("Equatable") {

                it("equals another error with same code and status") {
                    let a = EmbeddedAuthError(info: ["error": "invalid_request"], statusCode: 400)
                    let b = EmbeddedAuthError(info: ["error": "invalid_request"], statusCode: 400)
                    expect(a) == b
                }

                it("differs when status codes differ") {
                    let a = EmbeddedAuthError(info: ["error": "invalid_request"], statusCode: 400)
                    let b = EmbeddedAuthError(info: ["error": "invalid_request"], statusCode: 401)
                    expect(a) != b
                }
            }
        }
    }
}
