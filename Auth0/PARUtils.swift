#if WEB_AUTH_PLATFORM
import Foundation

extension PARWebAuth {

    static let requestUriPrefix = "urn:ietf:params:oauth:request_uri:"

    /// Validates that the request_uri conforms to the expected PAR format.
    ///
    /// - Parameter requestUri: The request_uri value to validate.
    /// - Returns: `true` if the request_uri starts with the required prefix.
    static func isValidRequestUri(_ requestUri: String) -> Bool {
        return requestUri.hasPrefix(requestUriPrefix)
    }

    /// Builds the `/authorize` URL for a PAR flow containing `client_id` and `request_uri`,
    /// plus any additional query parameters.
    ///
    /// - Parameters:
    ///   - baseURL: The Auth0 domain URL.
    ///   - clientId: The Auth0 client ID.
    ///   - requestUri: The request_uri from the PAR endpoint response.
    ///   - additionalParameters: Extra query parameters to append (e.g., session_transfer_token).
    /// - Returns: The fully constructed authorize URL.
    static func buildAuthorizeURL(baseURL: URL,
                                  clientId: String,
                                  requestUri: String,
                                  additionalParameters: [String: String] = [:]) -> URL {
        let authorizeURL = baseURL.appendingPathComponent("authorize")
        var components = URLComponents(url: authorizeURL, resolvingAgainstBaseURL: true)!
        var queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "request_uri", value: requestUri)
        ]
        for (key, value) in additionalParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = queryItems
        return components.url!
    }

}
#endif
