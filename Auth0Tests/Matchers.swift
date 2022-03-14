import Foundation
import Nimble
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif

@testable import Auth0

func hasAllOf(_ parameters: [String: String]) -> HTTPStubsTestBlock {
    return { request in
        guard let payload = request.payload else { return false }
        return parameters.count == payload.count && parameters.reduce(true, { (initial, entry) -> Bool in
            return initial && payload[entry.0] as? String == entry.1
        })
    }
}

func hasAtLeast(_ parameters: [String: String]) -> HTTPStubsTestBlock {
    return { request in
        guard let payload = request.payload else { return false }
        let entries = parameters.filter { (key, _) in payload.contains { (name, _) in  key == name } }
        return entries.count == parameters.count && entries.reduce(true, { (initial, entry) -> Bool in
            return initial && payload[entry.0] as? String == entry.1
        })
    }
}

func hasUserMetadata(_ metadata: [String: String]) -> HTTPStubsTestBlock {
    return hasObjectAttribute("user_metadata", value: metadata)
}

func hasObjectAttribute(_ name: String, value: [String: String]) -> HTTPStubsTestBlock {
    return { request in
        guard let payload = request.payload, let actualValue = payload[name] as? [String: Any] else { return false }
        return value.count == actualValue.count && value.reduce(true, { (initial, entry) -> Bool in
            guard let value = actualValue[entry.0] as? String else { return false }
            return initial && value == entry.1
        })
    }
}

func hasNoneOf(_ names: [String]) -> HTTPStubsTestBlock {
    return { request in
        guard let payload = request.payload else { return false }
        return payload.filter { names.contains($0.0) }.isEmpty
    }
}

func hasQueryParameters(_ parameters: [String: String]) -> HTTPStubsTestBlock {
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

func isToken(_ domain: String) -> HTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/oauth/token")
}

func isSignUp(_ domain: String) -> HTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/dbconnections/signup")
}

func isResetPassword(_ domain: String) -> HTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/dbconnections/change_password")
}

func isPasswordless(_ domain: String) -> HTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/passwordless/start")
}

func isUserInfo(_ domain: String) -> HTTPStubsTestBlock {
    return isMethodGET() && isHost(domain) && isPath("/userinfo")
}

func isRevokeToken(_ domain: String) -> HTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/oauth/revoke")
}

func isUsersPath(_ domain: String, identifier: String? = nil) -> HTTPStubsTestBlock {
    let path: String
    if let identifier = identifier {
        path = "/api/v2/users/\(identifier)"
    } else {
        path = "/api/v2/users/"
    }
    return isHost(domain) && isPath(path)
}

func isLinkPath(_ domain: String, identifier: String) -> HTTPStubsTestBlock {
    return isHost(domain) && isPath("/api/v2/users/\(identifier)/identities")
}

func isUnlinkPath(_ domain: String, identifier: String, provider: String, identityId: String) -> HTTPStubsTestBlock {
    return isHost(domain) && isPath("/api/v2/users/\(identifier)/identities/\(provider)/\(identityId)")
}

func isJWKSPath(_ domain: String) -> HTTPStubsTestBlock {
    return isHost(domain) && isPath("/.well-known/jwks.json")
}

func isMultifactorChallenge(_ domain: String) -> HTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/mfa/challenge")
}


func hasHeader(_ name: String, value: String) -> HTTPStubsTestBlock {
    return { request in
        return request.value(forHTTPHeaderField: name) == value
    }
}

func hasBearerToken(_ token: String) -> HTTPStubsTestBlock {
    return hasHeader("Authorization", value: "Bearer \(token)")
}

func containItem(withName name: String, value: String? = nil) -> Predicate<[URLQueryItem]> {
    return Predicate<[URLQueryItem]>.define("contain item with name <\(name)>") { expression, failureMessage -> PredicateResult in
        guard let items = try expression.evaluate() else { return PredicateResult(status: .doesNotMatch, message: failureMessage) }
        let outcome = items.contains { item -> Bool in
            return item.name == name && ((value == nil && item.value != nil) || item.value == value)
        }
        return PredicateResult(bool: outcome, message: failureMessage)
    }
}

