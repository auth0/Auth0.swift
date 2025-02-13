import Foundation

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
