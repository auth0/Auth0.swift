import Foundation

/**
 *  Represents an error during a request to the Auth0 Management API.
 */
public struct ManagementError: Auth0APIError {

    /**
     Additional information about the error.
     */
    public let info: [String: Any]

    /**
     Creates an error from a JSON response.

     - Parameters:
       - info:       JSON response from Auth0.
       - statusCode: HTTP Status Code of the response.

     - Returns: A newly created error.
     */
    public init(info: [String: Any], statusCode: Int) {
        var values = info
        values["statusCode"] = statusCode
        self.info = values
        self.statusCode = statusCode
    }

    /**
     HTTP Status Code of the response.
     */
    public let statusCode: Int

    /**
     The underlying `Error`, if any. Defaults to `nil`.
     */
    public var cause: Error? {
        return self.info["cause"] as? Error
    }

    /**
     The code of the error as a string.
     */
    public var code: String {
        return self.info["code"] as? String ?? unknownError
    }

    /**
     Description of the error.

     - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
     */
    public var debugDescription: String {
        if let string = self.info["description"] as? String {
            return string
        }
        return "Failed with unknown error \(self.info)"
    }

}

// MARK: - Equatable

extension ManagementError: Equatable {

    /// Conformance to `Equatable`.
    public static func == (lhs: ManagementError, rhs: ManagementError) -> Bool {
        return lhs.code == rhs.code
            && lhs.statusCode == rhs.statusCode
            && lhs.localizedDescription == rhs.localizedDescription
    }

}
