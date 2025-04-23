#if !os(watchOS)
import Foundation

public struct PublicKeyCredentialCreationOptions: Codable {

    public let relyingParty: PublicKeyRelyingParty
    public let user: PublicKeyUser
    public let challenge: String
    public let credentialParameters: [PublicKeyCredentialParameters]

    public var timeout: TimeInterval? // MyAcc, AuthAPI
    public var selectionCriteria: AuthenticatorSelectionCriteria? // MyAcc, AuthAPI
    // var excludeCredentials: [PublicKeyCredentialDescriptor]? // NOT in MyAcc/AuthAPI
    // var hints: [String]? // NOT in MyAcc/AuthAPI
    // var attestation: String = "none" // NOT in MyAcc/AuthAPI TODO: Check if this can/should be nullable, or should just default to none
    // var attestationFormats: [String]? // NOT in MyAcc/AuthAPI

    public struct PublicKeyRelyingParty: Codable {
        public let name: String // ? MyAcc, AuthAPI
        public var id: String? // MyAcc, AuthAPI TODO: Check if this can actually be nil
    }

    public struct PublicKeyUser: Codable {
        public let id: String // MyAcc, AuthAPI
        public let name: String // MyAcc, AuthAPI
        public let displayName: String // MyAcc, AuthAPI
    }

    public struct PublicKeyCredentialParameters: Codable {
        public let alg: Int
        public let type: String
    }

    public struct AuthenticatorSelectionCriteria: Codable {
        // var authenticatorAttachment: String? // Not in MyAcc/AuthAPI
        public var residentKey: String? // MyAcc, AuthAPI
        public var userVerification: String? // MyAcc, AuthAPI TODO: Check if should default to "preferred"
        // var requireResidentKey: Bool = false // NOT in MyAcc/AuthAPI TODO: Check if this can/should be nullable, or should just default to false
    }

//    public struct PublicKeyCredentialDescriptor: Codable {
//        let id: String // ?
//        let type: String
//        var transports: [String]?
//    }

    enum CodingKeys: String, CodingKey {
        case relyingParty = "rp"
        case user
        case challenge
        case credentialParameters = "pubKeyCredParams"
        case timeout
        case selectionCriteria = "authenticatorSelection"
    }

}
#endif
