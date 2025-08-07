/// A type that can use DPoP for securing requests.
///
/// ## Availability
///
/// This feature is currently available in
/// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
/// Please reach out to Auth0 support to get it enabled for your tenant.
public protocol SenderConstraining {

    /// The ``DPoP`` instance used for securing requests.
    ///
    /// - Important: This property must be set before making requests to ensure DPoP functionality.
    var dpop: DPoP? { get set }

}

public extension SenderConstraining {

    /// Enables DPoP for securing requests.
    ///
    /// This method initializes a ``DPoP`` instance with the specified keychain identifier and assigns it to the
    /// ``dpop`` property.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// - Parameter keychainIdentifier: The identifier used to store the key pair on the Keychain. Defaults to the bundle identifier.
    /// - Returns: A modified instance with DPoP enabled.
    ///
    /// ## See Also
    ///
    /// - [RFC 9449](https://www.rfc-editor.org/rfc/rfc9449.html)
    func useDPoP(keychainIdentifier: String = DPoP.defaultKeychainIdentifier) -> Self {
        var instance = self
        instance.dpop = DPoP(keychainIdentifier: keychainIdentifier)
        return instance
    }

}

extension SenderConstraining {

    func baseHeaders(accessToken: String, tokenType: String) -> [String: String] {
        return ["Authorization": "\(tokenType) \(accessToken)"]
    }

}
