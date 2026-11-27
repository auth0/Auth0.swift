#if PASSKEYS_PLATFORM
import Foundation

// MARK: - PasskeyUserVerification

/// The WebAuthn user verification requirement sent by the server with a passkey offer.
///
/// See ``PasskeyRequestOptions/userVerification`` and ``PasskeyCreationOptions/userVerification``.
public enum PasskeyUserVerification: String, Sendable, Equatable, CaseIterable {

    /// The authenticator must verify the user, for example with biometrics or the device passcode.
    case required

    /// The authenticator should verify the user when it can.
    case preferred

    /// The authenticator should not verify the user.
    case discouraged

}

// MARK: - PasskeyRequestOptions

/// The main WebAuthn request options the server sends with ``NextAction/verifyPasskey(options:requestJson:)``.
///
/// The app builds the platform request for the system passkey UI from these options, for example with
/// `ASAuthorizationPlatformPublicKeyCredentialProvider`; the SDK doesn't build or present it. The options are typed
/// because the system passkey API takes these values and not JSON. An app that runs the ceremony with its own WebAuthn
/// code can use `requestJson`, the complete options object, from the same next action. The relying party, the
/// challenge, the timeout and the user verification are always present: an offer that lacks one of them, or has a
/// user verification value this SDK version doesn't know, is dropped.
/// The allowed credentials and the hints can be empty, and keys this SDK version doesn't know are ignored.
/// Use the options exactly as received; never derive them from the SDK domain or reuse the options of an earlier offer.
public struct PasskeyRequestOptions: Sendable, Equatable {

    /// The relying party identifier. Use it as sent.
    public let relyingPartyId: String

    /// The single-use challenge, decoded from base64url.
    public let challengeData: Data

    /// The time in milliseconds the server allows for the ceremony.
    ///
    /// Informational only. The SDK doesn't impose a timeout, and the platform passkey request has no timeout setting.
    public let timeout: Int

    /// The user verification requirement.
    public let userVerification: PasskeyUserVerification

    /// The IDs of the credentials the server accepts, decoded from base64url.
    ///
    /// Empty means that any passkey for ``relyingPartyId`` is accepted.
    public let allowedCredentialIds: [Data]

    /// Hints about which kind of authenticator to prefer, as sent by the server.
    ///
    /// Informational only: the platform request the app builds from these options has no input for them.
    public let hints: [String]
}

// MARK: - Parsing

extension PasskeyRequestOptions {

    /// Parses the `authn_params_public_key` object of a passkey offer.
    ///
    /// `challenge`, `rpId`, `timeout` and `userVerification` are required, as in the server's API: an offer that lacks
    /// one of them, or sends it with the wrong type, is rejected. `timeout` must be a whole number, and a JSON boolean
    /// is not one. A `userVerification` value this SDK version doesn't know rejects the offer too. Unknown keys are
    /// ignored.
    /// Fails closed on `allowCredentials`: if it is present but is not an array, or any item has no decodable `id`,
    /// the whole offer is rejected, because dropping items could turn a restricted list into an empty one, which
    /// means "any credential".
    init?(json: [String: Any]) {
        guard let relyingPartyId = json["rpId"] as? String, !relyingPartyId.isEmpty,
              let challengeString = json["challenge"] as? String,
              let challenge = challengeString.a0_decodeBase64URLSafe(), !challenge.isEmpty,
              let timeout = json["timeout"] as? Int, !isJSONBoolean(json["timeout"]),
              let userVerificationString = json["userVerification"] as? String,
              let userVerification = PasskeyUserVerification(rawValue: userVerificationString) else { return nil }

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
                  timeout: timeout,
                  userVerification: userVerification,
                  allowedCredentialIds: credentialIds,
                  hints: (json["hints"] as? [Any])?.compactMap { $0 as? String } ?? [])
    }

    /// The `authn_params_public_key` object of a passkey offer as a JSON string: the complete options object the
    /// server sent, including keys this SDK version doesn't know. The keys are sorted, so the same offer always gives
    /// the same string.
    ///
    /// It holds the challenge, so it must never be logged. Returns `nil` if the object can't be written as JSON, which
    /// drops the offer.
    static func requestJson(from json: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(json),
              let data = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys, .withoutEscapingSlashes])
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

}