func haveAuthenticationError<T>(code: String, description: String) -> Predicate<AuthenticationResult<T>> {
    return Predicate<AuthenticationResult<T>>.define("be an error response with code <\(code)> and description <\(description)") { expression, failureMessage -> PredicateResult in
        return try beFailure(expression, failureMessage) { (error: AuthenticationError) -> Bool in
            return code == error.code && description == error.localizedDescription
        }
    }
}

#if WEB_AUTH_PLATFORM
func haveAuthenticationError<T>(code: String, description: String) -> Predicate<WebAuthResult<T>> {
    return Predicate<WebAuthResult<T>>.define("be an error response with code <\(code)> and description <\(description)") { expression, failureMessage -> PredicateResult in
        return try beFailure(expression, failureMessage) { (error: WebAuthError) -> Bool in
            guard let cause = error.cause as? AuthenticationError else { return false }
            return code == cause.code && description == cause.localizedDescription
        }
    }
}
#endif

func haveManagementError<T>(_ errorString: String, description: String, code: String, statusCode: Int) -> Predicate<ManagementResult<T>> {
    return Predicate<ManagementResult<T>>.define("be an error response with code <\(code)> and description <\(description)") { expression, failureMessage -> PredicateResult in
        return try beFailure(expression, failureMessage) { (error: ManagementError) -> Bool in
            return errorString == error.info["error"] as? String
                && code == error.code
                && description == error.localizedDescription
                && statusCode == error.statusCode
        }
    }
}

func haveManagementError<T>(description: String, code: String, statusCode: Int = 0, cause: Error? = nil) -> Predicate<ManagementResult<T>> {
    return Predicate<ManagementResult<T>>.define("be an error response with code <\(code)> and description <\(description)") { expression, failureMessage -> PredicateResult in
        return try beFailure(expression, failureMessage) { (error: ManagementError) -> Bool in
            return code == error.code
                && description == error.localizedDescription
                && statusCode == error.statusCode
                && (cause == nil || error.cause?.localizedDescription == cause?.localizedDescription)
        }
    }
}

func haveManagementError<T>(description: String, statusCode: Int) -> Predicate<ManagementResult<T>> {
    return Predicate<ManagementResult<T>>.define("be an error result") { expression, failureMessage -> PredicateResult in
        return try beFailure(expression, failureMessage) { (error: ManagementError) -> Bool in
            return error.localizedDescription == description && error.statusCode == statusCode
        }
    }
}

#if WEB_AUTH_PLATFORM
func haveWebAuthError<T>(_ expected: WebAuthError) -> Predicate<WebAuthResult<T>> {
    return Predicate<WebAuthResult<T>>.define("be an error result") { expression, failureMessage -> PredicateResult in
        return try beFailure(expression, failureMessage) { (error: WebAuthError) -> Bool in
            return error == expected
                && (expected.cause == nil || error.cause?.localizedDescription == expected.cause?.localizedDescription)
        }
    }
}
#endif

func haveCredentialsManagerError<T>(_ expected: CredentialsManagerError) -> Predicate<CredentialsManagerResult<T>> {
    return Predicate<CredentialsManagerResult<T>>.define("be an error result") { expression, failureMessage -> PredicateResult in
        return try beFailure(expression, failureMessage) { (error: CredentialsManagerError) -> Bool in
            return error == expected
                && (expected.cause == nil || error.cause?.localizedDescription == expected.cause?.localizedDescription)
        }
    }
}

func haveCredentials(_ accessToken: String? = nil, _ idToken: String? = nil) -> Predicate<AuthenticationResult<Credentials>> {
    return Predicate<AuthenticationResult<Credentials>>.define("be a successful authentication result") { expression, failureMessage -> PredicateResult in
        return try haveCredentials(accessToken: accessToken,
                                   idToken: idToken,
                                   refreshToken: nil,
                                   expression,
                                   failureMessage)
    }
}

