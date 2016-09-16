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

            it("should detect access_denied") {
                let error = AuthenticationError(info: ["error": "access_denied"], statusCode: 401)
                expect(error.isAccessDenied) == true
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
                    ExampleDescriptionKey: "You may not reuse any of the last 2 passwords. This password was used a day ago.",
                    ExampleExtraKey: [
                        "name": "PasswordHistoryError",
                        "message": "Password has previously been used",
                    ]
                ]
            }

            it("should have status code") {
                let values = [
                    "code": "invalid_password",
                    "description": "You may not reuse any of the last 2 passwords. This password was used a day ago.",
                    "name": "PasswordHistoryError",
                    "message":"Password has previously been used",
                    ]
                let error = AuthenticationError(info: values, statusCode: 400)
                expect(error.statusCode) == 400
            }

            it("should detect password already used") {
                let values: [String: Any] = [
                    "code": "invalid_password",
                    "description": "You may not reuse any of the last 2 passwords. This password was used a day ago.",
                    "name": "PasswordHistoryError",
                    "message":"Password has previously been used",
                    "statusCode": 400,
                ]
                let error = AuthenticationError(info: values, statusCode: 400)
                expect(error.isPasswordAlreadyUsed) == true
            }

            it("should detect password already used") {
                let values: [String: Any] = [
                    "code": "invalid_password",
                    "description": "You may not reuse any of the last 2 passwords. This password was used a day ago.",
                    "name": "PasswordHistoryError",
                    "message":"Password has previously been used",
                    "statusCode": 400,
                    ]
                let error = AuthenticationError(info: values, statusCode: 400)
                expect(error.isPasswordAlreadyUsed) == true
            }

            it("should detect rule error") {
                let values = [
                    "error": "unauthorized",
                    "error_description": "user is blocked"
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isRuleError) == true
            }

            it("should detect mfa required") {
                let values = [
                    "error": "a0.mfa_required",
                    "error_description": "missing mfa_code parameter"
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isMultifactorRequired) == true
            }

            it("should detect mfa enrolled required") {
                let values = [
                    "error": "a0.mfa_registration_required",
                    "error_description": "User is not enrolled with google-authenticator"
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isMultifactorEnrollRequired) == true
            }

            it("should detect mfa invalid code") {
                let values = [
                    "error": "a0.mfa_invalid_code",
                    "error_description": "Wrong or expired code."
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isMultifactorCodeInvalid) == true
            }

            it("should detect too many attempts") {
                let values = [
                    "error": "too_many_attempts",
                    "error_description": "too many attempts"
                ]
                let error = AuthenticationError(info: values, statusCode: 429)
                expect(error.isTooManyAttempts) == true
            }

        }

    }
}

class AuthenticationErrorSpecSharedExamplesConfiguration: QuickConfiguration {
    override class func configure(_ configuration: Configuration) {
        sharedExamples(OAuthErrorExample) { (context: SharedExampleContext) in
            let code = context()[ExampleCodeKey] as! String
            let description = context()[ExampleDescriptionKey] as? String
            var values = [
                "error": code,
            ]
            values["error_description"] = description
            let error = AuthenticationError(info: values, statusCode: 401)

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

            values.forEach { key, value in
                it("should contain \(key)") {
                    expect(error.info[key] as? String) == value
                }
            }


            it("should not match any custom error") {
                expect(error.isRuleError).to(beFalse(), description: "should not match rule error")
                expect(error.isPasswordNotStrongEnough).to(beFalse(), description: "should not match pwd strength")
                expect(error.isPasswordAlreadyUsed).to(beFalse(), description: "should not match pwd history")
                expect(error.isInvalidCredentials).to(beFalse(), description: "should not match invalid creds")
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
            let error = AuthenticationError(info: values, statusCode: 401)

            it("should have code \(code)") {
                expect(error.code) == code
            }

            it("should have description \(description)") {
                expect(error.description) == description
            }

            values.forEach { key, value in
                it("should contain \(key)") {
                    expect(error.info[key] as? String) == value
                }
            }

            extras?.forEach { key, value in
                it("should have key \(key) with value \(value)") {
                    expect(error.info[key] as? String) == value
                }
            }
        }

        sharedExamples(UnknownErrorExample) { (context: SharedExampleContext) in
            let values = context()[ExampleValuesKey] as! [String: Any]
            let error = AuthenticationError(info: values, statusCode: 401)
            it("should have unknown error code") {
                expect(error.code) == UnknownError
            }

            it("should have description") {
                expect(error.description).toNot(beNil())
            }

            values.forEach { key, value in
                it("should contain \(key)") {
                    expect(error.info[key]).toNot(beNil())
                }
            }

            it("should not match any known error") {
                expect(error.isMultifactorCodeInvalid).to(beFalse(), description: "should not match mfa invalid")
                expect(error.isMultifactorEnrollRequired).to(beFalse(), description: "should not match mfa enroll")
                expect(error.isMultifactorRequired).to(beFalse(), description: "should not match mfa missing")
                expect(error.isRuleError).to(beFalse(), description: "should not match rule error")
                expect(error.isPasswordNotStrongEnough).to(beFalse(), description: "should not match pwd strength")
                expect(error.isPasswordAlreadyUsed).to(beFalse(), description: "should not match pwd history")
                expect(error.isAccessDenied).to(beFalse(), description: "should not match acces denied")
                expect(error.isInvalidCredentials).to(beFalse(), description: "should not match invalid creds")
            }
        }

        sharedExamples(PlainErrorExample) { (context: SharedExampleContext) in
            let value = context()[ExamplePlainValueKey] as? String
            let status = context()[ExamplePlainStatusKey] as? Int ?? 0
            let error = AuthenticationError(string: value, statusCode: status)

            if value != nil {
                it("should have plain error code") {
                    expect(error.code) == NonJSONError
                }
            } else {
                it("should have empty body error code") {
                    expect(error.code) == EmptyBodyError
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
