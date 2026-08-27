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

[Go up ⤴](../../EXAMPLES.md)
