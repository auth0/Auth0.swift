// AuthenticationErrorSpec.swift
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

import Quick
import Nimble

@testable import Auth0

private let ExampleCodeKey = "com.auth0.authentication.example.code.key"
private let ExampleDescriptionKey = "com.auth0.authentication.example.description.key"
private let ExampleExtraKey = "com.auth0.authentication.example.extra.key"
private let ExampleValuesKey = "com.auth0.authentication.example.values.key"
private let ExamplePlainValueKey = "com.auth0.authentication.example.value.key"
private let ExamplePlainStatusKey = "com.auth0.authentication.example.status.key"

private let UnknownErrorExample = "com.auth0.authentication.example.unknown"
private let PlainErrorExample = "com.auth0.authentication.example.plain"
private let Auth0ErrorExample = "com.auth0.authentication.example.auth0"
private let OAuthErrorExample = "com.auth0.authentication.example.oauth"

class AuthenticationErrorSpec: QuickSpec {
    override func spec() {

        describe("oauth spec error") {

            itBehavesLike(OAuthErrorExample) {
                return [
                    ExampleCodeKey: "invalid_request",
                    ExampleDescriptionKey: "missing client_id",
                ]
            }

            itBehavesLike(OAuthErrorExample) {
                return [
                    ExampleCodeKey: "invalid_request",
                ]
            }

        }

        describe("unknown error structure") {

            itBehavesLike(UnknownErrorExample) { return [ExampleValuesKey: ["key": "value"]] }

            itBehavesLike(UnknownErrorExample) { return [ExampleValuesKey: [:]] }

        }

        describe("non json") {

            itBehavesLike(PlainErrorExample) { return [ExamplePlainValueKey: "random string"] }
            itBehavesLike(PlainErrorExample) { return [ExamplePlainStatusKey: 200] }

        }

        describe("auth0 error") {

            itBehavesLike(Auth0ErrorExample) { return [
                    ExampleCodeKey: "invalid_password",
                    ExampleDescriptionKey: "You may not reuse any of the last 2 passwords. This password was     used a day ago.",
                    ExampleExtraKey: [
                        "name": "PasswordHistoryError",
                        "message":"Password has previously been used",
                    ]
                ]
            }
        }

    }
}

class AuthenticationErrorSpecSharedExamplesConfiguration: QuickConfiguration {
    override class func configure(configuration: Configuration) {
        sharedExamples(OAuthErrorExample) { (context: SharedExampleContext) in
            let code = context()[ExampleCodeKey] as! String
            let description = context()[ExampleDescriptionKey] as? String
            var values = [
                "error": code,
            ]
            values["error_description"] = description
            let error = AuthenticationError(info: values)

            it("should have code \(code)") {
                expect(error.code) == code
            }

            if let description = description {
                it("should have description \(description)") {
                    expect(error.description) == description
                }
            } else {
                it("should have a description") {
                    expect(error.description).toNot(beNil())
                }
            }

            it("should return all values") {
                expect(error.info.count) == values.count
            }
        }

        sharedExamples(Auth0ErrorExample) { (context: SharedExampleContext) in
            let code = context()[ExampleCodeKey] as! String
            let description = context()[ExampleDescriptionKey] as! String
            let extras = context()[ExampleExtraKey] as? [String: String]
            var values = [
                "code": code,
                "description": description,
                ]
            extras?.forEach { values[$0] = $1 }
            let error = AuthenticationError(info: values)

            it("should have code \(code)") {
                expect(error.code) == code
            }

            it("should have description \(description)") {
                expect(error.description) == description
            }

            it("should return all values") {
                expect(error.info.count) == values.count
            }

            extras?.forEach { key, value in
                it("should have key \(key) with value \(value)") {
                    expect(error.info[key] as? String) == value
                }
            }
        }

        sharedExamples(UnknownErrorExample) { (context: SharedExampleContext) in
            let values = context()[ExampleValuesKey] as! [String: AnyObject]
            let error = AuthenticationError(info: values)
            it("should have unknown error code") {
                expect(error.code) == AuthenticationError.UnknownCode
            }

            it("should have description") {
                expect(error.description).toNot(beNil())
            }

            it("should return all values") {
                expect(error.info.count) == values.count
            }
        }

        sharedExamples(PlainErrorExample) { (context: SharedExampleContext) in
            let value = context()[ExamplePlainValueKey] as? String
            let status = context()[ExamplePlainStatusKey] as? Int ?? 0
            let error = AuthenticationError(string: value, statusCode: status)

            if value != nil {
                it("should have plain error code") {
                    expect(error.code) == AuthenticationError.NonJSONError
                }
            } else {
                it("should have empty body error code") {
                    expect(error.code) == AuthenticationError.EmptyBodyError
                }
            }

            if let value = value {
                it("should have description") {
                    expect(error.description) == value
                }
            } else {
                it("should have description") {
                    expect(error.description).toNot(beNil())
                }
            }

            it("should return status code") {
                expect(error.info["statusCode"] as? Int).toNot(beNil())
            }
        }
        
    }
}
