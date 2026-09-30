## Embedded Auth (iOS / macOS / tvOS / watchOS / visionOS) [Beta]

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/embeddedauth)**

- [Obtain a client](#obtain-a-client)
- [Start the flow and step through next actions](#start-the-flow-and-step-through-next-actions)
- [Error handling during the flow](#error-handling-during-the-flow)

### Embedded Authorization flow

> [!IMPORTANT]
> The embedded authorization flow is currently in [Beta](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#beta). Please reach out to Auth0 support to get it enabled for your tenant and application.

The `EmbeddedAuth` client runs the interactive `POST /e/authorize` loop. Each step returns an error whose `nextActions` array tells you what to present next. When `verifyOtp` succeeds, `Credentials` are returned directly — no manual code exchange required.

#### Obtain a client

```swift
let client = Auth0.embeddedAuth()
```

> [!NOTE]
> `Auth0.embeddedAuth()` loads credentials from `Auth0.plist`. Supply them directly with `Auth0.embeddedAuth(clientId:domain:)`.

#### Start the flow and step through next actions

`authorize(connection:)` uses a default scope of `"openid profile email offline_access"`, which ensures `Credentials.idToken` is populated after a successful `verifyOtp`. Pass a custom `scope:` to the full `authorize(connection:capabilities:scope:audience:)` overload if needed.

```swift
func runEmbeddedAuth(connection: String) async throws -> Credentials {
    do {
        // This always throws — read nextActions to know what to present.
        try await client.authorize(connection: connection).start()
        fatalError("authorize always throws on the first call")
    } catch let error as EmbeddedAuthError where error.isInsufficientAuthorization {
        return try await handleNextActions(error.nextActions)
    }
}

func handleNextActions(_ actions: [NextAction]) async throws -> Credentials {
    guard let action = actions.first else {
        throw EmbeddedAuthError(info: ["error": "no_next_steps"], statusCode: 0)
    }
    switch action {
    case .identifyEmail:
        let email = // … collect email from your UI …
        try await client.identify(email, type: .email).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .challengeEmail(let index, let identifier):
        // identifier is the masked destination, e.g. "al**@example.com"
        try await client.challengeEmail(index: index).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .verifyOTP(let channel, let identifier):
        let otp = // … collect OTP from your UI (shown at: identifier ?? "") …
        return try await client.verifyOtp(otp, type: channel == .totp ? .totp : .oob).start()
    case .unknown:
        throw EmbeddedAuthError(info: ["error": "unsupported_action"], statusCode: 0)
    }
}
```

<details>
  <summary>Using callbacks</summary>

```swift
Auth0.embeddedAuth()
    .authorize(connection: "my-connection")
    .start { result in
        switch result {
        case .success:
            // authorize() always fails on the first call — unreachable in practice
            break
        case .failure(let error) where error.isInsufficientAuthorization:
            // Read error.nextActions and present the first action's UI
            if case .identifyEmail = error.nextActions.first {
                // Show email input
            }
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```
</details>

#### Error handling during the flow

```swift
do {
    let credentials = try await client.verifyOtp(otp, type: .oob).start()
    // Use credentials
} catch let error as EmbeddedAuthError where error.isInvalidCode {
    // Wrong OTP — session is still alive, let the user retry
} catch let error as EmbeddedAuthError where error.isChallengeExpired {
    // Challenge timed out — call challengeEmail again
} catch let error as EmbeddedAuthError where error.isTooManyWrongOtpAttempts {
    // Too many wrong attempts — start over with authorize()
} catch let error as EmbeddedAuthError where error.isTooManyAttempts {
    // Rate-limited — ask the user to wait and retry
} catch let error as EmbeddedAuthError {
    print("Failed with: \(error)")
}
```

[Go up ⤴](../EXAMPLES.md#examples)
