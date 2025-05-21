import Foundation
import Quick
import Nimble

@testable import Auth0

private let PasskeyId = "passkey|dev_rMJhr6SjnUUcHCxW"
private let PasskeyType = "passkey"
private let PasskeyCreatedAt = "2025-05-01T11:24:10.172Z"
private let PasskeyUserIdentityId = "681359da4a20c7993310ff1d"
private let PasskeyUserHandle = "uq9owlgkg7papmbVSah3y968mhZfLh6xSBtLxx9rGouTF3ZIw59_VqC3CyRJQCI76Fp07n-5p2I4ew1D-0b" +
"OBA"
private let PasskeyUserAgent = "OAuth2/1 CFNetwork/3826.500.111.2.2 Darwin/24.4.0"
private let PasskeyKeyId = "XqQWiLjlWv6SPbFapFvkwYrSDCc"
private let PasskeyPublicKey = "pQECAyYgASFYIGK0OMbKXIHgb1Es/MrVoCTrGDzi96vGxUpAGJOhUOp4IlggxIbnS81JDZHWv+NZtWV7wMzb" +
"g7sTOJbACvk7xY6DE7A="
private let PasskeyCredentialDeviceType = "multi_device"
private let PasskeyIsCredentialBackedUp = true

private let JSON = """
{
    "id": "\(PasskeyId)",
    "type": "\(PasskeyType)",
    "created_at": "\(PasskeyCreatedAt)",
    "identity_user_id": "\(PasskeyUserIdentityId)",
    "user_handle": "\(PasskeyUserHandle)",
    "user_agent": "\(PasskeyUserAgent)",
    "key_id": "\(PasskeyKeyId)",
    "public_key": "\(PasskeyPublicKey)",
    "credential_device_type": "\(PasskeyCredentialDeviceType)",
    "credential_backed_up": \(PasskeyIsCredentialBackedUp)
}
"""

class PasskeyAuthenticationMethodSpec: QuickSpec {
    override class func spec() {

        describe("decode from json") {

            var decoder: JSONDecoder!

            beforeEach {
                decoder = JSONDecoder()
            }

            it("should have all properties") {
                let jsonData = JSON.data(using: .utf8)!
                let challenge = try decoder.decode(PasskeyAuthenticationMethod.self, from: jsonData)
                let createdAtDecoder = ISO8601DateFormatter()
                createdAtDecoder.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let createdAtDate = createdAtDecoder.date(from: PasskeyCreatedAt)!

                expect(challenge.id) == PasskeyId
                expect(challenge.type) == PasskeyType
                expect(challenge.userIdentityId) == PasskeyUserIdentityId
                expect(challenge.userAgent) == PasskeyUserAgent
                expect(challenge.credential.id) == PasskeyKeyId
                expect(challenge.credential.publicKey) == PasskeyPublicKey.a0_decodeBase64URLSafe()
                expect(challenge.credential.userHandle) == PasskeyUserHandle.a0_decodeBase64URLSafe()
                expect(challenge.credential.deviceType) == .multiDevice
                expect(challenge.credential.isBackedUp) == PasskeyIsCredentialBackedUp
                expect(challenge.createdAt).to(beCloseTo(createdAtDate, within: 0.01))
            }

            it("should have non-optional properties only") {
                let json = """
                {
                    "id": "\(PasskeyId)",
                    "type": "\(PasskeyType)",
                    "created_at": "\(PasskeyCreatedAt)",
                    "identity_user_id": "\(PasskeyUserIdentityId)",
                    "user_handle": "\(PasskeyUserHandle)",
                    "key_id": "\(PasskeyKeyId)",
                    "public_key": "\(PasskeyPublicKey)",
                    "credential_device_type": "\(PasskeyCredentialDeviceType)",
                    "credential_backed_up": \(PasskeyIsCredentialBackedUp)
                }
                """
                let jsonData = json.data(using: .utf8)!
                let challenge = try decoder.decode(PasskeyAuthenticationMethod.self, from: jsonData)
                let createdAtDecoder = ISO8601DateFormatter()
                createdAtDecoder.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let createdAtDate = createdAtDecoder.date(from: PasskeyCreatedAt)!

                expect(challenge.id) == PasskeyId
                expect(challenge.type) == PasskeyType
                expect(challenge.userIdentityId) == PasskeyUserIdentityId
                expect(challenge.userAgent).to(beNil())
                expect(challenge.credential.id) == PasskeyKeyId
                expect(challenge.credential.publicKey) == PasskeyPublicKey.a0_decodeBase64URLSafe()
                expect(challenge.credential.userHandle) == PasskeyUserHandle.a0_decodeBase64URLSafe()
                expect(challenge.credential.deviceType) == .multiDevice
                expect(challenge.credential.isBackedUp) == PasskeyIsCredentialBackedUp
                expect(challenge.createdAt).to(beCloseTo(createdAtDate, within: 0.01))
            }

            it("should fail when the user handle is invalid") {
                let json = JSON.replacingOccurrences(of: "\"\(PasskeyUserHandle)\"", with: "1000")
                let jsonData = json.data(using: .utf8)!
                let context = DecodingError.Context(codingPath: [],
                                                    debugDescription: "Format of user_handle is not recognized.")
                let expectedError = DecodingError.dataCorrupted(context)

                expect({
                    try decoder.decode(PasskeyAuthenticationMethod.self, from: jsonData)
                }).to(throwError(expectedError))
            }

            it("should fail when the public key is invalid") {
                let json = JSON.replacingOccurrences(of: "\"\(PasskeyPublicKey)\"", with: "1000")
                let jsonData = json.data(using: .utf8)!
                let context = DecodingError.Context(codingPath: [],
                                                    debugDescription: "Format of public_key is not recognized.")
                let expectedError = DecodingError.dataCorrupted(context)

                expect({
                    try decoder.decode(PasskeyAuthenticationMethod.self, from: jsonData)
                }).to(throwError(expectedError))
            }

        }

    }
}
