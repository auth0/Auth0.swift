import Foundation

let apiErrorCode = "code"
let apiErrorDescription = "description"
let apiErrorCause = "cause"

/// Generic representation of Auth0 API errors.
public protocol Auth0APIError: Auth0Error {

    /// Raw error values.
    var info: [String: Any] { get }

    /// Error code.
    var code: String { get }

    /// HTTP status code of the response.
    var statusCode: Int { get }

    /// Creates an error from a JSON response.
    ///
    /// - Parameters:
    ///   - info:       JSON response from Auth0.
    ///   - statusCode: HTTP status code of the response.
    ///
    /// - Returns: A new `Auth0APIError`.
    init(info: [String: Any], statusCode: Int)

}

public extension Auth0APIError {

    /// The underlying `Error` value, if any. Defaults to `nil`.
    var cause: Error? {
        return self.info["cause"] as? Error
    }

    /// Whether the request failed due to network issues.
    ///
    /// Returns `true` when the `URLError` code is one of the following:
    /// - [dataNotAllowed](https://developer.apple.com/documentation/foundation/urlerror/datanotallowed)
    /// - [notConnectedToInternet](https://developer.apple.com/documentation/foundation/urlerror/notconnectedtointernet)
    /// - [networkConnectionLost](https://developer.apple.com/documentation/foundation/urlerror/networkconnectionlost)
    /// - [dnsLookupFailed](https://developer.apple.com/documentation/foundation/urlerror/dnslookupfailed)
    /// - [cannotFindHost](https://developer.apple.com/documentation/foundation/urlerror/cannotfindhost)
    /// - [cannotConnectToHost](https://developer.apple.com/documentation/foundation/urlerror/cannotconnecttohost)
    /// - [timedOut](https://developer.apple.com/documentation/foundation/urlerror/timedout)
    /// - [internationalRoamingOff](https://developer.apple.com/documentation/foundation/urlerror/internationalroamingoff)
    /// - [callIsActive](https://developer.apple.com/documentation/foundation/urlerror/callisactive)
    ///
    /// The underlying `URLError` is available in the ``cause`` property.
    var isNetworkError: Bool {
        guard let code = (self.cause as? URLError)?.code else {
            return false
        }

        return Self.networkErrorCodes.contains(code)
    }

}

extension Auth0APIError {

    init(info: [String: Any], statusCode: Int = 0) {
        self.init(info: info, statusCode: statusCode)
    }

    init(cause error: Error, statusCode: Int = 0) {
        let info: [String: Any] = [
            apiErrorCode: nonJSONError,
            apiErrorDescription: "Unable to complete the operation.",
            apiErrorCause: error
        ]
        self.init(info: info, statusCode: statusCode)
    }

    init(description: String?, statusCode: Int = 0) {
        let info: [String: Any] = [
            apiErrorCode: description != nil ? nonJSONError : emptyBodyError,
            apiErrorDescription: description ?? "Empty response body."
        ]
        self.init(info: info, statusCode: statusCode)
    }

    init(from response: Response<Self>) {
        self.init(description: string(response.data), statusCode: response.response?.statusCode ?? 0)
    }

    static var networkErrorCodes: [URLError.Code] {
        return [
            .dataNotAllowed,
            .notConnectedToInternet,
            .networkConnectionLost,
            .dnsLookupFailed,
            .cannotFindHost,
            .cannotConnectToHost,
            .timedOut,
            .internationalRoamingOff,
            .callIsActive
        ]
    }

}
