import Foundation

let serialQueue = DispatchQueue(label: "com.auth0.sdk.serial")

func date(from string: String) -> Date? {
    guard let interval = Double(string) else {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: string)
    }
    return Date(timeIntervalSince1970: interval)
}

func includeRequiredScope(in scope: String?) -> String? {
    guard let scope = scope, !scope.split(separator: " ").map(String.init).contains("openid") else { return scope }
    return "openid \(scope)"
}

func extractRedirectURL(from url: URL) -> URL? {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
        return nil
    }

    if let redirectURIString = components.queryItems?.first(where: { $0.name == "redirect_uri" || $0.name == "returnTo" })?.value,
       let redirectURI = URL(string: redirectURIString) {
        return redirectURI
    }

    return nil
}

/// Wrapper for non-Sendable types that need to be used in Sendable contexts.
/// Use only when thread-safety is guaranteed through synchronization (locks, serial queues, etc.).
struct SendableBox<T>: @unchecked Sendable {
    let value: T
}

/// Serializes a [String: Any] parameter dictionary to Data at the API boundary.
/// Data is natively Sendable, so the result is safe to capture in concurrent closures.
/// Returns empty Data for empty input; invalid JSON objects are silently dropped.
func normalize(_ params: [String: Any]) -> Data {
    guard !params.isEmpty,
          JSONSerialization.isValidJSONObject(params),
          let data = try? JSONSerialization.data(withJSONObject: params) else { return Data() }
    return data
}

extension Data {
    /// Deserializes back to [String: Any] at the point of use.
    var asParameters: [String: Any] {
        guard !isEmpty,
              let obj = try? JSONSerialization.jsonObject(with: self),
              let dict = obj as? [String: Any] else { return [:] }
        return dict
    }
}
