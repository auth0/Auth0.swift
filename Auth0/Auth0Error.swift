import Foundation

let unknownError = "a0.sdk.internal_error.unknown"
let nonJSONError = "a0.sdk.internal_error.plain"
let emptyBodyError = "a0.sdk.internal_error.empty"

public protocol Auth0Error: LocalizedError {

    /// The underlying `Error`, if any
    var cause: Error? { get }

}

/**
   Generic representation of Auth0 API errors
   - note: It's recommended to use either `AuthenticationError` or `ManagementError` for better error handling
 */
public protocol Auth0APIError: Auth0Error {

    /// The code of the error as a String
    var code: String { get }

    /// Http Status Code of the response
    var statusCode: Int { get }

    /**
     Creates an error from a JSON response

     - parameter info:          JSON response from Auth0
     - parameter statusCode:    Http Status Code of the Response

     - returns: a newly created error
     */
    init(info: [String: Any], statusCode: Int?)

}

extension Auth0APIError {

    init(error: Error, statusCode: Int? = 0) {
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

    public init(info: [String: Any], statusCode: Int? = 0) {
        self.init(info: info, statusCode: statusCode)
    }

}
