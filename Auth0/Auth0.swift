// Auth0.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/**
 Auth0 Authentication API to authenticate your user using a Database, Social, Enterprise or Passwordless connections

 ```
 Auth0.authentication(clientId: clientId, domain: "samples.auth0.com")
 ```

 - parameter clientId: clientId of your Auth0 client/application
 - parameter domain:   domain of your Auth0 account. e.g.: 'samples.auth0.com'
 - parameter session:  instance of NSURLSession used for networking. By default it will use the shared NSURLSession

 - returns: Auth0 Authentication API
 */
public func authentication(clientId clientId: String, domain: String, session: NSURLSession = .sharedSession()) -> Authentication {
    return Authentication(clientId: clientId, url: .a0_url(domain), session: session)
}

/**
 Auth0 Management API v2 to perform CRUD operation against your Users, Clients, Connections, etc.
 
 ```
 Auth0.management(token: token, domain: "samples.auth0.com")
 ```

 - parameter token:     token of Management API v2 with the correct allowed scopes to perform the desired action
 - parameter domain:    domain of your Auth0 account. e.g.: 'samples.auth0.com'
 - parameter session:   instance of NSURLSession used for networking. By default it will use the shared NSURLSession

 - returns: Auth0 Management API v2
 - important: Auth0.swift has yet to implement all endpoints. Now you can only perform some CRUD operations against Users
 */
public func management(token token: String, domain: String, session: NSURLSession = .sharedSession()) -> Management {
    return Management(token: token, url: .a0_url(domain), session: session)
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
 - parameter session:   instance of NSURLSession used for networking. By default it will use the shared NSURLSession

 - returns: Auth0 Management API v2
 */
public func users(token token: String, domain: String, session: NSURLSession = .sharedSession()) -> Users {
    return management(token: token, domain: domain, session: session).users()
}

public extension NSURL {
    /**
     Returns an Auth0 domain URL given a domain

     - parameter domain: name of your Auth0 account

     - returns: URL of your Auth0 account
     */
    @objc(a0_URLWithDomain:)
    public static func a0_url(domain: String) -> NSURL {
        let urlString: String
        if !domain.hasPrefix("https") {
            urlString = "https://\(domain)"
        } else {
            urlString = domain
        }
        return NSURL(string: urlString)!
    }
}

// MARK: - Xcode hacks

//Xcode issue that won't add these to Auth0-Swift.h file. 21/05/2016

extension NSArray { }

extension NSDictionary { }