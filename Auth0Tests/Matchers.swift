// Matchers.swift
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
import OHHTTPStubs
import Nimble
@testable import Auth0

func hasAllOf(_ parameters: [String: String]) -> OHHTTPStubsTestBlock {
    return { request in
        guard let payload = request.a0_payload else { return false }
        return parameters.count == payload.count && parameters.reduce(true, { (initial, entry) -> Bool in
            return initial && payload[entry.0] as? String == entry.1
        })
    }
}

func hasAtLeast(_ parameters: [String: String]) -> OHHTTPStubsTestBlock {
    return { request in
        guard let payload = request.a0_payload else { return false }
        let entries = parameters.filter { (key, _) in payload.contains { (name, _) in  key == name } }
        return entries.count == parameters.count && entries.reduce(true, { (initial, entry) -> Bool in
            return initial && payload[entry.0] as? String == entry.1
        })
    }
}

func hasUserMetadata(_ metadata: [String: String]) -> OHHTTPStubsTestBlock {
    return hasObjectAttribute("user_metadata", value: metadata)
}

func hasObjectAttribute(_ name: String, value: [String: String]) -> OHHTTPStubsTestBlock {
    return { request in
        guard let payload = request.a0_payload, let actualValue = payload[name] as? [String: Any] else { return false }
        return value.count == actualValue.count && value.reduce(true, { (initial, entry) -> Bool in
            guard let value = actualValue[entry.0] as? String else { return false }
            return initial && value == entry.1
        })
    }
}

func hasNoneOf(_ names: [String]) -> OHHTTPStubsTestBlock {
    return { request in
        guard let payload = request.a0_payload else { return false }
        return payload.filter { names.contains($0.0) }.isEmpty
    }
}

func hasNoneOf(_ parameters: [String: String]) -> OHHTTPStubsTestBlock {
    return !hasAtLeast(parameters)
}

func hasQueryParameters(_ parameters: [String: String]) -> OHHTTPStubsTestBlock {
    return { request in
        guard
            let url = request.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let items = components.queryItems
            else { return false }
        return items.count == parameters.count && items.reduce(true, { (initial, item) -> Bool in
            return initial && parameters[item.name] == item.value
        })
    }
}

func isResourceOwner(_ domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/oauth/ro")
}

func isToken(_ domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/oauth/token")
}

func isSignUp(_ domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/dbconnections/signup")
}

func isResetPassword(_ domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/dbconnections/change_password")
}

func isPasswordless(_ domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/passwordless/start")
}

func isTokenInfo(_ domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/tokeninfo")
}

func isUserInfo(_ domain: String) -> OHHTTPStubsTestBlock {
    return isMethodGET() && isHost(domain) && isPath("/userinfo")
}

func isOAuthAccessToken(_ domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/oauth/access_token")
}

func isRevokeToken(_ domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/oauth/revoke")
}

func isUsersPath(_ domain: String, identifier: String? = nil) -> OHHTTPStubsTestBlock {
    let path: String
    if let identifier = identifier {
        path = "/api/v2/users/\(identifier)"
    } else {
        path = "/api/v2/users/"
    }
    return isHost(domain) && isPath(path)
}

func isLinkPath(_ domain: String, identifier: String) -> OHHTTPStubsTestBlock {
    return isHost(domain) && isPath("/api/v2/users/\(identifier)/identities")
}

func isJWKSPath(_ domain: String) -> OHHTTPStubsTestBlock {
    return isHost(domain) && isPath("/.well-known/jwks.json")
}

func hasBearerToken(_ token: String) -> OHHTTPStubsTestBlock {
    return { request in
        return request.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)"
    }
}

