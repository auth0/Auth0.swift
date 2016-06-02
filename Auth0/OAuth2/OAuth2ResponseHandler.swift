// OAuth2ResponseHandler.swift
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

protocol OAuth2ResponseHandler {
    func credentials(values: [String: String], callback: Result<Credentials, Authentication.Error> -> ())
}

struct ImplicitGrant: OAuth2ResponseHandler {

    func credentials(values: [String : String], callback: Result<Credentials, Authentication.Error> -> ()) {
        guard let credentials = Credentials(json: values) else {
            let data = try? NSJSONSerialization.dataWithJSONObject(values, options: [])
            callback(.Failure(error: .InvalidResponse(response: data)))
            return
        }
        callback(.Success(result: credentials))
    }

}