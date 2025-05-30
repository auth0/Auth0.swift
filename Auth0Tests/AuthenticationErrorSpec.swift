import Foundation
import Quick
import Nimble

@testable import Auth0

private let ExampleCodeKey = "com.auth0.authentication.example.code.key"
private let ExampleDescriptionKey = "com.auth0.authentication.example.description.key"
private let ExampleExtraKey = "com.auth0.authentication.example.extra.key"
private let ExampleValuesKey = "com.auth0.authentication.example.values.key"
private let ExamplePlainValueKey = "com.auth0.authentication.example.value.key"
private let ExamplePlainStatusKey = "com.auth0.authentication.example.status.key"


class AuthenticationErrorSpec: QuickSpec {
    override class func spec() {

        describe("init") {

            it("should initialize with info") {
                let info: [String: Any] = ["foo": "bar"]
                let error = AuthenticationError(info: info)
                expect(error.info["foo"] as? String) == "bar"
                expect(error.info.count) == 2
                expect(error.statusCode) == 0
                expect(error.cause).to(beNil())
            }

            it("should initialize with info & status code") {
                let info: [String: Any] = ["foo": "bar"]
                let statusCode = 400
                let error = AuthenticationError(info: info, statusCode: statusCode)
                expect(error.statusCode) == statusCode
            }

            it("should initialize with cause") {
                let cause = NSError(domain: "com.auth0", code: -99999, userInfo: nil)
                let error = AuthenticationError(cause: cause)
                expect(error.cause).to(matchError(cause))
                expect(error.statusCode) == 0
            }

            it("should initialize with cause & status code") {
                let cause = NSError(domain: "com.auth0", code: -99999, userInfo: nil)
                let statusCode = 400
                let error = AuthenticationError(cause: cause, statusCode: statusCode)
                expect(error.statusCode) == statusCode
            }

            it("should initialize with description") {
                let description = "foo"
                let error = AuthenticationError(description: description)
                expect(error.localizedDescription) == description
                expect(error.statusCode) == 0
                expect(error.cause).to(beNil())
            }

            it("should initialize with description & status code") {
                let description = "foo"
                let statusCode = 400
                let error = AuthenticationError(description: description, statusCode: statusCode)
                expect(error.statusCode) == statusCode
            }

            it("should initialize with response") {
                let description = "foo"
                let data = description.data(using: .utf8)!
                let response = Response<AuthenticationError>(data: data, response: nil, error: nil)
                let error = AuthenticationError(from: response)
                expect(error.localizedDescription) == description
                expect(error.statusCode) == 0
                expect(error.cause).to(beNil())
            }

            it("should initialize with response & status code") {
                let description = "foo"
                let data = description.data(using: .utf8)!
                let statusCode = 400
                let httpResponse = HTTPURLResponse(url: URL(string: "example.com")!,
                                                   statusCode: statusCode,
                                                   httpVersion: nil,
                                                   headerFields: nil)
                let response = Response<AuthenticationError>(data: data, response: httpResponse, error: nil)
                let error = AuthenticationError(from: response)
                expect(error.localizedDescription) == description
                expect(error.statusCode) == statusCode
            }

            it("should initialize with cause") {
                let cause = MockError()
                let description = "Unable to complete the operation. CAUSE: \(cause.localizedDescription)."
                let error = AuthenticationError(cause: cause)
                expect(error.cause).toNot(beNil())
                expect(error.localizedDescription) == description
                expect(error.statusCode) == 0
            }

            it("should initialize with cause & status code") {
                let statusCode = 400
                let error = AuthenticationError(cause: MockError(), statusCode: statusCode)
                expect(error.statusCode) == statusCode
            }

        }

        describe("operators") {

            it("should be equal") {
                let info: [String: Any] = ["code": "foo", "description": "bar"]
                let statusCode = 400
                let error = AuthenticationError(info: info, statusCode: statusCode)
                expect(error) == AuthenticationError(info: info, statusCode: statusCode)
            }

            it("should not be equal to an error with a different code") {
                let description = "foo"
                let statusCode = 400
                let error = AuthenticationError(info: ["code": "bar", "description": description], statusCode: statusCode)
                expect(error) != AuthenticationError(info: ["code": "baz", "description": description], statusCode: statusCode)
            }

            it("should not be equal to an error with a different status code") {
                let info: [String: Any] = ["code": "foo", "description": "bar"]
                let error = AuthenticationError(info: info, statusCode: 400)
                expect(error) != AuthenticationError(info: info, statusCode: 500)
            }

            it("should not be equal to an error with a different description") {
                let code = "foo"
                let statusCode = 400
                let error = AuthenticationError(info: ["code": code, "description": "bar"], statusCode: statusCode)
                expect(error) != AuthenticationError(info: ["code": code, "description": "baz"], statusCode: statusCode)
            }

            it("should access the internal info dictionary") {
                let info: [String: Any] = ["foo": "bar"]
                let error = AuthenticationError(info: info)
                expect(error.info["foo"] as? String) == "bar"
            }

        }

        describe("oauth spec error") {

            itBehavesLike(OAuthErrorBehavior.self) {
                return [
                    ExampleCodeKey: "invalid_request",
                    ExampleDescriptionKey: "missing client_id",
                ]
            }

            itBehavesLike(OAuthErrorBehavior.self) {
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

            itBehavesLike(UnknownErrorBehavior.self) { return [ExampleValuesKey: ["key": "value"]] }
            itBehavesLike(UnknownErrorBehavior.self) { return [ExampleValuesKey: [String: String]()] }

        }

        describe("non json") {

            itBehavesLike(PlainErrorBehavior.self) { return [ExamplePlainValueKey: "random string"] }
            itBehavesLike(PlainErrorBehavior.self) { return [ExamplePlainStatusKey: 200] }

        }

        describe("auth0 error") {

            itBehavesLike(Auth0ErrorBehavior.self) { return [
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
                    "message": "Password has previously been used",
                ]
                let error = AuthenticationError(info: values, statusCode: 400)
                expect(error.statusCode) == 400
            }

            it("should not have an underlying error") {
                let values = [
                    "code": "invalid_password",
                    "description": "You may not reuse any of the last 2 passwords. This password was used a day ago.",
                    "name": "PasswordHistoryError",
                    "message": "Password has previously been used",
                ]
                let error = AuthenticationError(info: values, statusCode: 400)
                expect(error.cause).to(beNil())
            }

            it("should detect password not strong enough") {
                let values: [String: Any] = [
                    "code": "invalid_password",
                    "description": "Password is not strong enough",
                    "name": "PasswordStrengthError",
                    "message": "Password is not strong enough",
                    "statusCode": 400
                ]
                let error = AuthenticationError(info: values, statusCode: 400)
                expect(error.isPasswordNotStrongEnough) == true
            }

            it("should detect password already used") {
                let values: [String: Any] = [
                    "code": "invalid_password",
                    "description": "You may not reuse any of the last 2 passwords. This password was used a day ago.",
                    "name": "PasswordHistoryError",
                    "message": "Password has previously been used",
                    "statusCode": 400
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

            it("should detect mfa required oidc") {
                let values = [
                    "error": "mfa_required",
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

            it("should detect mfa enrolled required oidc") {
                let values = [
                    "error": "unsupported_challenge_type",
                    "error_description": "User is not enrolled with google-authenticator"
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isMultifactorEnrollRequired) == true
            }

            it("should detect mfa invalid otp code") {
                let values = [
                    "error": "a0.mfa_invalid_code",
                    "error_description": "Wrong or expired code."
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isMultifactorCodeInvalid) == true
            }

            it("should detect mfa invalid otp code oidc") {
                let values = [
                    "error": "invalid_grant",
                    "error_description": "Invalid otp_code."
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isMultifactorCodeInvalid) == true
            }

            it("should detect mfa invalid binding code") {
                let values = [
                    "error": "invalid_grant",
                    "error_description": "Invalid binding_code."
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isMultifactorCodeInvalid) == true
            }

            it("should detect mfa invalid recovery code") {
                let values = [
                    "error": "invalid_grant",
                    "error_description": "MFA Authorization rejected."
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

            it("should detect invalid credentials") {
                let values = [
                    "error": "invalid_grant",
                    "error_description": "Wrong email or password."
                ]
                let error = AuthenticationError(info: values, statusCode: 403)
                expect(error.isInvalidCredentials) == true
            }

            it("should detect invalid credentials email") {
                let values = [
                    "error": "invalid_grant",
                    "error_description": "Wrong email or verification code."
                ]
                let error = AuthenticationError(info: values, statusCode: 403)
                expect(error.isInvalidCredentials) == true
            }

            it("should detect invalid credentials phone number") {
                let values = [
                    "error": "invalid_grant",
                    "error_description": "Wrong phone number or verification code."
                ]
                let error = AuthenticationError(info: values, statusCode: 403)
                expect(error.isInvalidCredentials) == true
            }

            it("should detect refresh token deleted") {
                let values = [
                    "error": "invalid_grant",
                    "error_description": "The refresh_token was generated for a user who doesn't exist anymore."
                ]
                let error = AuthenticationError(info: values, statusCode: 403)
                expect(error.isRefreshTokenDeleted) == true
            }

            it("should detect invalid refresh token") {
                let values = [
                    "error": "invalid_grant",
                    "error_description": "Unknown or invalid refresh token."
                ]
                let error = AuthenticationError(info: values, statusCode: 403)
                expect(error.isInvalidRefreshToken) == true
            }

            it("should detect invalid mfa token") {
                let values = [
                    "error": "expired_token",
                    "error_description": "mfa_token is expired"
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isMultifactorTokenInvalid) == true
            }

            it("should detect malformed mfa token") {
                let values = [
                    "error": "invalid_grant",
                    "error_description": "Malformed mfa_token"
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isMultifactorTokenInvalid) == true
            }

            it("should detect verification required") {
                let values = [
                    "error": "requires_verification",
                    "error_description": "Suspicious request requires verification"
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isVerificationRequired) == true
            }

            it("should detect password leaked") {
                let values = [
                    "error": "password_leaked",
                    "error_description": "Password leaked"
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isPasswordLeaked) == true
            }

            it("should detect login required") {
                let values = [
                    "error": "login_required",
                    "error_description": "Login required"
                ]
                let error = AuthenticationError(info: values, statusCode: 401)
                expect(error.isLoginRequired) == true
            }

            it("should detect network error") {
                for errorCode in AuthenticationError.networkErrorCodes {
                    expect(AuthenticationError(cause: URLError.init(errorCode)).isNetworkError) == true
                }
            }

        }

        describe("error message") {

            it("should return the message") {
                let description = "foo"
                let info: [String: Any] = ["description": description]
                let error = AuthenticationError(info: info)
                expect(error.localizedDescription) == description
            }

            it("should return the default message") {
                let info: [String: Any] = ["foo": "bar", "statusCode": 0]
                let message = "Failed with unknown error: \(info)."
                let error = AuthenticationError(info: info)
                expect(error.localizedDescription) == message
            }

            it("should append the cause error message") {
                let description = "foo."
                let cause =  MockError(message: "bar.")
                let info: [String: Any] = ["description": description, "cause": cause]
                let message = "\(description) CAUSE: \(cause.localizedDescription)"
                let error = AuthenticationError(info: info)
                expect(error.localizedDescription) == message
            }

            it("should append the cause error message adding periods") {
                let description = "foo"
                let cause =  MockError(message: "bar")
                let info: [String: Any] = ["description": description, "cause": cause]
                let message = "\(description). CAUSE: \(cause.localizedDescription)."
                let error = AuthenticationError(info: info)
                expect(error.localizedDescription) == message
            }

        }

    }

}

class OAuthErrorBehavior: Behavior<[String:Any]> {
    override class func spec(_ aContext: @escaping () -> [String : Any]) {
        var context: [String:Any]!
        var error: AuthenticationError!
        
        beforeEach {
            context = aContext()
            error = AuthenticationError(info: getValuesFromBehaviourContext(context), statusCode: 401)
        }
        
        it("should have code") {
            expect(error.code) == context[ExampleCodeKey] as! String
        }
        
        it("should have description") {
            if let description = context[ExampleDescriptionKey] as? String {
                expect(error.localizedDescription) == description
            } else {
                expect(error.localizedDescription).toNot(beNil())
            }
        }
        
        it("should contain info key value pairs") {
            let values = getValuesFromBehaviourContext(context)
            values.forEach { key, value in
                expect(error.info[key] as? String) == value
            }
        }
        
        it("should not match any custom error") {
            expect(error.isRuleError).to(beFalse(), description: "should not match rule error")
            expect(error.isPasswordNotStrongEnough).to(beFalse(), description: "should not match password strength")
            expect(error.isPasswordAlreadyUsed).to(beFalse(), description: "should not match password history")
            expect(error.isInvalidCredentials).to(beFalse(), description: "should not match invalid credentials")
            expect(error.isRefreshTokenDeleted).to(beFalse(), description: "should not match refresh token deleted")
            expect(error.isInvalidRefreshToken).to(beFalse(), description: "should not match invalid refresh token")
            expect(error.isPasswordLeaked).to(beFalse(), description: "should not match password leaked")
            expect(error.isLoginRequired).to(beFalse(), description: "should not match login required")
        }
    }
}

class Auth0ErrorBehavior: Behavior<[String:Any]> {
    override class func spec(_ aContext: @escaping () -> [String : Any]) {
        var context: [String:Any]!
        var error: AuthenticationError!
        
        beforeEach {
            context = aContext()
            error = AuthenticationError(info: getValuesFromBehaviourContext(context), statusCode: 401)
        }
        
        it("should have code") {
            expect(error.code) == context[ExampleCodeKey] as! String
        }
        
        it("should have localized description") {
            expect(error.localizedDescription) == context[ExampleDescriptionKey] as! String
        }
        
        it("should contain info key value pairs") {
            let values = getValuesFromBehaviourContext(context)
            values.forEach { key, value in
                expect(error.info[key] as? String) == value
            }
        }
        
        it("should contain the extras key value pairs") {
            let extras = context[ExampleExtraKey] as? [String: String]
            extras?.forEach { key, value in
                expect(error.info[key] as? String) == value
            }
        }
    }
}

class UnknownErrorBehavior: Behavior<[String:Any]> {
    override class func spec(_ aContext: @escaping () -> [String : Any]) {
        var context: [String:Any]!
        var error: AuthenticationError!
        
        beforeEach {
            context = aContext()
            error = AuthenticationError(info: getValuesFromBehaviourContext(context), statusCode: 401)
        }
        
        it("should have unknown error code") {
            expect(error.code) == unknownError
        }
        
        it("should have localized description") {
            expect(error.localizedDescription).toNot(beNil())
        }
        
        it("should contain info key value pairs") {
            let values = getValuesFromBehaviourContext(context)
            values.forEach { key, value in
                expect(error.info[key] as? String) == value
            }
        }
        
        it("should not match any known error") {
            expect(error.isMultifactorCodeInvalid).to(beFalse(), description: "should not match mfa otp invalid")
            expect(error.isMultifactorEnrollRequired).to(beFalse(), description: "should not match mfa enroll")
            expect(error.isMultifactorTokenInvalid).to(beFalse(), description: "should not match mfa token invalid")
            expect(error.isMultifactorRequired).to(beFalse(), description: "should not match mfa missing")
            expect(error.isRuleError).to(beFalse(), description: "should not match rule error")
            expect(error.isPasswordNotStrongEnough).to(beFalse(), description: "should not match password strength")
            expect(error.isPasswordAlreadyUsed).to(beFalse(), description: "should not match password history")
            expect(error.isAccessDenied).to(beFalse(), description: "should not match access denied")
            expect(error.isInvalidCredentials).to(beFalse(), description: "should not match invalid credentials")
            expect(error.isRefreshTokenDeleted).to(beFalse(), description: "should not match refresh token deleted")
            expect(error.isInvalidRefreshToken).to(beFalse(), description: "should not match invalid refresh token")
            expect(error.isPasswordLeaked).to(beFalse(), description: "should not match password leaked")
            expect(error.isLoginRequired).to(beFalse(), description: "should not match login required")
        }
    }
}

class PlainErrorBehavior: Behavior<[String:Any]> {
    override class func spec(_ aContext: @escaping () -> [String : Any]) {
        var context: [String:Any]!
        var error: AuthenticationError!
        
        beforeEach {
            context = aContext()
            let value = context[ExamplePlainValueKey] as? String ?? ""
            let status = context[ExamplePlainStatusKey] as? Int ?? 0
            error = AuthenticationError(description:value , statusCode: status)
        }
        
        it("should have plain error code") {
            expect(error.code) == nonJSONError
        }
        
        it("should have localized description") {
            expect(error.localizedDescription) == context[ExamplePlainValueKey] as? String ?? ""
        }
        
        it("should return status code") {
            expect(error.info["statusCode"] as? Int).toNot(beNil())
        }
    }
}

func getValuesFromBehaviourContext(_ context: [String : Any]) -> [String : String] {
    var values: [String:String] = [:]
    if let code = context[ExampleCodeKey] as? String {
        values["error"] = code
    }
    if let description = context[ExampleDescriptionKey] as? String {
        values["error_description"] = description
    }
    let extras = context[ExampleExtraKey] as? [String: String]
    extras?.forEach { values[$0] = $1 }
    return values
}
