// Request.swift
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

#if DEBUG
    let parameterPropertyKey = "com.auth0.parameter"
#endif

/**
 Auth0 API request

 ```
 let request: Request<Credentials, Authentication.Error> = //
 request.start { result in
    //handle result
 }
 ```
 */
public struct Request<T, E: Auth0Error>: Requestable {
    public typealias Callback = (Result<T>) -> Void

    let session: URLSession
    let url: URL
    let method: String
    let handle: (Response<E>, Callback) -> Void
    let payload: [String: Any]
    let headers: [String: String]
    let logger: Logger?
    let telemetry: Telemetry

    init(session: URLSession, url: URL, method: String, handle: @escaping (Response<E>, Callback) -> Void, payload: [String: Any] = [:], headers: [String: String] = [:], logger: Logger?, telemetry: Telemetry) {
        self.session = session
        self.url = url
        self.method = method
        self.handle = handle
        self.payload = payload
        self.headers = headers
        self.logger = logger
        self.telemetry = telemetry
    }

    var request: URLRequest {
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = method
        if !payload.isEmpty, let httpBody = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            request.httpBody = httpBody
            #if DEBUG
            URLProtocol.setProperty(payload, forKey: parameterPropertyKey, in: request)
            #endif
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { name, value in request.setValue(value, forHTTPHeaderField: name) }
        telemetry.addTelemetryHeader(request: request)
        return request as URLRequest
    }

    /**
     Starts the request to the server

     - parameter callback: called when the request finishes and yield it's result
     */
    public func start(_ callback: @escaping Callback) {
        let handler = self.handle
        let request = self.request
        let logger = self.logger

        logger?.trace(request: request, session: self.session)

        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if error == nil, let response = response {
                logger?.trace(response: response, data: data)
            }
            handler(Response(data: data, response: response, error: error), callback)
        })
        task.resume()
    }

}

/**
 *  A concatenated request, if the first one fails it will yield it's error, otherwise it will return the last request outcome
 */
public struct ConcatRequest<F, S, E: Auth0Error>: Requestable {
    let first: Request<F, E>
    let second: Request<S, E>

    public typealias ResultType = S

    /**
     Starts the request to the server

     - parameter callback: called when the request finishes and yield it's result
     */
    public func start(_ callback: @escaping (Result<ResultType>) -> Void) {
        let second = self.second
        first.start { result in
            switch result {
            case .failure(let cause):
                callback(.failure(error: cause))
            case .success:
                second.start(callback)
            }
        }
    }
}
