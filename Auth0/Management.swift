// Management.swift
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

public typealias ManagementObject = [String: Any]

/**
 *  Auth0 Management API
 */
struct Management: Trackable, Loggable {
    let token: String
    let url: URL
    var telemetry: Telemetry
    var logger: Logger?

    let session: URLSession

    init(token: String, url: URL, session: URLSession = .shared, telemetry: Telemetry = Telemetry()) {
        self.token = token
        self.url = url
        self.session = session
        self.telemetry = telemetry
    }

    func managementObject(response: Response<ManagementError>, callback: Request<ManagementObject, ManagementError>.Callback) {
        do {
            if let dictionary = try response.result() as? ManagementObject {
                callback(.success(result: dictionary))
            } else {
                callback(.failure(error: ManagementError(string: string(response.data))))
            }
        } catch let error {
            callback(.failure(error: error))
        }
    }

    func managementObjects(response: Response<ManagementError>, callback: Request<[ManagementObject], ManagementError>.Callback) {
        do {
            if let list = try response.result() as? [ManagementObject] {
                callback(.success(result: list))
            } else {
                callback(.failure(error: ManagementError(string: string(response.data))))
            }
        } catch let error {
            callback(.failure(error: error))
        }
    }

    var defaultHeaders: [String: String] {
        return [
            "Authorization": "Bearer \(token)"
        ]
    }
}
