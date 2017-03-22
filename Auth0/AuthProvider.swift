// AuthProvider.swift
//
// Copyright (c) 2017 Auth0 (http://auth0.com)
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

/**
 The AuthProvider protocol is adopted by an objects that are to be used as Native Authentication
 handlers. An object implementing this protocol is intended to superceed the default authentication
 model for a given connection name with its own native implementation.

 ```
 struct Facebook: AuthProvider {

     func login(withConnection connection: String, scope: String, parameters: [String : Any]) -> NativeAuthTransaction {
         let transaction = FacebookNativeAuthTransaction()
         ...
         return transaction
     }
 
     static func isAvailable() -> Bool {
         return true
     }

 ```
 */
public protocol AuthProvider {
    func login(withConnection connection: String, scope: String, parameters: [String: Any]) -> NativeAuthTransaction

    /**
     Determine if the Auth method used by the Provider is available on the device.
     e.g. If using a Twitter Auth provider it should check the presence of a Twitter account on the device.

     If a Auth is performed on a provider that returns `false` the transaction will fail with an error.

     - returns: Bool if the AuthProvider is available on the device
     */
    static func isAvailable() -> Bool
}
