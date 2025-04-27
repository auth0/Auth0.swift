import Foundation

public struct PasskeySignupChallenge: Codable, Sendable {

    public let authenticationSession: String
    public let credentialOptions: PublicKeyCredentialCreationOptions

    enum CodingKeys: String, CodingKey {
        case authenticationSession = "auth_session"
        case credentialOptions = "authn_params_public_key"
    }

}
