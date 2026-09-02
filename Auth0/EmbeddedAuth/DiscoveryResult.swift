import Foundation

// MARK: - DiscoveryResult

/// The live set of login alternatives available for a client, returned by
/// ``EmbeddedAuth/discover(connection:)``.
public struct DiscoveryResult: Sendable {

    /// Ordered list of login alternatives as advertised by the server.
    public let options: [LoginOption]

    /// Initializes a result from a decoded list of alternatives.
    init(options: [LoginOption]) {
        self.options = options
    }

    /// The distinct grant types present in ``options``.
    public var types: [GrantType] {
        var seen = Set<GrantType>()
        return options.compactMap { opt in
            let type = opt.grantType
            return seen.insert(type).inserted ? type : nil
        }
    }

    /// Realm names for all `.passwordRealm` alternatives.
    public var passwordRealms: [String] {
        options.compactMap {
            guard case .passwordRealm(let realm) = $0 else { return nil }
            return realm
        }
    }

    /// Connection names for all `.passkey` alternatives.
    public var passkeyConnections: [String] {
        options.compactMap {
            guard case .passkey(let conn) = $0 else { return nil }
            return conn
        }
    }

    /// Projected ``OTPOption`` values for all `.passwordlessOtp` alternatives.
    public var otpOptions: [OTPOption] {
        options.compactMap {
            guard case .passwordlessOtp(let conn, let ids, let type) = $0 else { return nil }
            return OTPOption(connection: conn, identifiers: ids, type: type)
        }
    }

    /// `subject_token_type` values for all `.nativeSocial` alternatives.
    public var socialProviders: [String] {
        options.compactMap {
            guard case .nativeSocial(let stt) = $0 else { return nil }
            return stt
        }
    }

    /// Returns `true` if any alternative matches the given grant type.
    public func supports(_ grantType: GrantType) -> Bool {
        options.contains { $0.grantType == grantType }
    }

}

// MARK: - LoginOption

/// A single login alternative returned by the discovery endpoint.
public enum LoginOption: Sendable {

    /// Resource Owner Password Grant against the tenant's default directory.
    case password

    /// Resource Owner Password Realm Grant against a named realm (connection).
    case passwordRealm(realm: String)

    /// Passkey (WebAuthn) against a named connection.
    case passkey(connection: String)

    /// Passwordless OTP — either `legacy` (via `/passwordless/start`) or `auth0` (via `/otp/challenge`).
    case passwordlessOtp(connection: String, identifiers: [PasswordlessIdentifier], type: OTPFlowType)

    /// Native social login via token exchange (Google, Apple, Facebook).
    case nativeSocial(subjectTokenType: String)

    /// Interactive embedded authorization via `POST /e/authorize`.
    case embeddedAuthorize(connection: String)

    /// An unrecognized grant type returned by the server (forward-compatibility).
    case unknown(rawGrantType: String, connection: String?)

    // MARK: Convenience

    /// The ``GrantType`` that classifies this alternative.
    public var grantType: GrantType {
        switch self {
        case .password:            return .password
        case .passwordRealm:       return .passwordRealm
        case .passkey:             return .passkey
        case .passwordlessOtp:     return .passwordlessOtp
        case .nativeSocial:        return .nativeSocial
        case .embeddedAuthorize:   return .authorizationCode
        case .unknown:             return .unknown
        }
    }

    /// The connection name associated with this alternative, if any.
    public var connection: String? {
        switch self {
        case .password, .nativeSocial:                          return nil
        case .passwordRealm:                                    return nil
        case .passkey(let conn), .embeddedAuthorize(let conn):  return conn
        case .passwordlessOtp(let conn, _, _):                  return conn
        case .unknown(_, let conn):                             return conn
        }
    }

}

// MARK: - Supporting types

/// High-level grant type classification for a ``LoginOption``.
public enum GrantType: Sendable, Hashable {
    case password
    case passwordRealm
    case passkey
    case passwordlessOtp
    case nativeSocial
    case authorizationCode
    case unknown
}

/// The identifier type accepted by a passwordless OTP connection.
public enum PasswordlessIdentifier: Sendable, Equatable {
    /// Email address.
    case email
    /// Phone number.
    case phoneNumber
}

/// Which passwordless flow a connection uses, determining the follow-up API call.
///
/// - `legacy`: Use `POST /passwordless/start` → verify with realm + otp.
/// - `auth0`:  Use `POST /otp/challenge` → verify with auth_session + otp.
public enum OTPFlowType: Sendable, Equatable {
    case legacy
    case auth0
}

/// Projected OTP details for a `.passwordlessOtp` alternative.
public struct OTPOption: Sendable {
    /// Name of the connection.
    public let connection: String
    /// Identifier types this connection accepts.
    public let identifiers: [PasswordlessIdentifier]
    /// Which passwordless flow the connection uses.
    public let type: OTPFlowType
}
