import Foundation
import Quick
import Nimble

@testable import Auth0

private let AuthenticationSession = "7p0knAl_iQedbOuG2vBrU0QKREz8J300DkuCzTRRGuFsQ_Z6XqcADPdrB26RxqDx"
private let RelyingPartyIdentifier = "example.com"
private let UserIdentifier = "LcICuavHdO2zbcA8zRgnTRIkzPrruI_HQqe0J3RL0ou5VSrWhRybCQqyNMXWj1LDdxOzat6KVf9xpW3qLw5qjw"
private let UserName = "user@example.com"
private let Challenge = "wC-Pos1D-2xf9H5JjeoNJDWKhToOwrlwJ2mguvhnshw"

class PasskeySignupChallengeSpec: QuickSpec {
    override class func spec() {

        describe("decode from json") {

            var decoder: JSONDecoder!

            beforeEach {
                decoder = JSONDecoder()
            }

            it("should have all properties") {
                let json = """
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
                """.data(using: .utf8)!
                let challenge = try decoder.decode(PasskeySignupChallenge.self, from: json)

                expect(challenge.authenticationSession) == AuthenticationSession
                expect(challenge.relyingPartyId) == RelyingPartyIdentifier
                expect(challenge.userId) == UserIdentifier.a0_decodeBase64URLSafe()
                expect(challenge.userName) == UserName
                expect(challenge.challengeData) == Challenge.a0_decodeBase64URLSafe()
            }

            it("should fail when the user id is invalid") {
                let json = """
                    {
                        "auth_session": "\(AuthenticationSession)",
                        "authn_params_public_key": {
                            "rp": {
                                "id": "\(RelyingPartyIdentifier)",
                                "name": "Foo",
                    
                            },
                            "user": {
                                "id": 1000,
                                "name": "\(UserName)",
                                "displayName": "Bar"
                            },
                            "challenge": "\(Challenge)",
                            "pubKeyCredParams": [{ "type": "public-key", "alg": -257 }]
                        }
                    }
                """.data(using: .utf8)!
                let context = DecodingError.Context(codingPath: [],
                                                    debugDescription: "Format of user id is not recognized.")
                let expectedError = DecodingError.dataCorrupted(context)

                expect({ try decoder.decode(PasskeySignupChallenge.self, from: json) }).to(throwError(expectedError))
            }

            it("should fail when the challenge is invalid") {
                let json = """
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
                            "challenge": 1000,
                            "pubKeyCredParams": [{ "type": "public-key", "alg": -257 }]
                        }
                    }
                """.data(using: .utf8)!
                let context = DecodingError.Context(codingPath: [],
                                                    debugDescription: "Format of challenge is not recognized.")
                let expectedError = DecodingError.dataCorrupted(context)

                expect({ try decoder.decode(PasskeySignupChallenge.self, from: json) }).to(throwError(expectedError))
            }

        }

    }
}
