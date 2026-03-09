// swiftlint:disable file_length
// swiftlint:disable function_parameter_count

import Foundation
import Combine

import os

/**
 A request wrapper for credential-returning authentication API calls.

 Returned by ``Authentication`` methods such as
 ``Authentication/codeExchange(withCode:codeVerifier:redirectURI:)``,
 ``Authentication/renew(withRefreshToken:audience:scope:)``,
 ``Authentication/ssoExchange(withRefreshToken:)``, and all `login` variants.

 Chain ``validateClaims()`` to opt in to ID token validation before calling ``start(_:)``.
 If the response contains an ID token (i.e. the result type conforms to ``IDTokenProtocol``),
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
     .withLeeway(120_000)                      // 2-minute clock skew
     .withIssuer("https://example.auth0.com/")
     .start { result in ... }
 ```
 */
public struct BaseAuthenticationRequest<T, E: Auth0APIError>: @unchecked Sendable {

    private var request: any Requestable<T, E>
    private let authentication: any Authentication

    private var validateClaimsEnabled: Bool = false
    private var leeway: Int?
    private var issuer: String
    private var nonce: String?
    private var maxAge: Int?
    private var organization: String?

    init(request: any Requestable<T, E>, authentication: any Authentication) {
        self.request = request
        self.authentication = authentication
        self.issuer = authentication.url.absoluteString
    }

    /// Forwards the DPoP instance from the underlying ``Request``, if present.
    /// Exposed for test inspection and debugging only.
    var dpop: DPoP? {
        return (request as? Request<T, E>)?.dpop
    }
}

// MARK: - Claim validation options

public extension BaseAuthenticationRequest {

    /**
     Enables ID token validation for this request.

     When called, the ID token returned in the response (if present and conforming to ``IDTokenProtocol``)
     will be validated before the result is delivered to the caller.

     - Returns: A copy of the request with claim validation enabled.
     */
    func validateClaims() -> BaseAuthenticationRequest<T, E> {
        var copy = self
        copy.validateClaimsEnabled = true
        return copy
    }

    /**
     Overrides the clock-skew tolerance used during ID token validation.

     - Parameter leeway: Allowed clock skew in **milliseconds**. Defaults to 60,000 (60 s).
     - Returns: A copy of the request with the leeway applied.
     */
    func withLeeway(_ leeway: Int) -> BaseAuthenticationRequest<T, E> {
        var copy = self
        copy.leeway = leeway
        return copy
    }

    /**
     Overrides the expected `iss` claim used during ID token validation.

     Defaults to the Auth0 domain URL (e.g. `https://your-domain.auth0.com/`).

     - Parameter issuer: The expected issuer string.
     - Returns: A copy of the request with the issuer applied.
     */
    func withIssuer(_ issuer: String) -> BaseAuthenticationRequest<T, E> {
        var copy = self
        copy.issuer = issuer
        return copy
    }

    /**
     Sets the expected `nonce` claim for ID token validation.

     - Parameter nonce: The nonce value to expect. Pass `nil` to skip nonce validation.
     - Returns: A copy of the request with the nonce applied.
     */
    func withNonce(_ nonce: String?) -> BaseAuthenticationRequest<T, E> {
        var copy = self
        copy.nonce = nonce
        return copy
    }

    /**
     Sets the maximum authentication age for ID token validation.

     - Parameter maxAge: Maximum elapsed seconds since last authentication. Validates the `auth_time` claim.
     - Returns: A copy of the request with the maxAge applied.
     */
    func withMaxAge(_ maxAge: Int?) -> BaseAuthenticationRequest<T, E> {
        var copy = self
        copy.maxAge = maxAge
        return copy
    }

    /**
     Sets the expected organization (`org_id` or `org_name`) claim for ID token validation.

     - Parameter organization: The organization value to expect.
     - Returns: A copy of the request with the organization applied.
     */
    func withOrganization(_ organization: String?) -> BaseAuthenticationRequest<T, E> {
        var copy = self
        copy.organization = organization
        return copy
    }
}

// MARK: - Requestable

extension BaseAuthenticationRequest: Requestable {

    public func start(_ callback: @escaping (Result<T, E>) -> Void) {
        if validateClaimsEnabled {
            request.start { result in
                guard case .success(let value) = result,
                      let carrier = value as? any IDTokenProtocol,
                      !carrier.idToken.isEmpty else {
                    return callback(result)
                }
                self.verifyClaims(idToken: carrier.idToken) { error in
                    if let error = error {
                        callback(.failure(E(cause: error)))
                    } else {
                        callback(.success(value))
                    }
                }
            }
            return
        }
        request.start(callback)
    }

    public func parameters(_ extraParameters: [String: Any]) -> any Requestable<T, E> {
        var copy = self
        copy.request = request.parameters(extraParameters)
        return copy
    }

    public func headers(_ extraHeaders: [String: String]) -> any Requestable<T, E> {
        var copy = self
        copy.request = request.headers(extraHeaders)
        return copy
    }

    public func requestValidators(_ extraValidators: [RequestValidator]) -> any Requestable<T, E> {
        var copy = self
        copy.request = request.requestValidators(extraValidators)
        return copy
    }
}

// MARK: - Private

private extension BaseAuthenticationRequest {
    func verifyClaims(idToken: String, callback: @escaping (Error?) -> Void) {
        let context = IDTokenValidatorContext(
            authentication: authentication,
            issuer: issuer,
            leeway: leeway ?? 60 * 1000,
            maxAge: maxAge,
            nonce: nonce,
            organization: organization
        )
        validate(idToken: idToken, with: context, callback: callback)
    }
}
