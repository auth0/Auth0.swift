### ID token validation

Auth0.swift automatically [validates](https://auth0.com/docs/secure/tokens/id-tokens/validate-id-tokens) the ID token obtained from Web Auth login, following the [OpenID Connect specification](https://openid.net/specs/openid-connect-core-1_0.html). This ensures the contents of the ID token have not been tampered with and can be safely used.

For direct Authentication API calls (`login`, `renew`, `codeExchange`, etc.) and MFA verification calls, ID token validation is **opt-in**. All credential-returning methods return `any TokenRequestable`, and you can chain `.validateClaims()` before `.start(_:)` to enable it:

```swift
Auth0
    .authentication()
    .renew(withRefreshToken: credentials.refreshToken)
    .validateClaims()
    .start { result in
        switch result {
        case .success(let credentials): print("Renewed: \(credentials)")
        case .failure(let error): print("Error: \(error)")
        }
    }
```

You can customise the validation by chaining additional modifiers after `validateClaims()`:

```swift
Auth0
    .authentication()
    .codeExchange(withCode: code, codeVerifier: verifier, redirectURI: redirectURI)
    .validateClaims()
    .withLeeway(120)                            // clock-skew tolerance in seconds
    .withNonce(nonce)                           // expected nonce claim
    .withOrganization("org_abc123")             // expected org_id or org_name claim
    .start { result in ... }
```

The same API is available on MFA verification:

```swift
Auth0
    .mfa()
    .verify(otp: otp, mfaToken: mfaToken)
    .validateClaims()
    .start { result in ... }
```
