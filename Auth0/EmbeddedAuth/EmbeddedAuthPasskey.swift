import Foundation
#if PASSKEYS_PLATFORM
import AuthenticationServices
#endif

// MARK: - PasskeyUserVerification

/// The WebAuthn user verification requirement sent by the server with a passkey offer.
///
/// See ``PasskeyRequestOptions/userVerification``.
public enum PasskeyUserVerification: String, Sendable, Equatable, CaseIterable {

    /// The authenticator must verify the user, for example with biometrics or the device passcode.
    case required

    /// The authenticator should verify the user when it can.
    case preferred

    /// The authenticator should not verify the user.
    case discouraged

}

// MARK: - PasskeyRequestOptions

/// The WebAuthn request options the server sends with ``NextAction/verifyPasskey(options:)``.
///
/// Use ``assertionRequest()`` to turn them into the request for the system passkey UI. Parsing is tolerant: the
/// server may add, change or drop optional values, so don't rely on any value matching what the server sent before.
/// Use the options exactly as received; never derive them from the SDK domain or reuse the options of an earlier offer.
public struct PasskeyRequestOptions: Sendable, Equatable {

    /// The relying party identifier. Use it as sent.
    public let relyingPartyId: String

    /// The single-use challenge, decoded from base64url.
    public let challengeData: Data

    /// The time in milliseconds the server allows for the ceremony, if it sent one.
    ///
    /// Informational only. The SDK doesn't impose a timeout, and the platform passkey request has no timeout setting.
    public let timeout: Int?

    /// The user verification requirement, or `nil` when the server sent none or one this SDK version doesn't recognise.
    public let userVerification: PasskeyUserVerification?

    /// The IDs of the credentials the server accepts, decoded from base64url.
    ///
    /// Empty means that any passkey for ``relyingPartyId`` is accepted.
    public let allowedCredentialIds: [Data]

    /// Hints about which kind of authenticator to prefer, as sent by the server.
    ///
    /// Informational only: ``assertionRequest()`` can't apply them, as the platform has no input for them.
    public let hints: [String]

    /// Creates request options, for example for tests or previews.
    ///
    /// - Parameters:
    ///   - relyingPartyId:       The relying party identifier.
    ///   - challengeData:        The challenge, as raw bytes.
    ///   - timeout:              The time in milliseconds the server allows for the ceremony.
    ///   - userVerification:     The user verification requirement.
    ///   - allowedCredentialIds: The IDs of the credentials the server accepts. Empty means any passkey.
    ///   - hints:                Hints about which kind of authenticator to prefer.
    public init(relyingPartyId: String,
                challengeData: Data,
                timeout: Int? = nil,
                userVerification: PasskeyUserVerification? = nil,
                allowedCredentialIds: [Data] = [],
                hints: [String] = []) {
        self.relyingPartyId = relyingPartyId
        self.challengeData = challengeData
        self.timeout = timeout
        self.userVerification = userVerification
        self.allowedCredentialIds = allowedCredentialIds
        self.hints = hints
    }

}

// MARK: - Parsing

extension PasskeyRequestOptions {

    /// Parses the `authn_params_public_key` object of a passkey offer.
    ///
    /// Only `challenge` and `rpId` are required. Unknown keys and unrecognised optional values are ignored.
    /// Fails closed on `allowCredentials`: if it is present but is not an array, or any item has no decodable `id`,
    /// the whole offer is rejected, because dropping items could turn a restricted list into an empty one, which
    /// means "any credential".
    init?(json: [String: Any]) {
        guard let relyingPartyId = json["rpId"] as? String, !relyingPartyId.isEmpty,
              let challengeString = json["challenge"] as? String,
              let challenge = challengeString.a0_decodeBase64URLSafe(), !challenge.isEmpty else { return nil }

        var credentialIds: [Data] = []
        if let rawList = json["allowCredentials"] {
            guard let list = rawList as? [Any] else { return nil }
            for item in list {
                guard let descriptor = item as? [String: Any],
                      let idString = descriptor["id"] as? String,
                      let credentialId = idString.a0_decodeBase64URLSafe(), !credentialId.isEmpty else { return nil }
                credentialIds.append(credentialId)
            }
        }

        self.init(relyingPartyId: relyingPartyId,
                  challengeData: challenge,
                  timeout: json["timeout"] as? Int,
                  userVerification: (json["userVerification"] as? String).flatMap(PasskeyUserVerification.init(rawValue:)),
                  allowedCredentialIds: credentialIds,
                  hints: (json["hints"] as? [Any])?.compactMap { $0 as? String } ?? [])
    }

}

// MARK: - Debug log

extension Auth0EmbeddedAuth {