// MARK: - PasskeyCreationOptions

/// The main WebAuthn creation options the server sends with ``NextAction/registerPasskey(options:creationJson:)``.
///
/// The app builds the platform registration request from these options, for example with
/// `ASAuthorizationPlatformPublicKeyCredentialProvider`; the SDK doesn't build or present it. An offer that lacks the
/// relying party, the challenge, the user or the timeout, or has a user verification value this SDK version doesn't
/// know, isn't passed to your app, and keys this SDK version doesn't know are ignored. Use the options exactly as
/// received.
public struct PasskeyCreationOptions: Sendable, Equatable {

    /// The relying party identifier. Use it as sent.
    public let relyingPartyId: String

    /// The relying party display name.
    public let relyingPartyName: String

    /// The single-use challenge, decoded from base64url.
    public let challengeData: Data

    /// The user handle of the new passkey, decoded from base64url.
    public let userId: Data

    /// The name shown to the user for the passkey, for example the verified email.
    public let userName: String

    /// The display name shown to the user.
    public let userDisplayName: String

    /// The user verification requirement. ``PasskeyUserVerification/preferred`` when the server sends none.
    public let userVerification: PasskeyUserVerification

    /// The time in milliseconds the server allows for the ceremony.
    ///
    /// Informational only. The SDK doesn't impose a timeout, and the platform passkey request has no timeout setting.
    public let timeout: Int
}

extension PasskeyCreationOptions {

    /// Parses the `authn_params_public_key` object of a sign-up passkey offer.
    ///
    /// Fails if `challenge`, `rp`, `user` or `timeout` is missing, has the wrong type or is empty where a value is
    /// needed. `authenticatorSelection.userVerification` is optional, but a value this SDK version doesn't know rejects
    /// the offer. Unknown keys are ignored.
    init?(json: [String: Any]) {
        guard let challengeString = json["challenge"] as? String,
              let challenge = challengeString.a0_decodeBase64URLSafe(), !challenge.isEmpty,
              let relyingParty = json["rp"] as? [String: Any],
              let relyingPartyId = relyingParty["id"] as? String, !relyingPartyId.isEmpty,
              let relyingPartyName = relyingParty["name"] as? String,
              let user = json["user"] as? [String: Any],
              let userIdString = user["id"] as? String,
              let userId = userIdString.a0_decodeBase64URLSafe(), !userId.isEmpty,
              let userName = user["name"] as? String, !userName.isEmpty,
              let userDisplayName = user["displayName"] as? String,
              let timeout = json["timeout"] as? Int, !isJSONBoolean(json["timeout"]) else { return nil }

        var userVerification = PasskeyUserVerification.preferred
        if let selection = json["authenticatorSelection"] {
            guard let selection = selection as? [String: Any] else { return nil }
            if let rawValue = selection["userVerification"] {
                guard let string = rawValue as? String, let value = PasskeyUserVerification(rawValue: string) else { return nil }
                userVerification = value
            }
        }

        self.init(relyingPartyId: relyingPartyId,
                  relyingPartyName: relyingPartyName,
                  challengeData: challenge,
                  userId: userId,
                  userName: userName,
                  userDisplayName: userDisplayName,
                  userVerification: userVerification,
                  timeout: timeout)
    }

}

/// Whether `value` is a JSON boolean. `JSONSerialization` reads `true` as an `NSNumber` that converts to the integer
/// 1, so a plain `as? Int` can't tell it from a number.
private func isJSONBoolean(_ value: Any?) -> Bool {
    guard let number = value as? NSNumber else { return false }
    return CFGetTypeID(number) == CFBooleanGetTypeID()
}

// MARK: - Local errors

/// A local check on a passkey failed. The message never contains passkey data.
struct PasskeyInputError: Error {
    let message: String
}

#endif
