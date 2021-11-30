import Foundation

/**
 `Result` wrapper for Authentication API operations
 */
public typealias AuthenticationResult<T> = Result<T, AuthenticationError>

/**
 `Result` wrapper for Management API operations
 */
public typealias ManagementResult<T> = Result<T, ManagementError>

#if WEB_AUTH_PLATFORM
/**
 `Result` wrapper for Web Auth operations
 */
public typealias WebAuthResult<T> = Result<T, WebAuthError>
#endif

/**
 `Result` wrapper for Credentials Manager operations
 */
public typealias CredentialsManagerResult<T> = Result<T, CredentialsManagerError>

 /**
  Default scope value used across Auth0.swift
 */
public let defaultScope = "openid profile email"

/**
 Auth0 Authentication API to authenticate your user using a Database, Social, Enterprise or Passwordless connections

 ```
 Auth0.authentication(clientId: clientId, domain: "samples.auth0.com")
 ```

 - parameter clientId: clientId of your Auth0 application
 - parameter domain:   domain of your Auth0 account. e.g.: 'samples.auth0.com'
 - parameter session:  instance of URLSession used for networking. By default it will use the shared URLSession

 - returns: Auth0 Authentication API
 */
public func authentication(clientId: String, domain: String, session: URLSession = .shared) -> Authentication {
    return Auth0Authentication(clientId: clientId, url: .httpsURL(from: domain), session: session)
}

/**
 Auth0 Authentication API to authenticate your user using a Database, Social, Enterprise or Passwordless connections.

 ```
 Auth0.authentication()
 ```

 Auth0 clientId & domain are loaded from the file `Auth0.plist` in your main bundle with the following content:
 
 ```
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
	<key>ClientId</key>
	<string>{YOUR_CLIENT_ID}</string>
	<key>Domain</key>
	<string>{YOUR_DOMAIN}</string>
 </dict>
 </plist>
 ```

 - parameter session:  instance of URLSession used for networking. By default it will use the shared URLSession
 - parameter bundle:    bundle used to locate the `Auth0.plist` file. By default is the main bundle

 - returns: Auth0 Authentication API
 - important: Calling this method without a valid `Auth0.plist` will crash your application
 */
public func authentication(session: URLSession = .shared, bundle: Bundle = .main) -> Authentication {
    let values = plistValues(bundle: bundle)!
    return authentication(clientId: values.clientId, domain: values.domain, session: session)
}

/**
 Auth0 Management Users API v2 that allows CRUD operations with the users endpoint.

 ```
 Auth0.users(token: token)
 ```

 Currently you can only perform the following operations:

 * Get an user by id
 * Update an user, e.g. by adding `user_metadata`
 * Link users
 * Unlink users

 Auth0 domain is loaded from the file `Auth0.plist` in your main bundle with the following content:

 ```
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
	<key>ClientId</key>
	<string>{YOUR_CLIENT_ID}</string>
	<key>Domain</key>
	<string>{YOUR_DOMAIN}</string>
 </dict>
 </plist>
 ```

 - parameter token:     token of Management API v2 with the correct allowed scopes to perform the desired action
 - parameter session:   instance of URLSession used for networking. By default it will use the shared URLSession
 - parameter bundle:    bundle used to locate the `Auth0.plist` file. By default is the main bundle

 - returns: Auth0 Management API v2
 - important: Calling this method without a valid `Auth0.plist` will crash your application
 */
public func users(token: String, session: URLSession = .shared, bundle: Bundle = .main) -> Users {
    let values = plistValues(bundle: bundle)!
    return users(token: token, domain: values.domain, session: session)
}

/**
 Auth0 Management Users API v2 that allows CRUD operations with the users endpoint.
 
 ```
 Auth0.users(token: token, domain: "samples.auth0.com")
 ```

 Currently you can only perform the following operations:
 
 * Get an user by id
 * Update an user, e.g. by adding `user_metadata`
 * Link users
 * Unlink users

 - parameter token:     token of Management API v2 with the correct allowed scopes to perform the desired action
 - parameter domain:    domain of your Auth0 account. e.g.: 'samples.auth0.com'
 - parameter session:   instance of URLSession used for networking. By default it will use the shared URLSession

 - returns: Auth0 Management API v2
 */
public func users(token: String, domain: String, session: URLSession = .shared) -> Users {
    return Management(token: token, url: .httpsURL(from: domain), session: session)
}

func plistValues(bundle: Bundle) -> (clientId: String, domain: String)? {
    guard
        let path = bundle.path(forResource: "Auth0", ofType: "plist"),
        let values = NSDictionary(contentsOfFile: path) as? [String: Any]
        else {
            print("Missing Auth0.plist file with 'ClientId' and 'Domain' entries in main bundle!")
            return nil
        }

    guard
        let clientId = values["ClientId"] as? String,
        let domain = values["Domain"] as? String
        else {
            print("Auth0.plist file at \(path) is missing 'ClientId' and/or 'Domain' entries!")
            print("File currently has the following entries: \(values)")
            return nil
        }
    return (clientId: clientId, domain: domain)
}
