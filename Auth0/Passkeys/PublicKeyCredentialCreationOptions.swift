#if !os(watchOS)
import Foundation

public struct PublicKeyCredentialCreationOptions: Sendable {

    public let relyingParty: PublicKeyRelyingParty

    public let user: PublicKeyUser

    public let challengeData: Data

    public let credentialParameters: [PublicKeyCredentialParameters]

    public let selectionCriteria: AuthenticatorSelectionCriteria

    public let timeout: Int

}

public struct PublicKeyRelyingParty: Codable, Sendable {

    public let id: String

    public let name: String

}

public struct PublicKeyUser: Codable, Sendable {

    public let id: Data

    public let name: String

    public let displayName: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case displayName
    }

}

public struct PublicKeyCredentialParameters: Codable, Sendable {

    public let alg: Int

    public let type: String = "public-key"

    enum CodingKeys: String, CodingKey {
        case alg
    }

}

public struct AuthenticatorSelectionCriteria: Codable, Sendable {

    public let residentKey: ResidentKey

    public let userVerification: UserVerification

    public enum ResidentKey: String, Codable, Sendable {

        case required

        case preferred

        case discouraged

    }

    public enum UserVerification: String, Codable, Sendable {

        case required

        case preferred

        case discouraged

    }

}

extension PublicKeyCredentialCreationOptions: Codable {

    enum CodingKeys: String, CodingKey {
        case relyingParty = "rp"
        case user
        case challengeData = "challenge"
        case credentialParameters = "pubKeyCredParams"
        case selectionCriteria = "authenticatorSelection"
        case timeout
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let userValues = try values.nestedContainer(keyedBy: PublicKeyUser.CodingKeys.self, forKey: .user)

        guard case let userIdString = try userValues.decode(String.self, forKey: .id),
              let userId = userIdString.a0_decodeBase64URLSafe() else {
            throw DecodingError.dataCorruptedError(forKey: .user,
                                                   in: values,
                                                   debugDescription: "Format of user.id is not recognized.")
        }

        user = PublicKeyUser(id: userId,
                             name: try userValues.decode(String.self, forKey: .name),
                             displayName: try userValues.decode(String.self, forKey: .displayName))

        guard case let challengeString = try values.decode(String.self, forKey: .challengeData),
              let challenge = challengeString.a0_decodeBase64URLSafe() else {
            throw DecodingError.dataCorruptedError(forKey: .challengeData,
                                                   in: values,
                                                   debugDescription: "Format of challenge is not recognized.")
        }

        challengeData = challenge
        relyingParty = try values.decode(PublicKeyRelyingParty.self, forKey: .relyingParty)
        credentialParameters = try values.decode([PublicKeyCredentialParameters].self, forKey: .credentialParameters)
        timeout = try values.decode(Int.self, forKey: .timeout)
        selectionCriteria = try values.decode(AuthenticatorSelectionCriteria.self, forKey: .selectionCriteria)
    }

}
#endif