    /// Logs, once per client and only when debug logging is on, that the server didn't offer a passkey although
    /// the capability was declared.
    ///
    /// The SDK can't tell why: the capability wasn't accepted, passkey login is off on the connection, or the domain
    /// is not a custom domain. The message never contains the session, a challenge or any other flow data.
    func logPasskeyNotOfferedIfNeeded(_ result: Result<ResponseValue, EmbeddedAuthError>) {
        guard logger != nil,
              !hasLoggedPasskeyNotOffered,
              case .failure(let error) = result,
              case .insufficientAuthorization = error.reason else { return }
        let entries = error.info["next"] as? [[String: Any]] ?? []
        let isOffered = entries.contains { $0["action"] as? String == EmbeddedAction.verifyPasskey.rawValue }
        guard !isOffered else { return }
        hasLoggedPasskeyNotOffered = true
        var message = "Passkey wasn't offered. Check the custom domain and the connection's passkey settings."
        if url.host?.lowercased().hasSuffix(".auth0.com") == true {
            message = "Passkey wasn't offered. The SDK domain is an Auth0 canonical domain, and passkeys are only offered on a custom domain."
        }
        unifiedLog.debug(.configuration, message)
    }

}

#if PASSKEYS_PLATFORM

// MARK: - Platform request

@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
public extension PasskeyRequestOptions {

    /// Builds the platform request for the system passkey UI, with the server options applied: relying party,
    /// challenge, user verification and allowed credentials.
    ///
    /// Use it with `ASAuthorizationController` to show the passkey sheet, or with `performAutoFillAssistedRequests()`
    /// to offer the passkey in AutoFill. Pass the resulting
    /// `ASAuthorizationPlatformPublicKeyCredentialAssertion` to ``EmbeddedAuth/verifyPasskey(_:)``.
    ///
    /// ``timeout`` and ``hints`` have no platform equivalent and are not applied.
    ///
    /// - Returns: The assertion request.
    func assertionRequest() -> ASAuthorizationPlatformPublicKeyCredentialAssertionRequest {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyId)
        let request = provider.createCredentialAssertionRequest(challenge: challengeData)
        switch userVerification {
        case .required?:
            request.userVerificationPreference = .required
        case .preferred?:
            request.userVerificationPreference = .preferred
        case .discouraged?:
            request.userVerificationPreference = .discouraged
        case nil:
            break
        }
        request.allowedCredentials = allowedCredentialIds.map {
            ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: $0)
        }
        return request
    }

}

// MARK: - verifyPasskey

/// A local check on a passkey failed. The message never contains passkey data.
struct PasskeyInputError: Error {
    let message: String
}

extension Auth0EmbeddedAuth {

    /// Submits a passkey assertion to sign the user in.
    /// On success, internally exchanges the authorization code for ``Credentials``.
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func verifyPasskey(_ passkey: any LoginPasskey) -> Request<Credentials, EmbeddedAuthError> {
        guard let currentSession else { return missingSessionRequest() }
        let assertion: [String: Any]
        do {
            assertion = try Self.passkeyAssertion(from: passkey)
        } catch let error as PasskeyInputError {
            return invalidInputRequest(message: error.message)
        } catch {
            return invalidInputRequest(message: "This passkey can't be used.")
        }
        return Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: decodeAuthorizationCodeResponse,
            parameters: [
                "client_id": clientId,
                "action": EmbeddedAction.verifyPasskey.rawValue,
                "auth_session": currentSession,
                "authn_response": assertion
            ],
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    /// Maps a passkey to the `authn_response` object, with only the fields the server accepts, base64url-encoded.
    ///
    /// Max lengths are not checked here: the server decides.
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    static func passkeyAssertion(from passkey: any LoginPasskey) throws -> [String: Any] {
        guard let userID = passkey.userID, !userID.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no user handle. Only discoverable passkeys are supported.")
        }
        let credentialID = passkey.credentialID
        guard !credentialID.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no credential ID.")
        }
        let clientData = passkey.rawClientDataJSON
        guard !clientData.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no client data.")
        }
        guard let authenticatorData = passkey.rawAuthenticatorData, !authenticatorData.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no authenticator data.")
        }
        guard let signature = passkey.signature, !signature.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no signature.")
        }

        let id = credentialID.encodeBase64URLSafe()
        var assertion: [String: Any] = [
            "id": id,
            "rawId": id,
            "type": "public-key",
            "response": [
                "clientDataJSON": clientData.encodeBase64URLSafe(),
                "authenticatorData": authenticatorData.encodeBase64URLSafe(),
                "signature": signature.encodeBase64URLSafe(),
                "userHandle": userID.encodeBase64URLSafe()
            ]
        ]
        if let attachment = passkey.attachment.stringValue {
            assertion["authenticatorAttachment"] = attachment
        }
        return assertion
    }

}

#endif
