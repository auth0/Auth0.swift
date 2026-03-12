import Foundation
import Combine

import os

/**
 A request wrapper for credential-returning authentication API calls.

 Returned by ``Authentication`` methods such as
 ``Authentication/codeExchange(withCode:codeVerifier:redirectURI:)``,
 ``Authentication/renew(withRefreshToken:audience:scope:)``,
 ``Authentication/ssoExchange(withRefreshToken:)``, and all `login` variants,
 as well as by ``MFAClient`` verification methods.

 Chain ``validateClaims()`` to opt in to ID token validation before calling ``start(_:)``.
 If the response contains an ID token (i.e. the result type is either ``Credentials`` or ``SSOCredentials``),
 it will be validated against the configured issuer and options.

 ## Usage

 ```swift
 Auth0
     .authentication()
     .renew(withRefreshToken: refreshToken)
     .validateClaims()
     .start { result in ... }
 ```

 To customise validation parameters:

 ```swift
 Auth0
     .authentication()
     .codeExchange(withCode: code, codeVerifier: verifier, redirectURI: redirectURI)
     .validateClaims()
     .withLeeway(120)                           // 2-minute clock skew
     .withIssuer("https://example.auth0.com/")
     .start { result in ... }
 ```
 */
public struct TokenRequest<T, E: Auth0APIError>: @unchecked Sendable {

    private let request: any Requestable<T, E>
    private let audience: String
    private let jwksRequest: any Requestable<JWKS, AuthenticationError>
    private let validateClaimsEnabled: Bool
    private let leeway: Int?
    private let issuer: String
    private let nonce: String?
    private let maxAge: Int?
    private let organization: String?

    init(request: any Requestable<T, E>, authentication: any Authentication) {
        self.init(request: request,
                  audience: authentication.clientId,
                  jwksRequest: authentication.jwks(),
                  validateClaimsEnabled: false,
                  leeway: nil,
                  issuer: authentication.url.absoluteString,
                  nonce: nil,
                  maxAge: nil,
                  organization: nil)
    }

    init(request: any Requestable<T, E>,
         audience: String,
         issuer: String,
         jwksRequest: any Requestable<JWKS, AuthenticationError>) {
        self.init(request: request,
                  audience: audience,
                  jwksRequest: jwksRequest,
                  validateClaimsEnabled: false,
                  leeway: nil,
                  issuer: issuer,
                  nonce: nil,
                  maxAge: nil,
                  organization: nil)
    }

    private init(request: any Requestable<T, E>,
                 audience: String,
                 jwksRequest: any Requestable<JWKS, AuthenticationError>,
                 validateClaimsEnabled: Bool,
                 leeway: Int?,
                 issuer: String,
                 nonce: String?,
                 maxAge: Int?,
                 organization: String?) {
        self.request = request
        self.audience = audience
        self.jwksRequest = jwksRequest
        self.validateClaimsEnabled = validateClaimsEnabled
        self.leeway = leeway
        self.issuer = issuer
        self.nonce = nonce
        self.maxAge = maxAge
        self.organization = organization
    }
}

// MARK: - TokenRequestable & Requestable

// TokenRequestable inherits Requestable, so one extension covers both.
extension TokenRequest: TokenRequestable {
    // MARK: TokenRequestable

    public func validateClaims() -> any TokenRequestable<T, E> {
        TokenRequest(request: request,
                     audience: audience,
                     jwksRequest: jwksRequest,
                     validateClaimsEnabled: true,
                     leeway: leeway,
                     issuer: issuer,
                     nonce: nonce,
                     maxAge: maxAge,
                     organization: organization)
    }

    public func withLeeway(_ leeway: Int) -> any TokenRequestable<T, E> {
        TokenRequest(request: request,
                     audience: audience,
                     jwksRequest: jwksRequest,
                     validateClaimsEnabled: validateClaimsEnabled,
                     leeway: leeway,
                     issuer: issuer,
                     nonce: nonce,
                     maxAge: maxAge,
                     organization: organization)
    }

