#if PASSKEYS_PLATFORM
import Foundation

/// A passkey signup challenge.
public struct PasskeySignupChallenge: Sendable {

    /// Session identifier.
    public let authenticationSession: String

    /// Custom domain configured in the Auth0 tenant.
    public let relyingPartyId: String

    /// Generated identifier.
    public let userId: Data

    /// User identifier, like the user's email.
    public let userName: String

    /// Signup challenge data.
    public let challengeData: Data

}

extension PasskeySignupChallenge: Decodable {

    enum CodingKeys: String, CodingKey {
        case authenticationSession = "auth_session"
        case credentialCreationOptions = "authn_params_public_key"
    }

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let credentialOptions = try values.decode(PublicKeyCredentialCreationOptions.self,
                                                  forKey: .credentialCreationOptions)

        authenticationSession = try values.decode(String.self, forKey: .authenticationSession)
        relyingPartyId = credentialOptions.relyingParty.id
        userId = credentialOptions.user.id
        userName = credentialOptions.user.name
        challengeData = credentialOptions.challengeData

    }

}
#endif
