import Foundation

/// Utility for redacting sensitive data from JSON request/response bodies.
struct SensitiveDataRedactor {

    /// List of sensitive keys that should be redacted at any nesting depth.
    private static let sensitiveKeys: Set<String> = [
        "access_token", "id_token", "refresh_token", "auth_session",
        "authorization_code", "otp", "code", "new_code"
    ]

    /// Redacts sensitive fields from a JSON body (request or response).
    ///
    /// This is an additional safety check - even when debugger is connected, we don't log
    /// tokens, codes, or other sensitive values on Xcode console and live Console.app.
    ///
    /// Note: These logs are only for debugging purposes and never persisted in production.
    ///
    /// - Parameter data: The body data to redact.
    /// - Returns: A JSON string with sensitive fields replaced by `<REDACTED>` if valid JSON,
    ///   otherwise the data decoded as a UTF-8 string, or `nil` if decoding fails.
    static func redact(_ data: Data) -> String? {
        do {
            let parsed = try JSONSerialization.jsonObject(with: data, options: [])
            let redacted: Any
            if let dict = parsed as? [String: Any] {
                redacted = redactDictionary(dict)
            } else {
                redacted = parsed
            }
            let redactedData = try JSONSerialization.data(withJSONObject: redacted, options: [.prettyPrinted])
            return String(data: redactedData, encoding: .utf8) ?? "<REDACTED>"
        } catch {
            return String(data: data, encoding: .utf8)
        }
    }

    private static func redactDictionary(_ dict: [String: Any]) -> [String: Any] {
        var result = dict
        for (key, value) in result {
            if sensitiveKeys.contains(key) {
                result[key] = "<REDACTED>"
            } else if let nested = value as? [String: Any] {
                result[key] = redactDictionary(nested)
            } else if let array = value as? [Any] {
                result[key] = redactArray(array)
            }
        }
        return result
    }

    private static func redactArray(_ array: [Any]) -> [Any] {
        return array.map { element -> Any in
            if let dict = element as? [String: Any] { return redactDictionary(dict) }
            if let arr = element as? [Any] { return redactArray(arr) }
            return element
        }
    }
}
