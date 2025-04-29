#if !os(tvOS) && !os(watchOS)
import Foundation

/// A passkey login challenge.
@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
public struct PasskeyLoginChallenge: Sendable {

    /// Session identifier.
    public let authenticationSession: String

    /// Custom domain configured in the Auth0 tenant.
    public let relyingPartyId: String

    /// Login challenge data.
    public let challengeData: Data

}

@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
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
