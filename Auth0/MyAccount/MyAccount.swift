import Foundation

public func myAccount(token: String, domain: String, session: URLSession = .shared) -> MyAccount {
    return Auth0MyAccount(token: token, url: .httpsURL(from: domain), session: session)
}

public func myAccount(token: String, session: URLSession = .shared, bundle: Bundle = .main) -> MyAccount {
    let values = plistValues(bundle: bundle)!
    return myAccount(token: token, domain: values.domain, session: session)
}

/// Client for the My Account API.
public protocol MyAccountClient: Trackable, Loggable {

    /// URL of the My Account API.
    var url: URL { get }

    /// An access token for My Account API.
    var token: String { get }

}

extension MyAccountClient {

    var defaultHeaders: [String: String] {
        return ["Authorization": "Bearer \(token)"]
    }

}

public protocol MyAccount: MyAccountClient {

    var authenticationMethods: MyAccountAuthenticationMethods { get }

}

extension MyAccount {

    static var apiVersion: String {
        return "v1"
    }

}

extension CodingUserInfoKey {

    static var headersKey: CodingUserInfoKey {
        // Force-unrapping it because it's never nil. See https://github.com/swiftlang/swift/issues/49302
        return CodingUserInfoKey(rawValue: "headers")!
    }

}
