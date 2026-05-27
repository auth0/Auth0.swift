#if PASSKEYS_PLATFORM
import Foundation

/// A passkey login challenge.
public struct PasskeyLoginChallenge: Sendable {

    /// Unique identifier of the Auth0 session.
    public let authenticationSession: String

    /// Custom domain configured in the Auth0 tenant.
    public let relyingPartyId: String

    /// Login challenge data.
    public let challengeData: Data

}

extension PasskeyLoginChallenge: Decodable {

    enum CodingKeys: String, CodingKey {
        case authenticationSession = "auth_session"
        case credentialRequestOptions = "authn_params_public_key"
    }

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let credentialOptions = try values.decode(PublicKeyCredentialRequestOptions.self,
                                                  forKey: .credentialRequestOptions)

        authenticationSession = try values.decode(String.self, forKey: .authenticationSession)
        relyingPartyId = credentialOptions.relyingPartyId
        challengeData = credentialOptions.challengeData

    }

}
#endif