    public func withIssuer(_ issuer: String) -> any TokenRequestable<T, E> {
        TokenRequest(request: request,
                     audience: audience,
                     jwksRequest: jwksRequest,
                     validateClaimsEnabled: validateClaimsEnabled,
                     leeway: leeway,
                     issuer: issuer,
                     nonce: nonce,
                     maxAge: maxAge,
                     organization: organization)
    }

    public func withNonce(_ nonce: String?) -> any TokenRequestable<T, E> {
        TokenRequest(request: request,
                     audience: audience,
                     jwksRequest: jwksRequest,
                     validateClaimsEnabled: validateClaimsEnabled,
                     leeway: leeway,
                     issuer: issuer,
                     nonce: nonce,
                     maxAge: maxAge,
                     organization: organization)
    }

    public func withMaxAge(_ maxAge: Int?) -> any TokenRequestable<T, E> {
        TokenRequest(request: request,
                     audience: audience,
                     jwksRequest: jwksRequest,
                     validateClaimsEnabled: validateClaimsEnabled,
                     leeway: leeway,
                     issuer: issuer,
                     nonce: nonce,
                     maxAge: maxAge,
                     organization: organization)
    }

    public func withOrganization(_ organization: String?) -> any TokenRequestable<T, E> {
        TokenRequest(request: request,
                     audience: audience,
                     jwksRequest: jwksRequest,
                     validateClaimsEnabled: validateClaimsEnabled,
                     leeway: leeway,
                     issuer: issuer,
                     nonce: nonce,
                     maxAge: maxAge,
                     organization: organization)
    }

    // MARK: Requestable

    public func start(_ callback: @escaping (Result<T, E>) -> Void) {
        request.start { result in
            switch result {
            case .success(let value):
                if self.validateClaimsEnabled {
                    guard let carrier = value as? any IDTokenCarrying else { return callback(result) }
                    guard !carrier.idToken.isEmpty else {
                        return callback(.failure(E(cause: IDTokenDecodingError.missingIDToken)))
                    }
                    self.verifyClaims(idToken: carrier.idToken) { error in
                        if let error = error {
                            callback(.failure(E(cause: error)))
                        } else {
                            callback(.success(value))
                        }
                    }
                } else {
                    callback(result)
                }
            case .failure:
                callback(result)
            }
        }
    }

    public func parameters(_ extraParameters: [String: Any]) -> any Requestable<T, E> {
        TokenRequest(request: request.parameters(extraParameters),
                     audience: audience,
                     jwksRequest: jwksRequest,
                     validateClaimsEnabled: validateClaimsEnabled,
                     leeway: leeway,
                     issuer: issuer,
                     nonce: nonce,
                     maxAge: maxAge,
                     organization: organization)
    }

    public func headers(_ extraHeaders: [String: String]) -> any Requestable<T, E> {
        TokenRequest(request: request.headers(extraHeaders),
                     audience: audience,
                     jwksRequest: jwksRequest,
                     validateClaimsEnabled: validateClaimsEnabled,
                     leeway: leeway,
                     issuer: issuer,
                     nonce: nonce,
                     maxAge: maxAge,
                     organization: organization)
    }

    public func requestValidators(_ extraValidators: [RequestValidator]) -> any Requestable<T, E> {
        TokenRequest(request: request.requestValidators(extraValidators),
                     audience: audience,
                     jwksRequest: jwksRequest,
                     validateClaimsEnabled: validateClaimsEnabled,
                     leeway: leeway,
                     issuer: issuer,
                     nonce: nonce,
                     maxAge: maxAge,
                     organization: organization)
    }
}

// MARK: - Private

private extension TokenRequest {
    func verifyClaims(idToken: String, callback: @escaping (Error?) -> Void) {
        let context = IDTokenValidatorContext(
            issuer: issuer,
            audience: audience,
            jwksRequest: jwksRequest,
            leeway: leeway ?? 60,
            maxAge: maxAge,
            nonce: nonce,
            organization: organization
        )
        validate(idToken: idToken, with: context, callback: callback)
    }
}
