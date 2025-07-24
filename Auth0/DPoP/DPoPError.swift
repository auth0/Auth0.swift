/// Represents an error during a DPoP operation.
///
/// This error type encapsulates various issues that can occur while performing DPoP-related operations, such as key
/// generation, proof creation, or cryptographic failures.
public struct DPoPError: Auth0Error, Sendable {

    enum Code: Equatable {
        case secureEnclaveOperationFailed(String)
        case keychainOperationFailed(String)
        case cryptoKitOperationFailed(String)
        case secKeyOperationFailed(String)
        case other
        case unknown(String)
    }

    let code: Code

    init(code: Code, cause: Error? = nil) {
        self.code = code
        self.cause = cause
    }

    /// The underlying `Error` value, if any. Defaults to `nil`.
    public let cause: Error?

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    public var debugDescription: String {
        self.appendCause(to: self.message)
    }

    /// A Secure Enclave operation failed.
    /// The underlying `Error` value can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let secureEnclaveOperationFailed: DPoPError = .init(code: .secureEnclaveOperationFailed(""))

    /// A Keychain operation failed.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let keychainOperationFailed: DPoPError = .init(code: .keychainOperationFailed(""))

    /// A CryptoKit operation failed.
    /// The underlying `Error` value can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let cryptoKitOperationFailed: DPoPError = .init(code: .cryptoKitOperationFailed(""))

    /// A SecKey operation failed.
    /// When available, the underlying `Error` value can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let secKeyOperationFailed: DPoPError = .init(code: .secKeyOperationFailed(""))

    /// An unexpected error occurred, and an `Error` value is available.
    /// The underlying `Error` value can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let other: DPoPError = .init(code: .other)

    /// An unexpected error occurred, but an `Error` value is not available.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let unknown: DPoPError = .init(code: .unknown(""))

}

extension DPoPError {

    var message: String {
        switch self.code {
        case .secureEnclaveOperationFailed(let message): return message
        case .cryptoKitOperationFailed(let message): return message
        case .secKeyOperationFailed(let message): return message
        case .keychainOperationFailed(let message): return message
        case .other: return "An unexpected error occurred."
        case .unknown(let message): return message
        }
    }

}

// MARK: - Equatable

extension DPoPError: Equatable {

    /// Conformance to `Equatable`.
    public static func == (lhs: DPoPError, rhs: DPoPError) -> Bool {
        return lhs.code == rhs.code && lhs.localizedDescription == rhs.localizedDescription
    }

}

// MARK: - Pattern Matching Operator

public extension DPoPError {

    /// Matches `DPoPError` values in a switch statement.
    static func ~= (lhs: DPoPError, rhs: DPoPError) -> Bool {
        return lhs.code == rhs.code
    }

    /// Matches `Error` values in a switch statement.
    static func ~= (lhs: DPoPError, rhs: Error) -> Bool {
        guard let rhs = rhs as? DPoPError else { return false }
        return lhs.code == rhs.code
    }

}
