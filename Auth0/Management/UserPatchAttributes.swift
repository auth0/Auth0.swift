// UserPatchAttributes.swift
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

public class UserPatchAttributes {

    private(set) var dictionary: [String: AnyObject] = [:]

    public func blocked(blocked: Bool) -> UserPatchAttributes {
        dictionary["blocked"] = blocked
        return self
    }

    public func email(email: String, verified: Bool? = nil, verify: Bool? = nil, connection: String, clientId: String) -> UserPatchAttributes {
        dictionary["email"] = email
        dictionary["verify_email"] = verify
        dictionary["email_verified"] = verified
        dictionary["connection"] = connection
        dictionary["client_id"] = clientId
        return self
    }

    public func emailVerified(verified: Bool, connection: String) -> UserPatchAttributes {
        dictionary["email_verified"] = verified
        dictionary["connection"] = connection
        return self
    }

    public func phoneNumber(phoneNumber: String, verified: Bool? = nil, verify: Bool? = nil, connection: String, clientId: String) -> UserPatchAttributes {
        dictionary["phone_number"] = phoneNumber
        dictionary["verify_phone_number"] = verify
        dictionary["phone_verified"] = verified
        dictionary["connection"] = connection
        dictionary["client_id"] = clientId
        return self
    }

    public func phoneVerified(verified: Bool, connection: String) -> UserPatchAttributes {
        dictionary["phone_verified"] = verified
        dictionary["connection"] = connection
        return self
    }

    public func password(password: String, verify: Bool? = nil, connection: String) -> UserPatchAttributes {
        dictionary["password"] = password
        dictionary["connection"] = connection
        dictionary["verify_password"] = verify
        return self
    }

    public func username(username: String, connection: String) -> UserPatchAttributes {
        dictionary["username"] = username
        dictionary["connection"] = connection
        return self
    }

    public func userMetadata(metadata: [String: AnyObject]) -> UserPatchAttributes {
        dictionary["user_metadata"] = metadata
        return self
    }

    public func appMetadata(metadata: [String: AnyObject]) -> UserPatchAttributes {
        dictionary["app_metadata"] = metadata
        return self
    }
}