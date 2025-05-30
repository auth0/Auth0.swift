import Foundation
import Quick
import Nimble

@testable import Auth0

private let AuthenticationSession = "u5WSCyajq719ZSkLiEH13OJpa-Jsh8YZ75-NsBXph5pS-_gvqA0Z1MZyXL_sellw"
private let RelyingPartyIdentifier = "example.com"
private let Challenge = "4Zak2Y_UFCY4BvuE_j58ThKyUWpf9Vqp6zXZb6dl-nA"

class PasskeyLoginChallengeSpec: QuickSpec {
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
                            "rpId": "\(RelyingPartyIdentifier)",
                            "challenge": "\(Challenge)",
                            "userVerification": "preferred",
                            "timeout": 60000
                        }
                    }
                """.data(using: .utf8)!
                let challenge = try decoder.decode(PasskeyLoginChallenge.self, from: json)

                expect(challenge.authenticationSession) == AuthenticationSession
                expect(challenge.relyingPartyId) == RelyingPartyIdentifier
                expect(challenge.challengeData) == Challenge.a0_decodeBase64URLSafe()
            }

            it("should fail when the challenge is invalid") {
                let json = """
                    {
                        "auth_session": "\(AuthenticationSession)",
                        "authn_params_public_key": {
                            "rpId": "\(RelyingPartyIdentifier)",
                            "challenge": 1000,
                            "userVerification": "preferred",
                            "timeout": 60000
                        }
                    }
                """.data(using: .utf8)!
                let context = DecodingError.Context(codingPath: [],
                                                    debugDescription: "Format of challenge is not recognized.")
                let expectedError = DecodingError.dataCorrupted(context)

                expect({ try decoder.decode(PasskeyLoginChallenge.self, from: json) }).to(throwError(expectedError))
            }

        }

    }
}
