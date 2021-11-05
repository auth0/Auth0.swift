import Foundation

public extension URL {
    /**
     Returns an Auth0 domain URL given a domain

     - parameter domain: name of your Auth0 account

     - returns: URL of your Auth0 account
     */
    static func a0_url(_ domain: String) -> URL {
        let urlString: String
        if !domain.hasPrefix("https") {
            urlString = "https://\(domain)"
        } else {
            urlString = domain
        }
        return URL(string: urlString)!
    }
}
