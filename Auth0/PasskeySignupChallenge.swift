import Foundation

public struct PasskeySignupChallenge: Codable {

    public let authenticationSession: String
    public let credentialCreationOptions: PublicKeyCredentialCreationOptions

    enum CodingKeys: String, CodingKey {
        case authenticationSession = "auth_session"
        case credentialCreationOptions = "authn_params_public_key"
    }

}
