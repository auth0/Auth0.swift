// Users.swift
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

public struct Users {
    let management: Management

    public func get(identifier: String, fields: [String] = [], include: Bool = true) -> Request<Management.Object, Management.Error> {
        let userPath = "/api/v2/users/\(identifier)"
        let component = components(self.management.url, path: userPath)
        let value = fields.joinWithSeparator(",")
        if !value.isEmpty {
            component.queryItems = [
                NSURLQueryItem(name: "fields", value: value),
                NSURLQueryItem(name: "include_fields", value: String(include))
            ]
        }

        return Request(session: self.management.session, url: component.URL!, method: "GET", handle: self.management.managementObject)
    }

    public func patch(identifier: String, attributes: UserPatchAttributes) -> Request<Management.Object, Management.Error> {
        let userPath = "/api/v2/users/\(identifier)"
        let component = components(self.management.url, path: userPath)

        return Request(session: self.management.session, url: component.URL!, method: "PATCH", handle: self.management.managementObject, payload: attributes.dictionary)
    }

    public func patch(identifier: String, userMetadata: [String: AnyObject]) -> Request<Management.Object, Management.Error> {
        return patch(identifier, attributes: UserPatchAttributes().userMetadata(userMetadata))
    }

    public func link(identifier: String, withSecondaryUserToken token: String) -> Request<[Management.Object], Management.Error> {
        let identitiesPath = "/api/v2/users/\(identifier)/identities"
        let component = components(self.management.url, path: identitiesPath)

        return Request(session: self.management.session, url: component.URL!, method: "POST", handle: self.management.managementObjects, payload: ["link_with": token])
    }

    public func link(identifier: String, withUser userId: String, provider: String, connectionId: String? = nil) -> Request<[Management.Object], Management.Error> {
        let identitiesPath = "/api/v2/users/\(identifier)/identities"
        let component = components(self.management.url, path: identitiesPath)
        var payload: [String: AnyObject] = [
            "user_id": userId,
            "provider": provider,
        ]
        payload["connection_id"] = connectionId
        return Request(session: self.management.session, url: component.URL!, method: "POST", handle: self.management.managementObjects, payload: payload)
    }

}

private func components(baseURL: NSURL, path: String) -> NSURLComponents {
    let url = baseURL.URLByAppendingPathComponent(path)
    return NSURLComponents(URL: url, resolvingAgainstBaseURL: true)!
}