import Foundation
import Quick
import Nimble

@testable import Auth0

class DPoPChallengeSpec: QuickSpec {
    override class func spec() {

        describe("initialization") {

            it("should initialize with error code") {
                let errorCode = "invalid_request"
                let challenge = DPoPChallenge(errorCode: errorCode, errorDescription: nil)
                expect(challenge.errorCode) == errorCode
                expect(challenge.errorDescription).to(beNil())
            }

            it("should initialize with error code and description") {
                let errorCode = "invalid_request"
                let errorDescription = "Invalid request"
                let challenge = DPoPChallenge(errorCode: errorCode, errorDescription: errorDescription)
                expect(challenge.errorCode) == errorCode
                expect(challenge.errorDescription) == errorDescription
            }

        }

        describe("parsing") {

            it("should parse a DPoP challenge with an error code") {
                let errorCode = "invalid_request"
                let header = "DPoP error=\"\(errorCode)\""
                let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 401,
                                               httpVersion: nil,
                                               headerFields: ["WWW-Authenticate": header])!
                let challenge = DPoPChallenge(from: response)

                expect(challenge).toNot(beNil())
                expect(challenge?.errorCode) == errorCode
                expect(challenge?.errorDescription).to(beNil())
            }

            it("should parse a DPoP challenge with an error code and description") {
                let errorCode = "invalid_request"
                let errorDescription = "Invalid request"
                let header = "DPoP error=\"\(errorCode)\", error_description=\"\(errorDescription)\""
                let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 401,
                                               httpVersion: nil,
                                               headerFields: ["WWW-Authenticate": header])!
                let challenge = DPoPChallenge(from: response)

                expect(challenge).toNot(beNil())
                expect(challenge?.errorCode) == errorCode
                expect(challenge?.errorDescription) == errorDescription
            }

            it("should ignore case when parsing the authentication scheme") {
                let errorCode = "invalid_request"
                let header = "dpoP error=\"\(errorCode)\""
                let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 401,
                                               httpVersion: nil,
                                               headerFields: ["WWW-Authenticate": header])!
                let challenge = DPoPChallenge(from: response)

                expect(challenge).toNot(beNil())
                expect(challenge?.errorCode) == errorCode
            }

            it("should ignore whitespace when parsing the error code") {
                let errorCode = "invalid_request"
                let header = "DPoP error = \"\(errorCode)\""
                let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 401,
                                               httpVersion: nil,
                                               headerFields: ["WWW-Authenticate": header])!
                let challenge = DPoPChallenge(from: response)

                expect(challenge).toNot(beNil())
                expect(challenge?.errorCode) == errorCode
            }

            it("should ignore whitespace when parsing the error description") {
                let errorDescription = "Invalid request"
                let header = "DPoP error=\"invalid_request\", error_description = \"\(errorDescription)\""
                let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 401,
                                               httpVersion: nil,
                                               headerFields: ["WWW-Authenticate": header])!
                let challenge = DPoPChallenge(from: response)

                expect(challenge).toNot(beNil())
                expect(challenge?.errorDescription) == errorDescription
            }

            it("should return nil when the DPoP challenge does not contain an error code") {
                let header = "Bearer realm=\"example\", DPoP"
                let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 401,
                                               httpVersion: nil,
                                               headerFields: ["WWW-Authenticate": header])!

                expect(DPoPChallenge(from: response)).to(beNil())
            }

            it("should return nil when WWW-Authenticate header does not contain a DPoP challenge") {
                let header = "Bearer realm=\"example\""
                let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 401,
                                               httpVersion: nil,
                                               headerFields: ["WWW-Authenticate": header])!

                expect(DPoPChallenge(from: response)).to(beNil())
            }

            it("should return nil when the WWW-Authenticate header is missing") {
                let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 401,
                                               httpVersion: nil,
                                               headerFields: nil)!

                expect(DPoPChallenge(from: response)).to(beNil())
            }

        }

    }
}
