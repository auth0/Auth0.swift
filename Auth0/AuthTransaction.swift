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

#if WEB_AUTH_PLATFORM
/**
Represents an ongoing Auth transaction with an Identity Provider (Auth0 or a third party).

The Auth will be done outside of application control, Safari or third party application.
The only way to communicate the results back is using a url with a registered custom scheme in your application so the OS can open it on success/failure.
When that happens the OS will call a method in your `AppDelegate` and that is where you need to handle the result.

- important: Only one AuthTransaction can be active at a given time for Auth0.swift, if you start a new one before finishing the current one it will be cancelled.
*/
public protocol AuthTransaction: AuthResumable, AuthCancelable {

    /// value of the OAuth 2.0 state parameter. It must be a cryptographically secure randon string used to protect the app with request forgery.
    var state: String? { get }

}
#endif
