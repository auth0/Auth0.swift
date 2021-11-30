import Foundation

extension URL {

    static func httpsURL(from domain: String) -> URL {
        let prefix = !domain.hasPrefix("https") ? "https://" : ""
        let suffix = !domain.hasSuffix("/") ? "/" : ""
        let urlString = "\(prefix)\(domain)\(suffix)"
        return URL(string: urlString)!
    }

}
