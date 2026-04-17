import Foundation
import Combine
/**
 A request that supports opt-in ID token claim validation via a chainable builder API.

 Returned by credential-producing methods on ``Authentication`` and ``MFAClient``.
 Chain ``validateClaims()`` before calling ``Requestable/start(_:)`` to validate the
 ID token in the response.

 ## Usage

 ```swift
 Auth0.mfa()
     .verify(otp: "123456", mfaToken: mfaToken)
     .validateClaims()
     .withLeeway(120)
     .start { result in ... }
 ```
 */
public protocol TokenRequestable<ResultType, ErrorType>: Requestable {

    /**
     Enables ID token validation for this request.

     When called, the ID token returned in the response (if present and conforming to ``IDTokenCarrying``)
     will be validated before the result is delivered to the caller.

     - Returns: A copy of the request with claim validation enabled.
     */
    func validateClaims() -> any TokenRequestable<ResultType, ErrorType>

    /**
     Overrides the clock-skew tolerance used during ID token validation.

     - Parameter leeway: Allowed clock skew in **seconds**. Defaults to 60.
     - Returns: A copy of the request with the leeway applied.
     */
    func withLeeway(_ leeway: Int) -> any TokenRequestable<ResultType, ErrorType>

    /**
     Overrides the expected `iss` claim used during ID token validation.

     Defaults to the Auth0 domain URL (e.g. `https://your-domain.auth0.com/`).

     - Parameter issuer: The expected issuer string.
     - Returns: A copy of the request with the issuer applied.
     */
    func withIssuer(_ issuer: String) -> any TokenRequestable<ResultType, ErrorType>

    /**
     Sets the expected `nonce` claim for ID token validation.

     - Parameter nonce: The nonce value to expect. Pass `nil` to skip nonce validation.
     - Returns: A copy of the request with the nonce applied.
     */
    func withNonce(_ nonce: String?) -> any TokenRequestable<ResultType, ErrorType>

    /**
     Sets the maximum authentication age for ID token validation.

     - Parameter maxAge: Maximum elapsed seconds since last authentication. Validates the `auth_time` claim.
     - Returns: A copy of the request with the maxAge applied.
     */
    func withMaxAge(_ maxAge: Int?) -> any TokenRequestable<ResultType, ErrorType>

    /**
     Sets the expected organization (`org_id` or `org_name`) claim for ID token validation.

     - Parameter organization: The organization value to expect.
     - Returns: A copy of the request with the organization applied.
     */
    func withOrganization(_ organization: String?) -> any TokenRequestable<ResultType, ErrorType>

    // MARK: - Requestable

    /**
     Executes the request and delivers the result to the callback.

     - Parameter callback: Called on completion with a `Result` containing either the decoded value or an error.
     */
    func start(_ callback: @escaping @MainActor (Result<ResultType, ErrorType>) -> Void)

    /**
     Returns a new request with the given parameters merged into the request body.

     - Parameter extraParameters: Key-value pairs to add to the request.
     - Returns: A new `Requestable` with the parameters applied.
     */
    func parameters(_ extraParameters: [String: Any]) -> any Requestable<ResultType, ErrorType>

    /**
     Returns a new request with the given headers merged into the request headers.

     - Parameter extraHeaders: Key-value pairs to add to the request headers.
     - Returns: A new `Requestable` with the headers applied.
     */
    func headers(_ extraHeaders: [String: String]) -> any Requestable<ResultType, ErrorType>

    /**
     Returns a new request with the given validators appended to the validation chain.

     - Parameter extraValidators: Validators to run against the response before delivering the result.
     - Returns: A new `Requestable` with the validators applied.
     */
    func requestValidators(_ extraValidators: [RequestValidator]) -> any Requestable<ResultType, ErrorType>
}

// MARK: - Combine

public extension TokenRequestable {

    /**
     Combine publisher for the request.

     - Returns: A type-erased publisher.
     */
    func start() -> AnyPublisher<ResultType, ErrorType> {
        return Deferred { Future { [self] promise in
            let box = SendableBox(value: promise)
            self.start { result in box.value(result) }
        } }.eraseToAnyPublisher()
    }

}

// MARK: - Async/Await

#if canImport(_Concurrency)
public extension TokenRequestable {

    /**
     Performs the request.

     - Throws: An error that conforms to ``Auth0APIError``.
     */
    func start() async throws -> ResultType where ResultType: Sendable {
        return try await withCheckedThrowingContinuation { continuation in
            self.start { @Sendable result in
                continuation.resume(with: result)
            }
        }
    }

}
#endif
