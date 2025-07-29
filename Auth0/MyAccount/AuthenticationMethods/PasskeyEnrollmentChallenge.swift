#if PASSKEYS_PLATFORM
import Foundation

/// A passkey enrollment challenge.
public struct PasskeyEnrollmentChallenge {

    /// Unique identifier of the authentication method.
    public let authenticationMethodId: String

    /// Unique identifier of the Auth0 session.
    public let authenticationSession: String

    /// Custom domain configured in the Auth0 tenant.
    public let relyingPartyId: String

    /// Generated unique identifier of the user.
    public let userId: Data

    /// A user identifier, like the user's email.
    public let userName: String

    /// Enrollment challenge data.
    public let challengeData: Data

}

extension PasskeyEnrollmentChallenge: Decodable {

    enum CodingKeys: String, CodingKey {
        case authenticationSession = "auth_session"
        case credentialCreationOptions = "authn_params_public_key"
    }

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        guard let headers = decoder.userInfo[.headersKey] as? [String: Any],
              let locationHeader = headers["Location"] as? String,
              let authenticationMethodId = locationHeader.components(separatedBy: "/").last else {
            let errorDescription = "Missing authentication method identifier in header 'Location'"
            let errorContext = DecodingError.Context(codingPath: [],
                                                     debugDescription: errorDescription)
            throw DecodingError.dataCorrupted(errorContext)
        }

        let values = try decoder.container(keyedBy: CodingKeys.self)
        let credentialOptions = try values.decode(PublicKeyCredentialCreationOptions.self,
                                                  forKey: .credentialCreationOptions)

        self.init(authenticationMethodId: authenticationMethodId,
                  authenticationSession: try values.decode(String.self, forKey: .authenticationSession),
                  relyingPartyId: credentialOptions.relyingParty.id,
                  userId: credentialOptions.user.id,
                  userName: credentialOptions.user.name,
                  challengeData: credentialOptions.challengeData)
    }

}
#endif
