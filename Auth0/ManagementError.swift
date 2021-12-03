import Foundation

/**
 *  Represents an error during a request to Auth0 Management API
 */
public struct ManagementError: Auth0APIError {

    let info: [String: Any]

    /**
     Creates a Auth0 Management API error from a JSON response

     - parameter info:          JSON response from Auth0
     - parameter statusCode:    Http Status Code of the Response

     - returns: a newly created ManagementError
     */
    public init(info: [String: Any], statusCode: Int?) {
        var values = info
        values["statusCode"] = statusCode
        self.info = values
        self.statusCode = statusCode ?? 0
    }

    /**
     Http Status Code of the response
     */
    public let statusCode: Int

    /**
     The underlying `Error`, if any
     */
    public var cause: Error? {
        return self.info["cause"] as? Error
    }

    /**
     Auth0 error code if the server returned one or an internal library code (e.g.: when the server could not be reached)
     */
    public var code: String {
        return self.info["code"] as? String ?? unknownError
    }

    /**
     Description of the error
     - important: You should avoid displaying the description to the user, it's meant for debugging only.
     */
    public var localizedDescription: String {
        if let string = self.info["description"] as? String {
            return string
        }
        return "Failed with unknown error \(self.info)"
    }

}

extension ManagementError: Equatable {

    public static func == (lhs: ManagementError, rhs: ManagementError) -> Bool {
        return lhs.code == rhs.code
            && lhs.statusCode == rhs.statusCode
            && lhs.localizedDescription == rhs.localizedDescription
    }

}

extension ManagementError: CustomDebugStringConvertible {

    /**
     Description of the error, returns the same value as `localizedDescription`
     - important: You should avoid displaying the error description to the user, it's meant for debugging only.
     */
    public var debugDescription: String { return self.localizedDescription }

}

// MARK: - Subscript

public extension ManagementError {

    /**
     Returns a value from the error data

     - parameter key: key of the value to return

     - returns: the value of key or nil if cannot be found or is of the wrong type.
     */
    subscript<T>(_ key: String) -> T? {
        return self.info[key] as? T
    }

}
