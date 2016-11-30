// ResponseType.swift
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

public struct ResponseOptions: OptionSet {
    public let rawValue: Int
    public let label: String?

    public init(rawValue: Int) {
        self.rawValue = rawValue
        self.label = nil
    }

    init(rawValue: Int, label: String) {
        self.rawValue = rawValue
        self.label = label
    }

    public static let token     = ResponseOptions(rawValue: 1 << 0, label: "token")
    public static let id_token  = ResponseOptions(rawValue: 1 << 1, label: "id_token")
    public static let code      = ResponseOptions(rawValue: 1 << 2, label: "code")
}

// TODO: Expand with descriptive error messages
public enum ResponseError: Error {
    case idTokenMissing, tokenDecodeFailed, nonceDoesNotMatch, tokenIssue
}
