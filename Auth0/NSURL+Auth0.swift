import Foundation

extension URL {

    static func httpsURL(from domain: String) -> URL {
        let prefix = !domain.hasPrefix("https") ? "https://" : ""
        let suffix = !domain.hasSuffix("/") ? "/" : ""
        let urlString = "\(prefix)\(domain)\(suffix)"
        return URL(string: urlString)!
    }

    // Once the required minimum platform versions have been adopted,
    // replace usages with `appending(path:)` and then remove this helper.
    func appending(_ path: String) -> Self {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            return self.appending(path: path)
        }

        return self.appendingPathComponent(path)
    }

}
