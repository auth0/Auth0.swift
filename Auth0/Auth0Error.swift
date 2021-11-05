import Foundation

let unknownError = "a0.sdk.internal_error.unknown"
let nonJSONError = "a0.sdk.internal_error.plain"
let emptyBodyError = "a0.sdk.internal_error.empty"

/**
   Generic representation of Auth0 API errors
   - note: It's recommended to use either `AuthenticationError` or `ManagementError` for better error handling
 */
public protocol Auth0Error: Error {

    init(string: String?, statusCode: Int)
    init(info: [String: Any], statusCode: Int)

    /// The code of the error as a String
    var code: String { get }
}