#if WEB_AUTH_PLATFORM
func haveCredentials(_ accessToken: String? = nil, _ idToken: String? = nil) -> Predicate<WebAuthResult<Credentials>> {
    return Predicate<WebAuthResult<Credentials>>.define("be a successful authentication result") { expression, failureMessage -> PredicateResult in
        return try haveCredentials(accessToken: accessToken,
                                   idToken: idToken,
                                   refreshToken: nil,
                                   expression,
                                   failureMessage)
    }
}
#endif

func haveCredentials(_ accessToken: String, _ idToken: String? = nil, _ refreshToken: String? = nil) -> Predicate<CredentialsManagerResult<Credentials>> {
    return Predicate<CredentialsManagerResult<Credentials>>.define("be a successful credentials retrieval") { expression, failureMessage -> PredicateResult in
        return try haveCredentials(accessToken: accessToken,
                                   idToken: idToken,
                                   refreshToken: refreshToken,
                                   expression,
                                   failureMessage)
    }
}

func haveCredentials() -> Predicate<CredentialsManagerResult<Credentials>> {
    return Predicate<CredentialsManagerResult<Credentials>>.define("be a successful credentials retrieval") { expression, failureMessage -> PredicateResult in
        return try beSuccessful(expression, failureMessage)
    }
}

func haveCreatedUser(_ email: String, username: String? = nil) -> Predicate<AuthenticationResult<DatabaseUser>> {
    return Predicate<AuthenticationResult<DatabaseUser>>.define("have created user with email <\(email)>") { expression, failureMessage -> PredicateResult in
        return try beSuccessful(expression, failureMessage) { (created: DatabaseUser) -> Bool in
            return created.email == email && (username == nil || created.username == username)
        }
    }
}

func beSuccessful<T>() -> Predicate<AuthenticationResult<T>> {
    return Predicate<AuthenticationResult<T>>.define("be a successful result") { expression, failureMessage -> PredicateResult in
        return try beSuccessful(expression, failureMessage)
    }
}

func beSuccessful<T>() -> Predicate<ManagementResult<T>> {
    return Predicate<ManagementResult<T>>.define("be a successful result") { expression, failureMessage -> PredicateResult in
        return try beSuccessful(expression, failureMessage)
    }
}

#if WEB_AUTH_PLATFORM
func beSuccessful<T>() -> Predicate<WebAuthResult<T>> {
    return Predicate<WebAuthResult<T>>.define("be a successful result") { expression, failureMessage -> PredicateResult in
        return try beSuccessful(expression, failureMessage)
    }
}
#endif

func beSuccessful<T>() -> Predicate<CredentialsManagerResult<T>> {
    return Predicate<CredentialsManagerResult<T>>.define("be a successful result") { expression, failureMessage -> PredicateResult in
        return try beSuccessful(expression, failureMessage)
    }
}

func beFailure<T>(_ cause: String? = nil) -> Predicate<AuthenticationResult<T>> {
    return Predicate<AuthenticationResult<T>>.define("be a failure result") { expression, failureMessage -> PredicateResult in
        if let cause = cause {
            _ = failureMessage.appended(message: " with cause \(cause)")
        } else {
            _ = failureMessage.appended(message: " from authentication api")
        }
        return try beFailure(expression, failureMessage)
    }
}

func beFailure<T>(_ cause: String? = nil) -> Predicate<ManagementResult<T>> {
    return Predicate<ManagementResult<T>>.define("be a failure result") { expression, failureMessage -> PredicateResult in
        if let cause = cause {
            _ = failureMessage.appended(message: " with cause \(cause)")
        } else {
            _ = failureMessage.appended(message: " from management api")
        }
        return try beFailure(expression, failureMessage)
    }
}

