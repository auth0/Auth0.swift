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
                let code = "invalid_request"
                let challenges: [String] = [
                    "DPoP error=\"\(code)\"",
                    "DPoP error=\"\(code)\", Bearer realm=\"example\"",
                    "Bearer realm=\"example\", DPoP error=\"\(code)\"",
                    "DPoP error=\(code)",
                    "DPoP error=\(code), Bearer realm=example",
                    "Bearer realm=example, DPoP error=\(code)",
                    "dpoP error=\"\(code)\"",
                    "dpoP error=\"\(code)\", Bearer realm=\"example\"",
                    "Bearer realm=\"example\", dpoP error=\"\(code)\"",
                    "dpoP error=\(code)",
                    "dpoP error=\(code), Bearer realm=example",
                    "Bearer realm=example, dpoP error=\(code)",
                    "DPoP error =  \"\(code)\"",
                    "DPoP error =  \"\(code)\", Bearer realm  = \"example\"",
                    "Bearer realm  = \"example\", DPoP error =  \"\(code)\"",
                    "DPoP error =  \(code)",
                    "DPoP error =  \(code), Bearer realm  = example",
                    "Bearer realm  = example, DPoP error =  \(code)"
                ]

                challenges.forEach { header in
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                                   statusCode: 401,
                                                   httpVersion: nil,
                                                   headerFields: ["WWW-Authenticate": header])!
                    let challenge = DPoPChallenge(from: response)

                    expect(challenge).toNot(beNil())
                    expect(challenge?.errorCode) == code
                    expect(challenge?.errorDescription).to(beNil())
                }

            }

            it("should parse a DPoP challenge with an error code and description") {
                let code = "invalid_request"
                let description = "Invalid request"
                let challenges: [String] = [
                    "DPoP error=\"\(code)\", error_description=\"\(description)\"",
                    "DPoP error=\"\(code)\", error_description=\"\(description)\", Bearer realm=\"example\"",
                    "Bearer realm=\"example\", DPoP error=\"\(code)\", error_description=\"\(description)\"",
                    "DPoP error=\(code), error_description=\"\(description)\"",
                    "DPoP error=\(code), error_description=\"\(description)\", Bearer realm=example",
                    "Bearer realm=example, DPoP error=\(code), error_description=\"\(description)\"",
                    "dpoP error=\"\(code)\", error_description=\"\(description)\"",
                    "dpoP error=\"\(code)\", error_description=\"\(description)\", Bearer realm=\"example\"",
                    "Bearer realm=\"example\", dpoP error=\"\(code)\", error_description=\"\(description)\"",
                    "dpoP error=\(code), error_description=\"\(description)\"",
                    "dpoP error=\(code), error_description=\"\(description)\", Bearer realm=example",
                    "Bearer realm=example, dpoP error=\(code), error_description=\"\(description)\"",
                    "DPoP error =  \"\(code)\", error_description = \"\(description)\"",
                    "DPoP error =  \"\(code)\", error_description = \"\(description)\", Bearer realm  = \"example\"",
                    "Bearer realm  = \"example\", DPoP error =  \"\(code)\", error_description = \"\(description)\"",
                    "DPoP error =  \(code), error_description = \"\(description)\"",
                    "DPoP error =  \(code), error_description = \"\(description)\", Bearer realm  = example",
                    "Bearer realm  = example, DPoP error =  \(code), error_description = \"\(description)\""
                ]

                challenges.forEach { header in
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                                   statusCode: 401,
                                                   httpVersion: nil,
                                                   headerFields: ["WWW-Authenticate": header])!
                    let challenge = DPoPChallenge(from: response)

                    expect(challenge).toNot(beNil())
                    expect(challenge?.errorCode) == code
                    expect(challenge?.errorDescription) == description
                }

            }

            it("should return nil when the DPoP challenge does not contain an error code") {
                let header = "Bearer realm=\"example\", DPoP algs=ES256"
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
