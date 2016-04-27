// Response.swift
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

struct Response {
    let data: NSData?
    let response: NSURLResponse?
    let error: NSError?

    var result: Result {
        guard error == nil else { return .Failure(.RequestFailed(error)) }
        guard let response = self.response as? NSHTTPURLResponse else { return .Failure(.RequestFailed(nil)) }
        guard (200...300).contains(response.statusCode) else { return .Failure(.ServerError(response.statusCode, data)) }
        guard let data = self.data else { return response.statusCode == 204 ? .Success(nil) : .Failure(.NoResponse) }
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
            return .Success(json)
        } catch {
            // This piece of code is dedicated to our friends the backend devs :)
            if response.URL?.lastPathComponent == "change_password" {
                return .Success(nil)
            } else {
                return .Failure(.InvalidJSON(data))
            }
        }
    }

    enum Result {
        case Success(AnyObject?)
        case Failure(Error)
    }

    enum Error: ErrorType {
        case RequestFailed(NSError?)
        case ServerError(Int, NSData?)
        case NoResponse
        case InvalidJSON(NSData)
    }
}
