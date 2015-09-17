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

/**
*  Auth0 API v2 `/users` endpoint helper
*/
public struct Users {

    let api: API
    let token: String

    init(api: API, token: String) {
        self.api = api
        self.token = token
    }

    /**
    Update a user performing a `PATCH` to `/users/:id`

    - parameter id:           of the auth0 user to update. If nil it will be obtained from the `id_token`.
    - parameter userMetadata: of the user to update.
    - parameter appMetadata:  of the user to update.
    - parameter parameters:   of the user, can include `user_metadata` and `app_metadata`.

    - returns: API request sent to Auth0
    */
    public func update(id: String? = nil, userMetadata: [String: AnyObject]? = nil, appMetadata: [String: AnyObject]? = nil, parameters: [String: AnyObject]? = [:]) -> APIRequest<[String: AnyObject]> {
        switch(normalizedUserId(id)) {
        case let .Some(userId):
            let url = NSURL(string: "api/v2/users/\(userId)", relativeToURL: self.api.domainUrl)!
            var param: [String: AnyObject] = parameters != nil ? parameters! : [:]
            if let metadata = userMetadata {
                param["user_metadata"] = metadata
            }
            if let metadata = appMetadata {
                param["app_metadata"] = metadata
            }
            let request = self.api.manager.request(jsonRequest(.PATCH, url: url, parameters: param))
            return APIRequest<[String: AnyObject]>(request: request) { return $0 as? [String: AnyObject] }
        case .None:
            return APIRequest<[String: AnyObject]>(error: NSError(domain: "com.auth0.api", code: 0, userInfo: [NSLocalizedDescriptionKey: "No id of a user supplied to perform the update"]))
        }
    }

    /**
    Find a user by id performing a `GET` to `/users/:id`

    - parameter id:            of the auth0 user to update. If nil it will be obtained from the `id_token`
    - parameter fields:        to be included or excluded from the response
    - parameter includeFields: that will determine if the list of fields are to be included or excluded from the response

    - returns: API request sent to Auth0
    */
    public func find(id: String? = nil, fields: [String]? = nil, includeFields: Bool = true) -> APIRequest<[String: AnyObject]> {
        switch(normalizedUserId(id)) {
        case let .Some(userId):
            let components = NSURLComponents(URL: self.api.domainUrl, resolvingAgainstBaseURL: true)!
            components.path = "/api/v2/users/\(userId)"
            if fields != nil && !fields!.isEmpty {
                components.queryItems = [
                    NSURLQueryItem(name: "fields", value: (fields!).joinWithSeparator(",")),
                    NSURLQueryItem(name: "include_fields", value: "\(includeFields)"),
                ]
            }
            let request = self.api.manager.request(jsonRequest(.GET, url: components.URL!))
            return APIRequest<[String: AnyObject]>(request: request) { return $0 as? [String: AnyObject] }
        case .None:
            return APIRequest<[String: AnyObject]>(error: NSError(domain: "com.auth0.api", code: 0, userInfo: [NSLocalizedDescriptionKey: "No id of a user supplied to fetch"]))
        }
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
        let jwt = try? JWTDecode.decode(token)
        return jwt?.subject
    }

    private func jsonRequest(method: Alamofire.Method, url: NSURL, parameters: [String: AnyObject]? = nil) -> NSURLRequest {
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

