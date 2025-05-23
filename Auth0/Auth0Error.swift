import Foundation

let unknownError = "a0.sdk.internal_error.unknown"
let nonJSONError = "a0.sdk.internal_error.plain"
let emptyBodyError = "a0.sdk.internal_error.empty"

/// Generic representation of Auth0 errors.
public protocol Auth0Error: LocalizedError, CustomDebugStringConvertible {

    /// The underlying `Error` value, if any.
    var cause: Error? { get }

}

public extension Auth0Error {

    /// The underlying `Error` value, if any. Defaults to `nil`.
    var cause: Error? { return nil }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    var localizedDescription: String { return self.debugDescription }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    var errorDescription: String? { return self.debugDescription }

}

extension Auth0Error {

    func appendCause(to message: String) -> String {
        guard let cause = self.cause else {
            return message
        }

        let errorMessage = self.appendPeriod(to: message)
        let causeMessage = self.appendPeriod(to: String(describing: cause))

        return "\(errorMessage) CAUSE: \(causeMessage)"
    }

    func appendPeriod(to message: String) -> String {
        return message.hasSuffix(".") ? message : "\(message)."
    }

}
