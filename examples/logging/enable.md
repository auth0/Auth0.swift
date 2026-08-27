### Enable Logging

Enable logging by calling the `logging(enabled:)` method on any Auth0.swift client that conforms to `Loggable` (e.g. `Authentication`, `MFAClient`, `MyAccountClient`, or `WebAuth`):

```swift
Auth0
    .webAuth()
    .logging(enabled: true)
    // ...
```

```swift
Auth0
    .authentication()
    .logging(enabled: true)
    // ...
```

> [!CAUTION]
> Enable logging **only when debugging** to avoid performance impacts and potential security concerns in production builds.
