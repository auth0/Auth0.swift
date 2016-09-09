// Logger.swift
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

public protocol Logger {
    func trace(request: NSURLRequest, session: NSURLSession)
    func trace(response: NSURLResponse, data: NSData?)
    func trace(url: NSURL, source: String?)
}

protocol LoggerOutput {
    func message(message: String)
    func newLine()
}

struct DefaultOutput: LoggerOutput {
    func message(message: String) { print(message) }
    func newLine() { print() }
}

struct DefaultLogger: Logger {

    let output: LoggerOutput

    init(output: LoggerOutput = DefaultOutput()) {
        self.output = output
    }

    func trace(request: NSURLRequest, session: NSURLSession) {
        guard
            let method = request.HTTPMethod,
            let url = request.URL
            else { return }
        output.message("\(method) \(url.absoluteString) HTTP/1.1")
        session.configuration.HTTPAdditionalHeaders?.forEach { key, value in output.message("\(key): \(value)") }
        request.allHTTPHeaderFields?.forEach { key, value in output.message("\(key): \(value)") }
        if let data = request.HTTPBody, let string = String(data: data, encoding: NSUTF8StringEncoding) {
            output.newLine()
            output.message(string)
        }
        output.newLine()
    }

    func trace(response: NSURLResponse, data: NSData?) {
        if let http = response as? NSHTTPURLResponse {
            output.message("HTTP/1.1 \(http.statusCode)")
            http.allHeaderFields.forEach { key, value in output.message("\(key): \(value)") }
            if let data = data, let string = String(data: data, encoding: NSUTF8StringEncoding) {
                output.newLine()
                output.message(string)
            }
            output.newLine()
        }
    }

    func trace(url: NSURL, source: String?) {
        output.message("\(source ?? "URL"): \(url.absoluteString)")
    }
}