#if PASSKEYS_PLATFORM
import Foundation

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
              let timeout = json["timeout"] as? Int, !Self.isBoolean(json["timeout"]),
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

    /// Whether `value` is a JSON boolean. `JSONSerialization` reads `true` as an `NSNumber` that converts to the integer
    /// 1, so a plain `as? Int` can't tell it from a number.
    private static func isBoolean(_ value: Any?) -> Bool {
        guard let number = value as? NSNumber else { return false }
        return CFGetTypeID(number) == CFBooleanGetTypeID()
    }

}

// MARK: - Local errors

/// A local check on a passkey failed. The message never contains passkey data.
struct PasskeyInputError: Error {
    let message: String
}

#endif
