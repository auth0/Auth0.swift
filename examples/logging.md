## Logging

Auth0.swift provides comprehensive logging capabilities for debugging HTTP requests and responses. The logging system is built on Apple's [Unified Logging](https://developer.apple.com/documentation/os/logging) (`OSLog`) for better performance and integration with system diagnostic tools.

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

### Automatic Token Redaction

**Security First**: Auth0.swift automatically redacts sensitive information from logs to protect user credentials. The following fields are redacted when logging HTTP responses:

- `access_token`
- `refresh_token`
- `id_token`

Redacted tokens appear as `"redacted"` in the logs, ensuring sensitive data never appears in plain text.

### Logging Output

With logging enabled, you'll see detailed HTTP request and response information. Here's an example of what a successful authentication flow looks like:

```text
ASWebAuthenticationSession: https://example.us.auth0.com/authorize?.....
Callback URL: com.example.MyApp://example.us.auth0.com/ios/com.example.MyApp/callback?...

POST https://example.us.auth0.com/oauth/token HTTP/1.1
Content-Type: application/json
Auth0-Client: eyJ2ZXJzaW9uI...

{
  "code": "...",
  "client_id": "...",
  "grant_type": "authorization_code",
  "redirect_uri": "com.example.MyApp://example.us.auth0.com/ios/com.example.MyApp/callback",
  "code_verifier": "..."
}

HTTP/1.1 200
Pragma: no-cache
Content-Type: application/json
Strict-Transport-Security: max-age=3600
Date: Wed, 08 Dec 2025 10:30:00 GMT
Content-Length: 1024
Cache-Control: no-cache
Connection: keep-alive

{
  "access_token": "redacted",
  "refresh_token": "redacted",
  "id_token": "redacted",
  "token_type": "Bearer",
  "expires_in": 86400
}
```

### Viewing Logs

Auth0.swift logs are written to the **Unified Logging System** with the following identifiers:

- **Subsystem**: `com.auth0.Auth0`
- **Categories**: `NetworkTracing`, `Configuration`

#### Xcode Console (Recommended)

Logs appear automatically in the Xcode debug console during development on all platforms.

**Filtering in Xcode 15+:**

Use these filter expressions directly in the console search bar:

| Filter | Description |
|--------|-------------|
| `subsystem:com.auth0.Auth0` | Show all Auth0 SDK logs |
| `category:NetworkTracing` | Show only network requests/responses |
| `category:Configuration` | Show only configuration errors |
| `subsystem:com.auth0.Auth0 category:NetworkTracing` | Combine filters for specific logs |

#### Log Categories

- **NetworkTracing** - HTTP requests and responses (enabled via `logging(enabled: true)`)
- **Configuration** - SDK setup and configuration issues (always logged)

> [!TIP]
> When troubleshooting, you can also check the logs in the [Auth0 Dashboard](https://manage.auth0.com/#/logs) for more information.

[Go up ⤴](../EXAMPLES.md#examples)
