import Foundation

/// Utility for redacting sensitive data from JSON responses.
struct SensitiveDataRedactor {
    
    /// List of sensitive keys that should be redacted.
    private static let sensitiveKeys: Set<String> = ["access_token", "id_token", "refresh_token"]
    
    /// Redacts sensitive fields from a JSON string in the response body.
    ///
    /// This is an additional safety check - even when debugger is connected, we don't log
    /// access tokens, id tokens, and refresh tokens on Xcode console and live Console.app.
    ///
    /// Note: These logs are only for debugging purposes and never persisted in production.
    ///
    /// - Parameter data: The response data to redact.
    /// - Returns: A JSON string with sensitive fields replaced by `<REDACTED>` if valid JSON, otherwise returns the data decoded as a UTF-8 string, or `nil` if decoding fails.
    static func redact(_ data: Data) -> String? {
        do {
            // Attempt to parse as JSON
            var jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            // Redact any sensitive keys present
            sensitiveKeys.forEach { key in
                if jsonObject?[key] != nil {
                    jsonObject?[key] = "<REDACTED>"
                }
            }
            
            // Convert back to pretty-printed JSON string
            let redactedData = try JSONSerialization.data(withJSONObject: jsonObject ?? [:], options: [.prettyPrinted])
            return String(data: redactedData, encoding: .utf8) ?? "<REDACTED>"
            
        } catch {
            // If not JSON, return try converting data to  string
            return String(data: data, encoding: .utf8)
        }
    }
}
