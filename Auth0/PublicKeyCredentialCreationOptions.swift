#if PASSKEYS_PLATFORM
import Foundation

struct PublicKeyCredentialCreationOptions: Sendable {

    let relyingParty: PublicKeyRelyingParty
    let user: PublicKeyUser
    let challengeData: Data

}

struct PublicKeyRelyingParty: Decodable, Sendable {

    let id: String

}

struct PublicKeyUser: Decodable, Sendable {

    let id: Data
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
    }

}

extension PublicKeyCredentialCreationOptions: Decodable {

    enum CodingKeys: String, CodingKey {
        case relyingParty = "rp"
        case user
        case challengeData = "challenge"
        case selectionCriteria = "authenticatorSelection"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let userValues = try values.nestedContainer(keyedBy: PublicKeyUser.CodingKeys.self, forKey: .user)

        guard case let userIdString = try userValues.decode(String.self, forKey: .id),
              let userId = userIdString.a0_decodeBase64URLSafe() else {
            throw DecodingError.dataCorruptedError(forKey: .user,
                                                   in: values,
                                                   debugDescription: "Format of user id is not recognized.")
        }

        guard case let challengeString = try values.decode(String.self, forKey: .challengeData),
              let challenge = challengeString.a0_decodeBase64URLSafe() else {
            throw DecodingError.dataCorruptedError(forKey: .challengeData,
                                                   in: values,
                                                   debugDescription: "Format of challenge is not recognized.")
        }

        relyingParty = try values.decode(PublicKeyRelyingParty.self, forKey: .relyingParty)
        user = PublicKeyUser(id: userId, name: try userValues.decode(String.self, forKey: .name))
        challengeData = challenge

    }

}
#endif
