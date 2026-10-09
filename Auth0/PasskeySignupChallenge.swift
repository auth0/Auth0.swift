#if PASSKEYS_PLATFORM
import Foundation

/// A passkey signup challenge.
public struct PasskeySignupChallenge: Sendable {

    /// Unique identifier of the Auth0 session.
    public let authenticationSession: String

    /// Custom domain configured in the Auth0 tenant.
    public let relyingPartyId: String

    /// Generated unique identifier of the user.
    public let userId: Data

    /// A user identifier, like the user's email.
    public let userName: String

    /// Signup challenge data.
    public let challengeData: Data

    /// Identifiers whose ownership must be verified with a one-time code before the signup can complete, if any
    /// (e.g. `[.email]`). Auth0 sends a code to each listed identifier. `nil` when no verification is required.
    public let verificationRequired: [PasskeyVerificationMethod]?

    /// Creates a new ``PasskeySignupChallenge`` instance.
    ///
    /// - Parameters:
    ///   - authenticationSession: Unique identifier of the Auth0 session.
    ///   - relyingPartyId: Custom domain configured in the Auth0 tenant.
    ///   - userId: Generated unique identifier of the user.
    ///   - userName: A user identifier, like the user's email.
    ///   - challengeData: Signup challenge data.
    ///   - verificationRequired: Identifiers that must be verified with a one-time code, if any.
    public init(authenticationSession: String,
                relyingPartyId: String,
                userId: Data,
                userName: String,
                challengeData: Data,
                verificationRequired: [PasskeyVerificationMethod]? = nil) {
        self.authenticationSession = authenticationSession
        self.relyingPartyId = relyingPartyId
        self.userId = userId
        self.userName = userName
        self.challengeData = challengeData
        self.verificationRequired = verificationRequired
    }

}

extension PasskeySignupChallenge: Decodable {

    enum CodingKeys: String, CodingKey {
        case authenticationSession = "auth_session"
        case credentialCreationOptions = "authn_params_public_key"
        case verificationRequired = "verification_required"
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
        verificationRequired = try values.decodeIfPresent([PasskeyVerificationMethod].self, forKey: .verificationRequired)
    }

}
#endif
