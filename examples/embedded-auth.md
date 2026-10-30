## Embedded Auth (iOS / macOS / tvOS / watchOS / visionOS) [Beta]

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/embeddedauth)**

- [Obtain a client](#obtain-a-client)
- [Start the flow and step through next actions](#start-the-flow-and-step-through-next-actions)
- [Username](#username)
- [Password](#password)
- [MFA flows](#mfa-flows)
- [Error handling during the flow](#error-handling-during-the-flow)

### Embedded Authorization flow

> [!IMPORTANT]
> The embedded authorization flow is currently in [Beta](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#beta). Please reach out to Auth0 support to get it enabled for your tenant and application.

#### Obtain a client

```swift
let client = Auth0.embeddedAuth()
```

> [!NOTE]
> `Auth0.embeddedAuth()` loads credentials from `Auth0.plist`. Supply them directly with `Auth0.embeddedAuth(clientId:domain:)`.

#### Start the flow and step through next actions

> [!NOTE]
> The Email OTP flow (`.challengeEmail` / `.verifyOTP`) is supported only for **existing users** who have already signed up. It does not work for fresh / new user sign-ups.

`authorize(connection:)` uses a default scope of `"openid profile email offline_access"`, which ensures `Credentials.idToken` is populated after a successful `verifyOtp` or `verifyPassword`. Pass a custom `scope:` to the full `authorize(connection:capabilities:scope:audience:)` overload if needed.

```swift
func runEmbeddedAuth(connection: String) async throws -> Credentials {
    do {
        // This always throws — read reason to know what to present.
        try await client.authorize(connection: connection).start()
        fatalError("authorize always throws on the first call")
    } catch let error as EmbeddedAuthError {
        guard case .insufficientAuthorization(_, let nextActions) = error.reason else {
            throw error
        }
        return try await handleNextActions(nextActions)
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
    case .identifyPhone:
        let phone = // … collect phone number from your UI …
        try await client.identify(phone, type: .phone).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .identifyUsername:
        let username = // … collect username from your UI …
        try await client.identify(username, type: .username).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .challengeEmail(let index, let identifier):
        // identifier is the masked destination, e.g. "al**@example.com".
        // index selects the user's authenticator — pass it back unchanged (it is not a position in `actions`).
        try await client.challengeEmail(index: index).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .challengePhone(let index, let identifier, let deliveryMethods):
        // Pick a delivery method from deliveryMethods and show identifier to the user
        let method = deliveryMethods.first ?? .text
        try await client.challengePhone(index: index, deliveryMethod: method).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .challengePush(let index, let name):
        // name is the display name of the push device, e.g. "Diego's iPhone"
        try await client.challengePush(index: index).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .verifyOTP(let channel, let identifier):
        let otp = // … collect OTP from your UI (shown at: identifier ?? "") …
        return try await client.verifyOtp(otp, type: channel == .totp ? .totp : .oob).start()
    case .verifyOob(let pollInMs):
        return try await pollForPushApproval(pollInMs: pollInMs)
    case .verifyPassword:
        let password = // … collect password from your UI …
        return try await client.verifyPassword(password).start()
    case .verifyRecoveryCode:
        let code = // … collect recovery code from your UI …
        try await client.verifyRecoveryCode(code).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .confirmRecoveryCode(let newCode):
        // Display newCode to the user so they can record it before continuing.
        return try await client.confirmRecoveryCode().start()
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
        case .failure(let error):
            if case .insufficientAuthorization(_, let nextActions) = error.reason,
               case .identifyEmail = nextActions.first {
                // Show email input
            } else {
                print("Failed with: \(error)")
            }
        }
    }
```
</details>

#### Username

When `nextActions` contains `.identifyUsername`, submit the username with `identify(_:type:)` and `.username`. It continues like the email and phone steps. `.verifyPassword` is the next step for a username, because the server requires a password for username sign-in.

The connection's username rules apply. A malformed username comes back as `.invalidRequest`, which ends the flow.

```swift
try await client.identify("alice", type: .username).start()
```

#### Password

When `nextActions` contains `.verifyPassword`, submit the user's password with `verifyPassword(_:)`. Like `verifyOtp`, it returns `Credentials` on success. If the user has to complete a second factor, it instead fails with `.insufficientAuthorization` and the MFA actions in `nextActions` (see below).

A wrong password fails with `.insufficientAuthorization(.invalidIdentifierOrPassword, nextActions)`. The flow stays live on a rotated session, and `nextActions` is `[.verifyPassword]` again, so show the error and present the password step once more. The server deliberately does not say whether the password or the user was wrong.

If a second factor is required but the user has no enrolled factor, `verifyPassword` fails with `.noEligibleFactors` after a correct password. The flow has ended: fall back to a redirect-based flow such as Universal Login.

An empty password is sent to the server like any other and comes back as `.invalidRequest`, which ends the flow. Disable the submit button while the field is empty.

After a wrong password the server offers only `.verifyPassword` again, never an identify step. To let the user correct the username or email, start a new flow with `authorize()`. Do not let the user retry endlessly: after several failures, offer a password reset or a different account.

```swift
func signIn(password: String) async throws -> Credentials {
    do {
        return try await client.verifyPassword(password).start()
    } catch let error as EmbeddedAuthError {
        switch error.reason {
        case .insufficientAuthorization(.invalidIdentifierOrPassword, let nextActions):
            // Show "incorrect username or password". nextActions is [.verifyPassword]: ask for the password again.
            return try await handleNextActions(nextActions)
        case .noEligibleFactors:
            // The password was right but a second factor is required and none is enrolled.
            throw error
        case .insufficientAuthorization(_, let nextActions):
            // Any other continuation, for example a second factor after the password.
            return try await handleNextActions(nextActions)
        default:
            throw error
        }
    }
}
```

#### MFA flows

After the primary factor succeeds the server may require a second factor. The `nextActions` in the continuation will include the user's eligible MFA factors. Handle them just like any other continuation step.

**Push notification (polling)**

```swift
func pollForPushApproval(pollInMs: Int) async throws -> Credentials {
    var intervalMs = pollInMs
    while true {
        // Wait before every poll, including the first: polling sooner than poll_in_ms is answered with slow_down.
        try await Task.sleep(nanoseconds: UInt64(intervalMs) * 1_000_000)
        do {
            return try await client.verifyOob().start()
        } catch let error as EmbeddedAuthError {
            switch error.reason {
            case .insufficientAuthorization(.authorizationPending, let next),
                 .insufficientAuthorization(.slowDown, let next):
                // Not approved yet, or polled too early. Use the interval from the latest
                // response — after slow_down it is longer than before.
                intervalMs = next.compactMap {
                    if case .verifyOob(let ms) = $0 { return ms } else { return nil }
                }.first ?? intervalMs
            default:
                throw error
            }
        }
    }
}
```

**Recovery code (with rotation)**

```swift
// Step 1: submit the current recovery code
do {
    try await client.verifyRecoveryCode(currentCode).start()
} catch let error as EmbeddedAuthError {
    if case .insufficientAuthorization(_, let next) = error.reason,
       case .confirmRecoveryCode(let newCode) = next.first {
        // Step 2: show newCode to the user so they record it
        showNewRecoveryCode(newCode)
        // Step 3: confirm and receive credentials
        let credentials = try await client.confirmRecoveryCode().start()
    }
}
```

#### Error handling during the flow

```swift
do {
    let credentials = try await client.verifyOtp(otp, type: .oob).start()
    // Use credentials
} catch let error as EmbeddedAuthError {
    switch error.reason {
    case .insufficientAuthorization(_, let nextActions):
        // Flow is still live — present the next action's UI.
        _ = nextActions
    case .challengeExpired:
        // The push challenge expired or was not found — the flow has ended, start over with authorize().
        break
    case .tooManyWrongOtpAttempts:
        // Too many wrong attempts — start over with authorize().
        break
    case .authorizationRejected:
        // Push notification was denied — start over with authorize().
        break
    case .noEligibleFactors:
        // User has no enrolled MFA factors — fall back to a redirect-based flow.
        break
    case .consentRequired:
        // Consent can't be collected in the embedded flow — sign in with a redirect-based flow such as Universal Login.
        break
    case .noNextSteps:
        // No further action is available — check the capabilities passed to authorize(), then start over.
        break
    case .passwordLeaked:
        // The password appears in a data breach — ask the user to choose a different password.
        break
    case .accessDenied:
        // Other terminal denial — start over with authorize().
        break
    case .tooManyAttempts, .tooManyLogins, .ipBlocked:
        // Rate-limited by attack protection — the flow has ended. Ask the user to try again later, then start over with authorize().
        break
    case .sessionExpired:
        // The grant expired — start over with authorize().
        break
    case .network:
        // Transient failure — retry the same step.
        break
    default:
        print("Failed with: \(error)")
    }
}
```

##### Retryable errors

`.insufficientAuthorization` carries a sub-reason that says why the server still needs input. All of them keep the flow live: the SDK switches to the rotated session, so the user can retry the step in `nextActions` without restarting.

| Server `error_description` | Sub-reason | When it is returned | What to do |
|---|---|---|---|
| `invalid_identifier_or_code` | `.invalidIdentifierOrCode` | The identifier or one-time code was rejected on the primary path. It is ambiguous on purpose, so a wrong code and an unknown user look the same. | Show a generic "incorrect code" message and let the user retry. |
| `invalid_code` | `.invalidCode` | A one-time code or recovery code was wrong for a user the server has already identified. | Let the user re-enter the code. |
| `authorization_pending` | `.authorizationPending` | The push notification has not been approved yet. | Wait for the `pollInMs` from `.verifyOob(pollInMs:)`, then call `verifyOob()` again. |
| `invalid_identifier_or_password` | `.invalidIdentifierOrPassword` | The identifier (email, phone or username) or the password was rejected. It is ambiguous on purpose, so a wrong password and an unknown user look the same. | Show a generic "incorrect username or password" message and present `nextActions` again; it holds `.verifyPassword`. |
| `slow_down` | `.slowDown` | `verifyOob()` was called before `pollInMs` elapsed. | Wait longer than before, then poll again. |

```swift
guard case .insufficientAuthorization(let subReason, let nextActions) = error.reason else {
    throw error
}
switch subReason {
case .invalidIdentifierOrCode, .invalidCode, .invalidIdentifierOrPassword:
    // The user entered something wrong — show an error and present nextActions again.
    break
case .authorizationPending, .slowDown:
    // Only returned while polling verifyOob() — see "Push notification (polling)".
    break
case .none:
    // A plain continuation — present nextActions.first.
    break
}
```

[Go up ⤴](../EXAMPLES.md#examples)
