#if WEB_AUTH_PLATFORM
import Foundation

/**
Represents an ongoing Auth transaction with an Identity Provider (Auth0 or a third party).

The Auth will be done outside of application control, Safari or third party application.
The only way to communicate the results back is using a url with a registered custom scheme in your application so the OS can open it on success/failure.

- Important: Only one ``AuthTransaction`` can be active at a given time for Auth0.swift, if you start a new one before finishing the current one it will be cancelled.
*/
protocol AuthTransaction {

    /// Value of the OAuth 2.0 state parameter. It must be a cryptographically secure random string used to protect the app with request forgery.
    var state: String? { get }

    /**
     Resumes the transaction when the third party application notifies the application using a url with a custom scheme.
     
     - Parameter url: The url sent by the third party application that contains the result of the Auth.
     - Returns: If the url was expected and properly formatted. Otherwise, it will return `false`.
    */
    func resume(_ url: URL) -> Bool

    /**
     Terminates the operation and reports back that it was cancelled.
    */
    func cancel()

}
#endif
