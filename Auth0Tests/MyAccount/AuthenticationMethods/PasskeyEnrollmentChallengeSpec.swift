import Foundation
import Quick
import Nimble

@testable import Auth0

private let AuthenticationMethodId = "baz"
private let AuthenticationSession = "7p0knAl_iQedbOuG2vBrU0QKREz8J300DkuCzTRRGuFsQ_Z6XqcADPdrB26RxqDx"
private let RelyingPartyIdentifier = "example.com"
private let UserIdentifier = "LcICuavHdO2zbcA8zRgnTRIkzPrruI_HQqe0J3RL0ou5VSrWhRybCQqyNMXWj1LDdxOzat6KVf9xpW3qLw5qjw"
private let UserName = "user@example.com"
private let Challenge = "wC-Pos1D-2xf9H5JjeoNJDWKhToOwrlwJ2mguvhnshw"
private let JSON = """
{
    "auth_session": "\(AuthenticationSession)",
    "authn_params_public_key": {
        "rp": {
            "id": "\(RelyingPartyIdentifier)",
            "name": "Foo",

        },
        "user": {
            "id": "\(UserIdentifier)",
            "name": "\(UserName)",
            "displayName": "Bar"
        },
        "challenge": "\(Challenge)",
        "pubKeyCredParams": [{ "type": "public-key", "alg": -257 }]
    }
}
"""

class PasskeyEnrollmentChallengeSpec: QuickSpec {
    override class func spec() {

        describe("decode from json") {

            var decoder: JSONDecoder!

            beforeEach {
                decoder = JSONDecoder()
                decoder.userInfo[.headersKey] = ["Location": "https://example.com/foo/bar/\(AuthenticationMethodId)"]
            }

            it("should have all properties") {
                let jsonData = JSON.data(using: .utf8)!
                let challenge = try decoder.decode(PasskeyEnrollmentChallenge.self, from: jsonData)

                expect(challenge.authenticationMethodId) == AuthenticationMethodId
                expect(challenge.authenticationSession) == AuthenticationSession
                expect(challenge.relyingPartyId) == RelyingPartyIdentifier
                expect(challenge.userId) == UserIdentifier.a0_decodeBase64URLSafe()
                expect(challenge.userName) == UserName
                expect(challenge.challengeData) == Challenge.a0_decodeBase64URLSafe()
            }

            it("should fail when the headers are missing") {
                decoder = JSONDecoder()

                let jsonData = JSON.data(using: .utf8)!
                let errorDescription = "Missing authentication method identifier in header 'Location'"
                let context = DecodingError.Context(codingPath: [],
                                                    debugDescription: errorDescription)
                let expectedError = DecodingError.dataCorrupted(context)

                expect({
                    try decoder.decode(PasskeyEnrollmentChallenge.self, from: jsonData)
                }).to(throwError(expectedError))
            }

            it("should fail when the Location header is missing") {
                decoder = JSONDecoder()
                decoder.userInfo[.headersKey] = ["Foo": "Bar"]

                let jsonData = JSON.data(using: .utf8)!
                let errorDescription = "Missing authentication method identifier in header 'Location'"
                let context = DecodingError.Context(codingPath: [],
                                                    debugDescription: errorDescription)
                let expectedError = DecodingError.dataCorrupted(context)

                expect({
                    try decoder.decode(PasskeyEnrollmentChallenge.self, from: jsonData)
                }).to(throwError(expectedError))
            }

            it("should fail when the user id is invalid") {
                let json = JSON.replacingOccurrences(of: "\"\(UserIdentifier)\"", with: "1000")
                let jsonData = json.data(using: .utf8)!
                let context = DecodingError.Context(codingPath: [],
                                                    debugDescription: "Format of user id is not recognized.")
                let expectedError = DecodingError.dataCorrupted(context)

                expect({
                    try decoder.decode(PasskeyEnrollmentChallenge.self, from: jsonData)
                }).to(throwError(expectedError))
            }

            it("should fail when the challenge is invalid") {
                let json = JSON.replacingOccurrences(of: "\"\(Challenge)\"", with: "1000")
                let jsonData = json.data(using: .utf8)!
                let context = DecodingError.Context(codingPath: [],
                                                    debugDescription: "Format of challenge is not recognized.")
                let expectedError = DecodingError.dataCorrupted(context)

                expect({
                    try decoder.decode(PasskeyEnrollmentChallenge.self, from: jsonData)
                }).to(throwError(expectedError))
            }

        }

    }
}
