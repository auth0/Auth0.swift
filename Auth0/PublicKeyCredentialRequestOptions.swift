#if PASSKEYS_PLATFORM
import Foundation

@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
struct PublicKeyCredentialRequestOptions: Sendable {

    let relyingPartyId: String
    let challengeData: Data

}

@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
extension PublicKeyCredentialRequestOptions: Decodable {

    enum CodingKeys: String, CodingKey {
        case relyingPartyId = "rpId"
        case challengeData = "challenge"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        guard case let challengeString = try values.decode(String.self, forKey: .challengeData),
              let challenge = challengeString.a0_decodeBase64URLSafe() else {
            throw DecodingError.dataCorruptedError(forKey: .challengeData,
                                                   in: values,
                                                   debugDescription: "Format of challenge is not recognized.")
        }

        relyingPartyId = try values.decode(String.self, forKey: .relyingPartyId)
        challengeData = challenge

    }

}
#endif
