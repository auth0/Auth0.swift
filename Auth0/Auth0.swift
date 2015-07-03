// Auth0.swift
//
// Copyright (c) 2014 Auth0 (http://auth0.com)
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
import Alamofire

/**
*  Main object of Auth0 swift toolkit that provides access to the different Auth0 API endpoints
*/
public struct Auth0 {
    /// Shared Auth0 instance with configuration info obtained from `Info.plist`
    public static let sharedInstance = Auth0()

    /// Auth0 API v2 helper
    public let api: API

    /**
    Creates a new Auth0 object. 
    It retrieves your Auth0 account domain from `Info.plist` file entry with key `Auth0Domain`

    :returns: a new instance
    */
    public init() {
        let info = NSBundle.mainBundle().infoDictionary
        let domain:String = info?["Auth0Domain"] as! String
        self.init(domain: domain)
    }

    /**
    Creates a new Auth0 object with an account Auth0 domain.
    The domain can be a full web url, e.g.: `https://samples.auth0.com`, or just the domain name, e.g. `samples.auth0.com`

    :param: domain of your Auth0 account

    :returns: a new instance
    */
    public init(domain: String) {
        self.api = API(domain: domain)
    }

    /**
    Initialize API v2 /users endpoint with a valid JWT

    :param: token a valid jwt of API v2 or an `id_token` of a user

    :returns: users api helper
    */
    public func users(token: String) -> Users {
        return api.users(token)
    }

    /**
    Initialize API v2 /users endpoint with a valid JWT from shared Auth0 configuration

    :param: token a valid jwt of API v2 or an `id_token` of a user

    :returns: users api helper
    */
    public static func users(token: String) -> Users {
        return Auth0.sharedInstance.api.users(token)
    }

}