import Foundation

extension URL {
    /**
     Returns an Auth0 domain URL given a domain

     - parameter domain: name of your Auth0 account

     - returns: URL of your Auth0 account
     */
    static func httpsURL(from domain: String) -> URL {
        let prefix = !domain.hasPrefix("https") ? "https://" : ""
        let suffix = !domain.hasSuffix("/") ? "/" : ""
        let urlString = "\(prefix)\(domain)\(suffix)"
        return URL(string: urlString)!
    }
}
