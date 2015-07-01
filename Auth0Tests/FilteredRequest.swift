// FilteredRequest.swift
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
import OHHTTPStubs

func all() -> FilteredRequest {
    return FilteredRequest(filter: { _ in return true })
}

func none() -> FilteredRequest {
    return FilteredRequest(filter: { _ in return false })
}

func filter(filter: (NSURLRequest -> Bool)) -> FilteredRequest {
    return FilteredRequest(filter: filter)
}

func hasJSON(expected: [String: AnyObject], request: NSURLRequest) -> Bool {
    var filter: Bool = false
    if let stream = request.HTTPBodyStream {
        stream.open()
        if let json = NSJSONSerialization.JSONObjectWithStream(stream, options: .allZeros, error: nil) as? [String: AnyObject] {
            filter = true
            for key in expected.keys {
                filter = contains(json.keys, key)
                if !filter {
                    break
                }
            }
        }
        stream.close()
    }
    return filter
}

struct FilteredRequest {
    let requestFilter: (NSURLRequest -> Bool)

    init(filter: (NSURLRequest -> Bool)) {
        self.requestFilter = filter
    }

    func stubWithName(name: String, stub: () -> OHHTTPStubsResponse) {
        OHHTTPStubs.stubRequestsPassingTest(self.requestFilter, withStubResponse: { _ in return stub() }).name = name
    }

    func stubWithName(name: String, error: NSError) {
        stubWithName(name) { return OHHTTPStubsResponse(error: error) }
    }

    func stubWithName(name: String, json: [String: AnyObject], statusCode:Int = 200) {
        stubWithName(name) { return OHHTTPStubsResponse(JSONObject: json, statusCode: Int32(statusCode), headers: ["Content-Type": "application/json"]) }
    }
}