### MFA client errors

The MFA client produces specific error types for different operations, all conforming to the `Auth0APIError` protocol:

- **`MfaListAuthenticatorsError`**: Returned by `getAuthenticators()` when listing authenticators fails
- **`MfaEnrollmentError`**: Returned by all `enroll()` methods when enrollment fails
- **`MfaChallengeError`**: Returned by `challenge()` when initiating a challenge fails
- **`MFAVerifyError`**: Returned by all `verify()` methods when verification fails

All MFA error types provide:
- `code`: The error code from the API response
- `statusCode`: The HTTP status code
- `info`: Raw error information dictionary
- `localizedDescription`: A human-readable error description (inherited from `LocalizedError`)
- `debugDescription`: A detailed description for debugging purposes
- `cause`: The underlying `Error` value, if any (useful for network errors)
- `isNetworkError`: Whether the request failed due to network issues
- `isRetryable`: Whether the error is retryable (network errors, rate limiting, or server errors)

#### Example error handling

```swift
Auth0
    .mfa()
    .verify(otp: "123456", mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Success: \(credentials)")
        case .failure(let error):
            print("Failed with code: \(error.code)")
            print("Description: \(error.localizedDescription)")
            print("Status code: \(error.statusCode)")
        }
    }
```

#### Common error codes

Each MFA error type provides specific error codes to help you handle different scenarios:

**MfaListAuthenticatorsError** (from `getAuthenticators()`):
- `invalid_request`: Request parameters are invalid (e.g., missing or empty factorsAllowed)
- `invalid_token`: MFA token is invalid or expired
- `access_denied`: User lacks permission to access this resource

**MfaEnrollmentError** (from `enroll()` methods):
- `invalid_request`: Enrollment parameters are invalid
- `invalid_token`: MFA token is invalid or expired
- `enrollment_conflict`: Authenticator is already enrolled
- `unsupported_challenge_type`: Requested factor type is not enabled

**MfaChallengeError** (from `challenge()`):
- `invalid_request`: Challenge parameters are invalid
- `invalid_token`: MFA token is invalid or expired
- `authenticator_not_found`: Specified authenticator doesn't exist
- `unsupported_challenge_type`: Authenticator type doesn't support challenges

**MFAVerifyError** (from `verify()` methods):
- `invalid_grant`: Verification code is incorrect or expired
- `invalid_token`: MFA token is invalid or expired
- `invalid_oob_code`: Out-of-band code is invalid
- `invalid_binding_code`: Binding code (SMS/email code) is incorrect
- `expired_token`: Verification code has expired

#### Handling specific error cases

You can check the `code` property to handle specific error scenarios:

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken, phoneNumber: "+12025550135")
    .start { result in
        switch result {
        case .success(let challenge):
            print("Enrollment successful")
        case .failure(let error):
            switch error.code {
            case "invalid_token":
                print("MFA token is invalid or expired")
            case "invalid_phone_number":
                print("Phone number format is invalid")
            case "unsupported_challenge_type":
                print("This MFA factor is not supported")
            default:
                print("Enrollment failed: \(error.localizedDescription)")
            }
        }
    }
```

#### Network and retryable errors

MFA errors inherit `isNetworkError` and `isRetryable` properties from `Auth0APIError` to help handle transient failures:

```swift
Auth0
    .mfa()
    .verify(otp: "123456", mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Success: \(credentials)")
        case .failure(let error):
            if error.isNetworkError {
                print("Network connectivity issue - check your connection")
            } else if error.isRetryable {
                print("Request can be retried (rate limiting or server error)")
            } else {
                print("Permanent error: \(error.localizedDescription)")
            }
        }
    }
```

The `isNetworkError` property returns `true` for network-related failures such as:
- No internet connection
- DNS lookup failures
- Connection timeouts
- Data not allowed

The `isRetryable` property returns `true` for errors that can be retried:
- Network errors (as determined by `isNetworkError`)
- Rate limiting errors (HTTP 429)
- Server errors (HTTP 5xx)

#### Authentication flow errors

When handling MFA-required errors from the authentication flow (not the MFA client), you'll still receive `AuthenticationError` values. Use these properties to identify MFA-related scenarios:

- `isMultifactorRequired`: MFA is required to authenticate
- `isMultifactorEnrollRequired`: MFA is required and the user is not enrolled
- `isMultifactorCodeInvalid`: The MFA code sent is invalid or expired (legacy)
- `isMultifactorTokenInvalid`: The MFA token is invalid or expired (legacy)

```swift
Auth0
    .authentication()
    .login(usernameOrEmail: "user@example.com", password: "password", realmOrConnection: "Username-Password-Authentication")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Success: \(credentials)")
        case .failure(let error) where error.isMultifactorRequired:
            print("MFA is required")
            // Extract mfaToken and proceed with MFA flow
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

Check the [Auth0APIError API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/auth0apierror) and [AuthenticationError API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/authenticationerror) to learn more about error handling.

> [!WARNING]
> Do not parse or otherwise rely on the error messages to handle the errors. The error messages are not part of the API and can change. Use the error `code` property and error types instead, which are part of the API.

[Go up ⤴](../../EXAMPLES.md)
