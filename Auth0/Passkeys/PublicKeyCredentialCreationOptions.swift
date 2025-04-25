#if !os(watchOS)
import Foundation

public struct PublicKeyCredentialCreationOptions {

    public let relyingParty: PublicKeyRelyingParty
    public let user: PublicKeyUser
    public let challenge: Data
    public let credentialParameters: [PublicKeyCredentialParameters]
    public let timeout: Int // ? MyAcc, AuthAPI
    public let selectionCriteria: AuthenticatorSelectionCriteria // ? MyAcc, AuthAPI

    // var excludeCredentials: [PublicKeyCredentialDescriptor]? // NOT in MyAcc/AuthAPI
    // var hints: [String]? // NOT in MyAcc/AuthAPI
    // var attestation: String = "none" // NOT in MyAcc/AuthAPI TODO: Check if this can/should be nullable, or should just default to none
    // var attestationFormats: [String]? // NOT in MyAcc/AuthAPI

    public struct PublicKeyRelyingParty: Codable {
        public let id: String // ? MyAcc, AuthAPI TODO: Check if this can actually be nil
        public let name: String // MyAcc, AuthAPI
    }

    public struct PublicKeyUser: Codable {
        public let id: Data // MyAcc, AuthAPI
        public let name: String // MyAcc, AuthAPI
        public let displayName: String // MyAcc, AuthAPI

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case displayName
        }
    }

    public struct PublicKeyCredentialParameters: Codable {
        public let alg: Int
        public let type: String
    }

    public struct AuthenticatorSelectionCriteria: Codable {
        public let residentKey: String // ? MyAcc, AuthAPI
        public let userVerification: String // ? MyAcc, AuthAPI TODO: Check if should default to "preferred"

        // var authenticatorAttachment: String? // Not in MyAcc/AuthAPI
        // var requireResidentKey: Bool = false // NOT in MyAcc/AuthAPI TODO: Check if this can/should be nullable, or should just default to false
    }

//    public struct PublicKeyCredentialDescriptor: Codable {
//        let id: String // ?
//        let type: String
//        var transports: [String]?
//    }

}

extension PublicKeyCredentialCreationOptions: Codable {

    enum CodingKeys: String, CodingKey {
        case relyingParty = "rp"
        case user
        case challenge
        case credentialParameters = "pubKeyCredParams"
        case timeout
        case selectionCriteria = "authenticatorSelection"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let userValues = try values.nestedContainer(keyedBy: PublicKeyUser.CodingKeys.self, forKey: .user)

        guard case let userIdString = try userValues.decode(String.self, forKey: .id),
              let userIdData = userIdString.a0_decodeBase64URLSafe() else {
            throw DecodingError.dataCorruptedError(forKey: .user,
                                                   in: values,
                                                   debugDescription: "Format of user.id is not recognized.")
        }

        user = PublicKeyUser(id: userIdData,
                             name: try userValues.decode(String.self, forKey: .name),
                             displayName: try userValues.decode(String.self, forKey: .displayName))

        guard case let challengeString = try values.decode(String.self, forKey: .challenge),
              let challengeData = challengeString.a0_decodeBase64URLSafe() else {
            throw DecodingError.dataCorruptedError(forKey: .challenge,
                                                   in: values,
                                                   debugDescription: "Format of challenge is not recognized.")
        }

        challenge = challengeData
        relyingParty = try values.decode(PublicKeyRelyingParty.self, forKey: .relyingParty)
        credentialParameters = try values.decode([PublicKeyCredentialParameters].self, forKey: .credentialParameters)
        timeout = try values.decode(Int.self, forKey: .timeout)
        selectionCriteria = try values.decode(AuthenticatorSelectionCriteria.self, forKey: .selectionCriteria)
    }

}
#endif
