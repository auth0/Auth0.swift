### MFA client configuration

#### Add custom parameters

Use the `parameters()` method to add custom parameters to any request.

```swift
Auth0
    .mfa()
    .verify(otp: "123456", mfaToken: mfaToken) // Any request
    .parameters(["key": "value"])
    // ...
```

#### Add custom headers

Use the `headers()` method to add custom headers to any request.

```swift
Auth0
    .mfa()
    .verify(otp: "123456", mfaToken: mfaToken) // Any request
    .headers(["key": "value"])
    // ...
```

#### Use a custom `URLSession` instance

You can specify a custom `URLSession` instance for more advanced networking configuration, such as customizing timeout values.

```swift
Auth0
    .mfa(session: customURLSession)
    // ...
```
