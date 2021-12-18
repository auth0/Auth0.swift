import Foundation

let unknownError = "a0.sdk.internal_error.unknown"
let nonJSONError = "a0.sdk.internal_error.plain"
let emptyBodyError = "a0.sdk.internal_error.empty"

/**
 Generic representation of Auth0 errors. ``AuthenticationError``, ``ManagementError``, ``WebAuthError``, and
 ``CredentialsManagerError`` conform to this protocol.
 */
public protocol Auth0Error: LocalizedError, CustomDebugStringConvertible {

    /**
     The underlying `Error`, if any.
     */
    var cause: Error? { get }

}

public extension Auth0Error {

    /**
     Defaults to `nil`.
     */
    var cause: Error? { return nil }

    /**
     Description of the error.

     - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
     */
    var localizedDescription: String { return self.debugDescription }

    /**
     Description of the error.

     - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
     */
    var errorDescription: String? { return self.debugDescription }

}

/**
 Generic representation of Auth0 API errors. ``AuthenticationError`` and ``ManagementError`` conform to this protocol.
 */
public protocol Auth0APIError: Auth0Error {

    /**
     Additional information about the error.
     */
    var info: [String: Any] { get }

    /**
     The code of the error as a string.
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
       - statusCode: HTTP Status Code of the response.

     - Returns: A newly created error.
     */
    init(info: [String: Any], statusCode: Int)

}

extension Auth0APIError {

    init(info: [String: Any], statusCode: Int = 0) {
        self.init(info: info, statusCode: statusCode)
    }

    init(cause error: Error, statusCode: Int = 0) {
        let info: [String: Any] = [
            "code": nonJSONError,
            "description": error.localizedDescription,
            "cause": error
        ]
        self.init(info: info, statusCode: statusCode)
    }

    init(description: String?, statusCode: Int = 0) {
        let info: [String: Any] = [
            "code": description != nil ? nonJSONError : emptyBodyError,
            "description": description ?? "Empty response body"
        ]
        self.init(info: info, statusCode: statusCode)
    }

    init(from response: Response<Self>) {
        self.init(description: string(response.data), statusCode: response.response?.statusCode ?? 0)
    }

}