func haveAuthenticationError<T>(code: String, description: String) -> Predicate<Result<T>> {
    return Predicate<Result<T>>.define("an error response with code <\(code)> and description <\(description)") { expression, failureMessage -> PredicateResult in
        if let actual = try expression.evaluate(), case .failure(let cause as AuthenticationError) = actual {
            return PredicateResult(bool: code == cause.code && description == cause.description, message: failureMessage)
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}

func haveManagementError<T>(_ error: String, description: String, code: String, statusCode: Int) -> Predicate<Result<T>> {
    return beFailure("server error response") { (cause: ManagementError) in
        return error == (cause.info["error"] as? String)
            && code == (cause.info["code"] as? String)
            && description == (cause.info["description"] as? String)
            && statusCode == (cause.info["statusCode"] as? Int)
    }
}

func haveCredentials(_ accessToken: String? = nil, _ idToken: String? = nil) -> Predicate<Result<Credentials>> {
    return Predicate<Result<Credentials>>.define("a successful authentication result") { expression, failureMessage -> PredicateResult in
        if let accessToken = accessToken {
            _ = failureMessage.appended(message: " <access_token: \(accessToken)>")
        }
        if let idToken = idToken {
            _ = failureMessage.appended(message: " <id_token: \(idToken)>")
        }
        if let actual = try expression.evaluate(), case .success(let credentials) = actual {
            return PredicateResult(bool: (accessToken == nil || credentials.accessToken == accessToken) && (idToken == nil || credentials.idToken == idToken), message: failureMessage)
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}

func haveCreatedUser(_ email: String, username: String? = nil) -> Predicate<Result<DatabaseUser>> {
    return Predicate<Result<DatabaseUser>>.define("have created user with email <\(email)>") { expression, failureMessage -> PredicateResult in
        if let actual = try expression.evaluate(), case .success(let created) = actual {
            return PredicateResult(bool: created.email == email && (username == nil || created.username == username), message: failureMessage)
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}

func beSuccessful<T>() -> Predicate<Result<T>> {
    return Predicate<Result<T>>.define("be a successful result") { expression, failureMessage -> PredicateResult in
        if let actual = try expression.evaluate(), case .success = actual {
            return PredicateResult(status: .matches, message: failureMessage)
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}

func beFailure<T>(_ cause: String? = nil) -> Predicate<Result<T>> {
    return Predicate<Result<T>>.define("be a failure result") { expression, failureMessage -> PredicateResult in
        if let cause = cause {
            _ = failureMessage.appended(message: " with cause \(cause)")
        } else {
            _ = failureMessage.appended(message: " from authentication api")
        }
        if let actual = try expression.evaluate(), case .failure = actual {
            return PredicateResult(status: .matches, message: failureMessage)
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}

func beFailure<T>(_ cause: String? = nil, predicate: @escaping (AuthenticationError) -> Bool) -> Predicate<Result<T>> {
    return Predicate<Result<T>>.define("be a failure result") { expression, failureMessage -> PredicateResult in
        if let cause = cause {
            _ = failureMessage.appended(message: " with cause \(cause)")
        } else {
            _ = failureMessage.appended(message: " from authentication api")
        }
        if let actual = try expression.evaluate(), case .failure(let cause as AuthenticationError) = actual {
            return PredicateResult(bool: predicate(cause), message: failureMessage)
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}

func beFailure<T>(_ cause: String? = nil, predicate: @escaping (ManagementError) -> Bool) -> Predicate<Result<T>> {
    return Predicate<Result<T>>.define("be a failure result") { expression, failureMessage -> PredicateResult in
        if let cause = cause {
            _ = failureMessage.appended(message: " with cause \(cause)")
        } else {
            _ = failureMessage.appended(message: " from management api")
        }
        if let actual = try expression.evaluate(), case .failure(let cause as ManagementError) = actual {
            return PredicateResult(bool: predicate(cause), message: failureMessage)
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}

func haveProfile(_ userId: String) -> Predicate<Result<Profile>> {
    return Predicate<Result<Profile>>.define("have user profile for user id <\(userId)>") { expression, failureMessage -> PredicateResult in
        if let actual = try expression.evaluate(), case .success(let profile) = actual {
            return PredicateResult(bool: profile.id == userId, message: failureMessage)
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}

func haveProfileOIDC(_ sub: String) -> Predicate<Result<UserInfo>> {
    return Predicate<Result<UserInfo>>.define("have userInfo for sub: <\(sub)>") { expression, failureMessage -> PredicateResult in
        if let actual = try expression.evaluate(), case .success(let userInfo) = actual {
            return PredicateResult(bool: userInfo.sub == sub, message: failureMessage)
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}

func haveObjectWithAttributes(_ attributes: [String]) -> Predicate<Result<[String: Any]>> {
    return Predicate<Result<[String: Any]>>.define("have attribues \(attributes)") { expression, failureMessage -> PredicateResult in
        if let actual = try expression.evaluate(), case .success(let value) = actual {
            let outcome = Array(value.keys).reduce(true, { (initial, value) -> Bool in
                return initial && attributes.contains(value)
            })
            return PredicateResult(bool: outcome, message: failureMessage)
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}

func haveJWKS() -> Predicate<Result<JWKS>> {
    return Predicate<Result<JWKS>>.define("have a JWKS object with at least one key") { expression, failureMessage -> PredicateResult in
        if let actual = try expression.evaluate(), case .success(let jwks) = actual {
            return PredicateResult(bool: !jwks.keys.isEmpty, message: failureMessage)
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}

func beURLSafeBase64() -> Predicate<String> {
    return Predicate<String>.define("be url safe base64") { expression, failureMessage -> PredicateResult in
        var set = CharacterSet()
        set.formUnion(.alphanumerics)
        set.insert(charactersIn: "-_/")
        set.invert()
        if let actual = try expression.evaluate() , actual.rangeOfCharacter(from: set) == nil {
            return PredicateResult(status: .matches, message: failureMessage)
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}

extension URLRequest {
    var a0_payload: [String: Any]? {
        get {
            return URLProtocol.property(forKey: parameterPropertyKey, in: self) as? [String: Any]
        }
    }
}
