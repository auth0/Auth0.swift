// Users.swift
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
import Alamofire
import JWTDecode

public class Users: NSObject {

    let api: API
    let token: String

    init(api: API, token: String) {
        self.api = api
        self.token = token
        super.init()
    }

    public func updateMetadata(id: String? = nil, _ metadata: [String: AnyObject]) -> APIRequest<[String: AnyObject]> {
        switch(normalizedUserId(id)) {
        case let .Some(userId):
            let url = NSURL(string: "api/v2/users/\(userId)", relativeToURL: self.api.domainUrl)!
            let parameters = [
                "user_metadata": metadata
            ]
            let request = self.api.manager.request(jsonRequest(.PATCH, url: url, parameters: parameters))
            return APIRequest<[String: AnyObject]>(request: request) { return $0 as? [String: AnyObject] }
        case .None:
            return APIRequest<[String: AnyObject]>(error: NSError(domain: "com.auth0.api", code: 0, userInfo: [NSLocalizedDescriptionKey: "No id of a user supplied to perform the update"]))
        }
    }

    public func findWithId(id: String? = nil, fields: [String] = []) -> APIRequest<[String: AnyObject]> {
        let url = NSURL(string: "api/v2/users/\(self.normalizedUserId(id)!)", relativeToURL: self.api.domainUrl)!
        let request = self.api.manager.request(jsonRequest(.GET, url: url, parameters: nil))
        return APIRequest<[String: AnyObject]>(request: request) { return $0 as? [String: AnyObject] }
    }

    private func normalizedUserId(id: String?) -> String? {
        var identifier: String?
        switch(id) {
        case let .Some(id):
            identifier = id
        default:
            identifier = self.subjectFromToken(self.token)
        }
        return identifier?.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
    }

    private func subjectFromToken(token: String) -> String? {
        let payload = JWTDecode.payload(jwt: token)!
        return payload["sub"] as? String
    }

    private func jsonRequest(method: Alamofire.Method, url: NSURL, parameters: [String: AnyObject]?) -> NSURLRequest {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = method.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let params = parameters {
            return Alamofire.ParameterEncoding.JSON.encode(request, parameters: params).0
        } else {
            return request
        }
    }
}

