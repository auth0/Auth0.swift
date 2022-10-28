import Foundation

/**
 `Result` wrapper for Authentication API operations.
 */
public typealias AuthenticationResult<T> = Result<T, AuthenticationError>

/**
 `Result` wrapper for Management API operations.
 */
public typealias ManagementResult<T> = Result<T, ManagementError>

#if WEB_AUTH_PLATFORM
/**
 `Result` wrapper for Web Auth operations.
 */
public typealias WebAuthResult<T> = Result<T, WebAuthError>
#endif

/**
 `Result` wrapper for Credentials Manager operations.
 */
public typealias CredentialsManagerResult<T> = Result<T, CredentialsManagerError>

/**
 Default scope value used across Auth0.swift. Equals to `openid profile email`.
 */
public let defaultScope = "openid profile email"

/**
 Auth0 [Authentication API](https://auth0.com/docs/api/authentication) client to authenticate your user using Database, Social, Enterprise or Passwordless connections.

 ## Usage

 ```swift
 Auth0.authentication(clientId: "client-id", domain: "samples.us.auth0.com")
 ```

 - Parameters:
   - clientId: Client ID of your Auth0 application.
   - domain:   Domain of your Auth0 account, for example `samples.us.auth0.com`.
   - session:  `URLSession` instance used for networking. Defaults to `URLSession.shared`.
 - Returns: Auth0 Authentication API client.
 */
public func authentication(clientId: String, domain: String, session: URLSession = .shared) -> Authentication {
    return Auth0Authentication(clientId: clientId, url: .httpsURL(from: domain), session: session)
}

/**
 Auth0 [Authentication API](https://auth0.com/docs/api/authentication) client to authenticate your user using Database,
 Social, Enterprise or Passwordless connections.

 ## Usage

 ```swift
 Auth0.authentication()
 ```

 The Auth0 Client ID & Domain are loaded from the `Auth0.plist` file in your main bundle. It should have the following
 content:
 
 ```xml
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
	  <key>ClientId</key>
	  <string>YOUR_AUTH0_CLIENT_ID</string>
	  <key>Domain</key>
	  <string>YOUR_AUTH0_DOMAIN</string>
 </dict>
 </plist>
 ```

 - Parameters:
   - session: `URLSession` instance used for networking. Defaults to `URLSession.shared`.
   - bundle:  Bundle used to locate the `Auth0.plist` file. Defaults to `Bundle.main`.
 - Returns: Auth0 Authentication API client.
 - Warning: Calling this method without a valid `Auth0.plist` file will crash your application.
 */
public func authentication(session: URLSession = .shared, bundle: Bundle = .main) -> Authentication {
    let values = plistValues(bundle: bundle)!
    return authentication(clientId: values.clientId, domain: values.domain, session: session)
}

/**
 Auth0 [Management API v2](https://auth0.com/docs/api/management/v2) client to perform operations with the Users
 endpoints.

 ## Usage

 ```swift
 Auth0.users(token: credentials.accessToken)
 ```

 Currently you can only perform the following operations:

 * Get a user by ID
 * Update an user, for example by adding `user_metadata`
 * Link users
 * Unlink users

 The Auth0 Domain is loaded from the `Auth0.plist` file in your main bundle. It should have the following content:

 ```xml
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
	  <key>ClientId</key>
	  <string>YOUR_AUTH0_CLIENT_ID</string>
	  <key>Domain</key>
	  <string>YOUR_AUTH0_DOMAIN</string>
 </dict>
 </plist>
 ```

 - Parameters:
   - token:   Management API token with the correct allowed scopes to perform the desired action.
   - session: `URLSession` instance used for networking. Defaults to `URLSession.shared`.
   - bundle:  Bundle used to locate the `Auth0.plist` file. Defaults to `Bundle.main`.
 - Returns: Auth0 Management API v2 client.
 - Warning: Calling this method without a valid `Auth0.plist` file will crash your application.
 */
public func users(token: String, session: URLSession = .shared, bundle: Bundle = .main) -> Users {
    let values = plistValues(bundle: bundle)!
    return users(token: token, domain: values.domain, session: session)
}

/**
 Auth0 [Management API v2](https://auth0.com/docs/api/management/v2) client to perform operations with the Users
 endpoints.

 ## Usage

 ```swift
 Auth0.users(token: credentials.accessToken, domain: "samples.us.auth0.com")
 ```

 Currently you can only perform the following operations:
 
 * Get a user by ID
 * Update an user, for example by adding `user_metadata`
 * Link users
 * Unlink users

 - Parameters:
   - token:   Management API token with the correct allowed scopes to perform the desired action.
   - domain:  Domain of your Auth0 account, for example `samples.us.auth0.com`.
   - session: `URLSession` instance used for networking. Defaults to `URLSession.shared`.
 - Returns: Auth0 Management API v2 client.
 */
public func users(token: String, domain: String, session: URLSession = .shared) -> Users {
    return Management(token: token, url: .httpsURL(from: domain), session: session)
}

#if WEB_AUTH_PLATFORM
/**
 Auth0 client for performing web-based authentication with [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login).

 ## Usage

 ```swift
 Auth0.webAuth()
 ```

 The Auth0 Domain is loaded from the `Auth0.plist` file in your main bundle. It should have the following content:

 ```xml
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
    <key>ClientId</key>
    <string>YOUR_AUTH0_CLIENT_ID</string>
    <key>Domain</key>
    <string>YOUR_AUTH0_DOMAIN</string>
 </dict>
 </plist>
 ```

 - Parameters:
   - session: `URLSession` instance used for networking. Defaults to `URLSession.shared`.
   - bundle:  Bundle used to locate the `Auth0.plist` file. Defaults to `Bundle.main`.
 - Returns: Auth0 Web Auth client.
 - Warning: Calling this method without a valid `Auth0.plist` file will crash your application.
 */
public func webAuth(session: URLSession = .shared, bundle: Bundle = Bundle.main) -> WebAuth {
    let values = plistValues(bundle: bundle)!
    return webAuth(clientId: values.clientId, domain: values.domain, session: session)
}

/**
 Auth0 client for performing web-based authentication with [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login).

 ## Usage

 ```swift
 Auth0.webAuth(clientId: "client-id", domain: "samples.us.auth0.com")
 ```

 - Parameters:
   - clientId: Client ID of your Auth0 application.
   - domain:   Domain of your Auth0 account, for example `samples.us.auth0.com`.
   - session:  `URLSession` instance used for networking. Defaults to `URLSession.shared`.
 - Returns: Auth0 Web Auth client.
 */
public func webAuth(clientId: String, domain: String, session: URLSession = .shared) -> WebAuth {
    return Auth0WebAuth(clientId: clientId, url: .httpsURL(from: domain), session: session)
}
#endif

func plistValues(bundle: Bundle) -> (clientId: String, domain: String)? {
    guard let path = bundle.path(forResource: "Auth0", ofType: "plist"),
          let values = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("Missing Auth0.plist file with 'ClientId' and 'Domain' entries in main bundle!")
            return nil
        }

    guard let clientId = values["ClientId"] as? String, let domain = values["Domain"] as? String else {
            print("Auth0.plist file at \(path) is missing 'ClientId' and/or 'Domain' entries!")
            print("File currently has the following entries: \(values)")
            return nil
        }
    return (clientId: clientId, domain: domain)
}