#if WEB_AUTH_PLATFORM
func beFailure<T>(_ cause: String? = nil) -> Predicate<WebAuthResult<T>> {
    return Predicate<WebAuthResult<T>>.define("be a failure result") { expression, failureMessage -> PredicateResult in
        if let cause = cause {
            _ = failureMessage.appended(message: " with cause \(cause)")
        } else {
            _ = failureMessage.appended(message: " from web auth")
        }
        return try beFailure(expression, failureMessage)
    }
}
#endif

func beFailure<T>() -> Predicate<CredentialsManagerResult<T>> {
    return Predicate<CredentialsManagerResult<T>>.define("be a failure result") { expression, failureMessage -> PredicateResult in
        _ = failureMessage.appended(message: " from credentials manager")
        return try beFailure(expression, failureMessage)
    }
}

func haveProfile(_ sub: String) -> Predicate<AuthenticationResult<UserInfo>> {
    return Predicate<AuthenticationResult<UserInfo>>.define("have userInfo for sub: <\(sub)>") { expression, failureMessage -> PredicateResult in
        return try beSuccessful(expression, failureMessage) { (userInfo: UserInfo) -> Bool in userInfo.sub == sub }
    }
}

func haveObjectWithAttributes(_ attributes: [String]) -> Predicate<ManagementResult<[String: Any]>> {
    return Predicate<ManagementResult<[String: Any]>>.define("have attributes \(attributes)") { expression, failureMessage -> PredicateResult in
        return try beSuccessful(expression, failureMessage) { (value: [String: Any]) -> Bool in
            return Array(value.keys).reduce(true, { (initial, value) -> Bool in
                return initial && attributes.contains(value)
            })
        }
    }
}

func haveJWKS() -> Predicate<AuthenticationResult<JWKS>> {
    return Predicate<AuthenticationResult<JWKS>>.define("have a JWKS object with at least one key") { expression, failureMessage -> PredicateResult in
        return try beSuccessful(expression, failureMessage) { (jwks: JWKS) -> Bool in !jwks.keys.isEmpty }
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

// MARK: - Private Functions

private func beSuccessful<T, E>(_ expression: Expression<Result<T, E>>,
                                _ message: ExpectationMessage,
                                predicate: @escaping (T) -> Bool = { _ in true }) throws -> PredicateResult {
    if let actual = try expression.evaluate(), case .success(let value) = actual {
        return PredicateResult(bool: predicate(value), message: message)
    }
    return PredicateResult(status: .doesNotMatch, message: message)
}

private func beFailure<T, E>(_ expression: Expression<Result<T, E>>,
                             _ message: ExpectationMessage,
                             predicate: @escaping (E) -> Bool = { _ in true }) throws -> PredicateResult {
    if let actual = try expression.evaluate(), case .failure(let error) = actual {
        return PredicateResult(bool: predicate(error), message: message)
    }
    return PredicateResult(status: .doesNotMatch, message: message)
}

private func haveCredentials<E>(accessToken: String?,
                                idToken: String?,
                                refreshToken: String?,
                                _ expression: Expression<Result<Credentials, E>>,
                                _ message: ExpectationMessage) throws -> PredicateResult {
    if let accessToken = accessToken {
        _ = message.appended(message: " <access_token: \(accessToken)>")
    }
    if let idToken = idToken {
        _ = message.appended(message: " <id_token: \(idToken)>")
    }
    if let refreshToken = refreshToken {
        _ = message.appended(message: " <refresh_token: \(refreshToken)>")
    }
    return try beSuccessful(expression, message) { (credentials: Credentials) -> Bool in
        return (accessToken == nil || credentials.accessToken == accessToken)
            && (idToken == nil || credentials.idToken == idToken)
            && (refreshToken == nil || credentials.refreshToken == refreshToken)
    }
}

// MARK: - Extensions

extension URLRequest {

    var payload: [String: Any]? {
        return URLProtocol.property(forKey: parameterPropertyKey, in: self) as? [String: Any]
    }

}
