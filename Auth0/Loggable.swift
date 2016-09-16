// Loggable.swift
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

public protocol Loggable {

    var logger: Logger? { get set }

}

public extension Loggable {

    /**
     Turn on Auth0.swift debug logging of HTTP requests and OAuth2 flow (iOS only) with a custom logger.

     - parameter logger: logger used to print log statements
     - note: By default all logging is **disabled**
     - important: Logging should be turned on/off **before** making request to Auth0 for the flag to take effect.
     */
    mutating func using(logger: Logger) -> Self {
        self.logger = logger
        return self
    }

    /**
     Turn on/off Auth0.swift debug logging of HTTP requests and OAuth2 flow (iOS only).

     - parameter enabled: optional flag to turn on/off logging
     - note: By default all logging is **disabled**
     - important: Logging should be turned on/off **before** making request to Auth0 for the flag to take effect.
     */
    mutating func logging(enabled: Bool) -> Self {
        if enabled {
            self.logger = DefaultLogger()
        } else {
            self.logger = nil
        }
        return self
    }
}
