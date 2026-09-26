# ID Token Validation

Validate ID token claims on credential-returning Authentication API requests.

## Overview

Methods on ``Authentication`` and ``MFAClient`` that return credentials (`login`, `renew`, `codeExchange`, `ssoExchange`, `verify`, and similar) return `any ``TokenRequestable``` instead of a plain `Requestable`. The concrete type returned is ``TokenRequest``, which conforms to ``TokenRequestable``. You can chain ``TokenRequestable/validateClaims()`` on the returned request before calling `start(_:)` to verify the ID token's claims.

> Note: ID token validation is only performed when the response contains a non-empty ID token (i.e. the result type is ``Credentials`` and ``SSOCredentials`` do). Embedded login is available for all the platforms. Hence IDTokenValidation would also be available for all platforms.

## Basic usage

```swift
Auth0
    .authentication()
    .renew(withRefreshToken: credentials.refreshToken)
    .validateClaims()
    .start { result in
        switch result {
        case .success(let credentials):
            print("Renewed credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

## Customising validation parameters

You can override individual validation options by chaining the corresponding modifiers **after** `validateClaims()`:

| Modifier | Default | Description |
| --- | --- | --- |
| `withLeeway(_:)` | `60_000` ms | Allowed clock-skew tolerance for `exp`, `iat`, and `auth_time`. |
| `withIssuer(_:)` | Auth0 domain URL | Expected `iss` claim value. |
| `withNonce(_:)` | `nil` (skip) | Expected `nonce` claim value. |
| `withMaxAge(_:)` | `nil` (skip) | Maximum elapsed seconds since last authentication (`auth_time`). |
| `withOrganization(_:)` | `nil` (skip) | Expected `org_id` or `org_name` claim value. |

```swift
Auth0
    .authentication()
    .codeExchange(withCode: code,
                  codeVerifier: codeVerifier,
                  redirectURI: redirectURI)
    .validateClaims()
    .withLeeway(120_000)
    .withNonce(nonce)
    .start { result in ... }
```

## MFA verify requests

MFA verification methods on ``MFAClient`` follow the same pattern:

```swift
mfaClient
    .verify(otp: otp, mfaToken: mfaToken)
    .validateClaims()
    .start { result in ... }
```

## Web Auth (PKCE)

When using ``WebAuth``, ID token validation is performed automatically — you do not need to call `validateClaims()` yourself. The PKCE flow validates the ID token using the nonce, issuer, leeway, and organisation values configured on the ``WebAuth`` builder.

## See Also

- ``TokenRequestable``
- ``TokenRequest``
- ``Authentication``
- ``MFAClient``
