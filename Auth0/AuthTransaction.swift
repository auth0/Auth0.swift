// AuthTransaction.swift
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

import UIKit
import SafariServices

/**
 Represents an on going AuthTransaction with Auth0.

 It will handle result from the redirect URL configured when the AuthTransaction flow was started,
 so we need to handle when the configured URL is opened in your Application's `AppDelegate`

 ```
 func application(app: UIApplication, openURL url: NSURL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
    let transaction = //retrieve current AuthTransaction
    return transaction.resume(url, options: options)
 }
 ```
 */
public protocol AuthTransaction {
    var state: String? { get }
    func resume(_ url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool
    func cancel()
}
