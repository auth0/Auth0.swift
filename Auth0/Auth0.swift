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

public func authentication(clientId clientId: String, domain: String, session: NSURLSession = .sharedSession()) -> Authentication {
    return Authentication(clientId: clientId, url: .a0_url(domain), session: session)
}

public func management(token: String, domain: String, session: NSURLSession = .sharedSession()) -> Management {
    return Management(token: token, url: .a0_url(domain), session: session)
}

public func users(token: String, domain: String, session: NSURLSession = .sharedSession()) -> Users {
    return management(token, domain: domain, session: session).users()
}

public extension NSURL {
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