import Foundation

let unknownError = "a0.sdk.internal_error.unknown"
let nonJSONError = "a0.sdk.internal_error.plain"
let emptyBodyError = "a0.sdk.internal_error.empty"

public protocol Auth0Error: LocalizedError, CustomDebugStringConvertible {

    /**
     The underlying `Error`, if any. Defaults to `nil`.
     */
    var cause: Error? { get }

}

public extension Auth0Error {

    /**
     The underlying `Error`, if any. Defaults to `nil`.
     */
    var cause: Error? { return nil }

    /**
     Description of the error.

     - Important: You should avoid displaying the error description to the user, it's meant for debugging only.
     */
    var localizedDescription: String { return self.debugDescription }

    /**
     Description of the error.

     - Important: You should avoid displaying the error description to the user, it's meant for debugging only.
     */
    var errorDescription: String? { return self.debugDescription }

}

/**
   Generic representation of Auth0 API errors.

   - Note: It's recommended to use either `AuthenticationError` or `ManagementError` for better error handling.
 */
public protocol Auth0APIError: Auth0Error {

    /**
     The code of the error as a String.
     */
    var code: String { get }

    /**
     HTTP Status Code of the response.
     */
    var statusCode: Int { get }

    /**
     Creates an error from a JSON response.

     - Parameters:
       - info:       JSON response from Auth0.
       - statusCode: HTTP Status Code of the Response.

     - Returns: A newly created error.
     */
    init(info: [String: Any], statusCode: Int?)

    /**
     Returns a value from the error data.

     - Parameter key: Key of the value to return.
     - Returns: The value of key or nil if cannot be found or is of the wrong type.
     */
    subscript<T>(_ key: String) -> T? { get }

}

extension Auth0APIError {

    init(info: [String: Any], statusCode: Int? = 0) {
        self.init(info: info, statusCode: statusCode)
    }

    init(cause error: Error, statusCode: Int? = 0) {
        let info: [String: Any] = [
            "code": nonJSONError,
            "description": error.localizedDescription,
            "cause": error
        ]
        self.init(info: info, statusCode: statusCode)
    }

    init(description: String?, statusCode: Int? = 0) {
        let info: [String: Any] = [
            "code": description != nil ? nonJSONError : emptyBodyError,
            "description": description ?? "Empty response body"
        ]
        self.init(info: info, statusCode: statusCode)
    }

    init(from response: Response<Self>) {
        self.init(description: string(response.data), statusCode: response.response?.statusCode)
    }

}
