import Foundation

let apiErrorCode = "code"
let apiErrorDescription = "description"
let apiErrorCause = "cause"
let apiErrorDPoPNonce = "dpop_nonce"

/// Generic representation of Auth0 API errors.
public protocol Auth0APIError: Auth0Error {

    /// Raw error values.
    var info: [String: any Sendable] { get }

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
    init(info: [String: any Sendable], statusCode: Int)

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

    init(cause error: Error, statusCode: Int = 0) {
        let info: [String: any Sendable] = [
            apiErrorCode: nonJSONError,
            apiErrorDescription: "Unable to complete the operation.",
            apiErrorCause: error
        ]
        self.init(info: info, statusCode: statusCode)
    }

    init(description: String?, statusCode: Int = 0) {
        let info: [String: any Sendable] = [
            apiErrorCode: description != nil ? nonJSONError : emptyBodyError,
            apiErrorDescription: description ?? "Empty response body."
        ]
        self.init(info: info, statusCode: statusCode)
    }

    init(from response: ResponseValue) {
        if let dpopChallenge = DPoP.challenge(from: response.value) {
            var info: [String: any Sendable] = [apiErrorCode: dpopChallenge.errorCode]
            if let desc = dpopChallenge.errorDescription { info[apiErrorDescription] = desc }
            if let nonce = DPoP.extractNonce(from: response.value) { info[apiErrorDPoPNonce] = nonce }
            self.init(info: info, statusCode: response.value.statusCode)
        } else if let jsonDict = json(response.data) as? [String: Any] {
            var info = jsonDict.toSendable()
            if let nonce = DPoP.extractNonce(from: response.value) { info[apiErrorDPoPNonce] = nonce }
            self.init(info: info, statusCode: response.value.statusCode)
        } else {
            self.init(description: string(response.data), statusCode: response.value.statusCode)
        }
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

    /// Determines if the error is retryable based on its type.
    ///
    /// Returns `true` for:
    /// - Network errors (as determined by ``isNetworkError``)
    /// - Rate limiting errors (HTTP 429)
    /// - Server errors (HTTP 5xx)
    ///
    /// - Returns: `true` if the error is retryable, `false` otherwise.
    var isRetryable: Bool {
        // Retry on network errors
        if self.isNetworkError {
            return true
        }

        // Retry on rate limiting (429) or server errors (5xx)
        let statusCode = self.statusCode
        return statusCode == 429 || (500...599).contains(statusCode)
    }

}

func json(_ data: Data?) -> Any? {
    guard let data = data else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: [])
}

func string(_ data: Data?) -> String? {
    guard let data = data else { return nil }
    return String(data: data, encoding: .utf8)
}

private func makeInfoSendable(_ value: Any) -> (any Sendable)? {
    if let v = value as? String { return v }
    if let v = value as? Bool { return v }
    if let v = value as? Int { return v }
    if let v = value as? Double { return v }
    if let v = value as? [String: Any] { return v.toSendable() }
    if let v = value as? [Any] { return v.compactMap { makeInfoSendable($0) } }
    return nil
}

extension Dictionary where Key == String, Value == Any {
    func toSendable() -> [String: any Sendable] {
        compactMapValues { makeInfoSendable($0) }
    }
}
