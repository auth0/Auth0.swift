#if WEB_AUTH_PLATFORM
/// The external user agent used to perform a web-based operation.
///
/// ## See Also
///
/// - [Example](https://github.com/auth0/Auth0.swift/blob/master/Auth0/SafariProvider.swift)
public protocol WebAuthUserAgent {

    /// Starts the external user agent.
    func start()

    /// Tears down the external user agent after the web-based operation completed, if needed.
    /// Auth0.swift will call this method after the callback URL was received and processed, or after the user
    /// cancelled the operation, or after any other error occurred.
    ///
    /// - Parameter result: The outcome of the web-based operation, containing either an empty success case or an
    /// error.
    func finish(with result: WebAuthResult<Void>)

}
#endif
