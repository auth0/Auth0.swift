// Auth0.swift
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
import Alamofire

func url(domain: String) -> NSURL {
    let urlString: String
    if !domain.hasPrefix("https") {
        urlString = "https://\(domain)"
    } else {
        urlString = domain
    }
    return NSURL(string: urlString)!
}

public func authentication(clientId clientId: String, domain: String) -> Authentication {
    return Authentication(clientId: clientId, url: url(domain))
}

public struct Authentication {
    public let clientId: String
    public let url: NSURL

    let manager: Alamofire.Manager

    public init(clientId: String, url: NSURL) {
        self.init(clientId: clientId, url: url, manager: Alamofire.Manager.sharedInstance)
    }

    init(clientId: String, url: NSURL, manager: Alamofire.Manager) {
        self.clientId = clientId
        self.url = url
        self.manager = manager
    }

    public enum Result {
        case Success(credentials: [String: String])
        case Failure(error: Error)
    }

    public enum Error: ErrorType {
        case Response(code: String, description: String)
        case InvalidURL(urlString: String)
        case InvalidResponse(response: AnyObject)
        case Unknown(cause: ErrorType)
    }

    public func login(username: String, password: String, connection: String, scope: String = "openid", parameters: [String: AnyObject] = [:], callback: Result -> ()) {
        var payload: [String: AnyObject] = [
            "username": username,
            "password": password,
            "connection": connection,
            "grant_type": "password",
            "scope": scope,
            "client_id": self.clientId
        ]
        parameters.forEach { key, value in payload[key] = value }
        guard let resourceOwner = NSURL(string: "/oauth/ro", relativeToURL: self.url) else {
            callback(.Failure(error: .InvalidURL(urlString: self.url.absoluteString)))
            return
        }
        self.manager.request(.POST, resourceOwner, parameters: payload)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .Success(let payload):
                    if let credentials = payload as? [String: String] {
                        callback(.Success(credentials: credentials))
                    } else {
                        callback(.Failure(error: .InvalidResponse(response: payload)))
                    }
                case .Failure(let cause):
                    callback(.Failure(error: authenticationError(response, cause: cause)))
                }
        }
    }
}

private func authenticationError(response: Alamofire.Response<AnyObject, NSError>, cause: NSError) -> Authentication.Error {
    if let jsonData = response.data,
        let json = try? NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions()),
        let payload = json as? [String: AnyObject] {
        return payloadError(payload, cause: cause)
    } else {
        return .Unknown(cause: cause)
    }
}

private func payloadError(payload: [String: AnyObject], cause: ErrorType) -> Authentication.Error {
    if let code = payload["error"] as? String, let description = payload["error_description"] as? String {
        return .Response(code: code, description: description)
    }

    if let code = payload["code"] as? String, let description = payload["description"] as? String {
        return .Response(code: code, description: description)
    }

    return .Unknown(cause: cause)
}
