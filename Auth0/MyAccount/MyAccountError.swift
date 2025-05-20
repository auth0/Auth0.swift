import Foundation

/// Represents an error during a request to the Auth0 My Account API.
public struct MyAccountError: Auth0APIError, @unchecked Sendable {

    /// Raw error values.
    public let info: [String: Any]

    /// HTTP status code of the response.
    public let statusCode: Int

    /// Error code.
    public let code: String

    /// Error description.
    public let title: String

    /// More information about the error.
    public let detail: String

    /// Creates an error from a JSON response.
    ///
    /// - Parameters:
    ///   - info:       JSON response from Auth0.
    ///   - statusCode: HTTP status code of the response.
    ///
    /// - Returns: A new `NyAccountError`.
    public init(info: [String: Any], statusCode: Int) {
        self.info = info
        self.statusCode = statusCode
        self.code = info["type"] as? String ?? info[apiErrorCode] as? String ?? unknownError
        self.title = info["title"] as? String ?? info[apiErrorDescription] as? String ?? ""
        self.detail = info["detail"] as? String ?? ""
    }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    public var debugDescription: String {
        self.appendCause(to: self.message)
    }

}

// MARK: - Error Messages

extension MyAccountError {

    var message: String {
        if self.code == unknownError {
            return "Failed with unknown error: \(self.info)."
        }

        if !self.detail.isEmpty {
            return self.appendPeriod(to: "\(self.title): \(self.detail)")
        }

        return self.appendPeriod(to: "\(self.title)")
    }

}

// MARK: - Equatable

extension MyAccountError: Equatable {

    /// Conformance to `Equatable`.
    public static func == (lhs: MyAccountError, rhs: MyAccountError) -> Bool {
        return lhs.code == rhs.code
            && lhs.statusCode == rhs.statusCode
            && lhs.localizedDescription == rhs.localizedDescription
    }

}
