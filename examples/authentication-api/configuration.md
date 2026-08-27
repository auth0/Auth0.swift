### Authentication API client configuration

#### Add custom parameters

Use the `parameters()` method to add custom parameters to any request.

```swift
Auth0
    .authentication()
    .renew(withRefreshToken: credentials.refreshToken) // Any request
    .parameters(["key": "value"])
    // ...
```

#### Add custom headers

Use the `headers()` method to add custom headers to any request.

```swift
Auth0
    .authentication()
    .renew(withRefreshToken: credentials.refreshToken) // Any request
    .headers(["key": "value"])
    // ...
```

#### Use a custom `URLSession` instance

You can specify a custom `URLSession` instance for more advanced networking configuration, such as customizing timeout values.

```swift
Auth0
    .authentication(session: customURLSession)
    // ...
```
