## Embedded Auth (iOS / macOS / tvOS / watchOS / visionOS) [Beta]

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/embeddedauth)**

- [Obtain a client](#obtain-a-client)
- [Start the flow and step through next actions](#start-the-flow-and-step-through-next-actions)
- [Username](#username)
- [Password](#password)
- [Passkey](#passkey)
- [Sign up](#sign-up)
- [Sign up with a password](#sign-up-with-a-password)
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
> Sign-in with an email OTP (`.challengeEmail` / `.verifyOTP`) is for **existing users**. New users register through the [sign-up](#sign-up) steps (`.signup` / `.confirmSignup`), which reuse the same identify, challenge and verify steps and which the server offers only when the connection allows self-registration.

> [!NOTE]
> New next actions can be added in future releases, and `.signup` / `.confirmSignup` and `.verifyPasskey` were added during the v4 beta, as were the `.invalidPasskey` sub-reason and the `.invalidInput` error reason. If you switch over `NextAction`, `EmbeddedCapability` or `EmbeddedAuthErrorReason`, keep a `default:` branch (or handle `.unknown`) so new cases don't break your build. The passkey cases, `.verifyPasskey` and `.invalidPasskey`, exist only where passkeys are supported (iOS, macOS, Mac Catalyst and visionOS). If your app also targets tvOS or watchOS, wrap the code that names them in `#if !os(tvOS) && !os(watchOS)`.

> [!IMPORTANT]
> Choose the step to present by the **type** of the entry in `nextActions`, never by its **position**, and always handle the other entries too. The order is up to the server, and `authorize(connection:)` now advertises passkey sign-in where the platform supports it, so a passkey entry can appear next to the identify steps. See [Passkey](#passkey).

`authorize(connection:)` uses a default scope of `"openid profile email offline_access"`, which ensures `Credentials.idToken` is populated after a successful `verifyOtp` or `verifyPassword`. Pass a custom `scope:` to the full `authorize(connection:capabilities:scope:audience:)` overload if needed. `openid` is added to a custom scope that lacks it, because the SDK validates the ID token.

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
    // Choose the step by its type, never by its position: the order of `actions` is up to the server.
    // Here the app prefers a passkey when it is offered, and otherwise takes the first entry it can present.
    #if os(tvOS) || os(watchOS)
    let preferred = actions.first // There are no passkeys on tvOS and watchOS.
    #else
    let preferred = actions.first { if case .verifyPasskey = $0 { return true } else { return false } } ?? actions.first
    #endif
    guard let action = preferred else {
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
    case .signup(let identifiers, let passwordRequirement):
        // The server offers to register a new user. identifiers lists the identifiers it accepts
        // and whether each is required. passwordRequirement says whether a password will be asked for
        // at the end: .none, .optional or .required. Call signup() only if the user chose to create an account.
        try await client.signup().start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .confirmSignup(let password):
        // The registration steps are complete. This finishes the sign-up and signs the user in.
        // password is nil when the connection does not collect one. Otherwise ask the user for it,
        // see "Sign up with a password".
        var entered: String?
        if let password {
            // Your own UI. Return nil to skip the password when !password.isRequired.
            entered = await askUserForPassword(rules: password.complexity, isRequired: password.isRequired)
        }
        return try await client.confirmSignup(password: entered).start()
    #if !os(tvOS) && !os(watchOS)
    case .verifyPasskey(let options, _):
        // This case doesn't exist on tvOS and watchOS. Passkey sign-in needs iOS 16.6+, macOS 13.5+ or
        // visionOS 1.0+. See the "Passkey" section.
        if #available(iOS 16.6, macOS 13.5, visionOS 1.0, *) {
            return try await signInWithPasskey(options: options, otherActions: actions)
        }
        // On an older OS passkeys aren't available: use another entry instead.
        return try await handleNextActions(actions.filter { if case .verifyPasskey = $0 { return false } else { return true } })
    #endif
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
               nextActions.contains(.identifyEmail) {
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

#### Passkey

When `nextActions` contains `.verifyPasskey(options:requestJson:)`, the server offers to sign the user in with a passkey. A passkey identifies and verifies the user in one step, so it is offered in the first `nextActions`, next to the identify steps, and the identify steps are always offered alongside it as a fallback. Show the system passkey UI, then pass the result to `verifyPasskey(_:)`. Like `verifyPassword`, it returns `Credentials` on success. The SDK doesn't show any UI: that is up to your app.

Passkey sign-in is available on iOS 16.6+, macOS 13.5+ (including Mac Catalyst) and visionOS 1.0+. On tvOS and watchOS the passkey API doesn't exist: `verifyPasskey(_:)`, `NextAction.verifyPasskey`, `EmbeddedCapability.verifyPasskey`, `PasskeyRequestOptions` and the `.invalidPasskey` sub-reason are all unavailable there, and the SDK doesn't advertise the capability. If your app also targets tvOS or watchOS, wrap the code that uses them in `#if !os(tvOS) && !os(watchOS)`. Only discoverable passkeys are supported.

**Prerequisites**

- A deployment target of iOS 16.6+, macOS 13.5+ or visionOS 1.0+ for the code that calls `verifyPasskey(_:)`.
- A [custom domain](https://auth0.com/docs/customize/custom-domains) configured for your Auth0 tenant. The server doesn't offer passkeys on the canonical `*.auth0.com` domain.
- Passkey login enabled on the connection.
- The iOS **Device Settings** configured for your Auth0 application, as for [passkey login](authentication-api/login-passkey.md#prerequisites).

> [!NOTE]
> The prerequisites of the standalone passkey login also include enabling the **Passkeys** grant for the application. Whether the embedded flow needs it too isn't confirmed yet: if the server doesn't offer the passkey with the prerequisites above, check that grant as well.

The SDK can't tell why a passkey wasn't offered: the capability wasn't declared, passkey login is off on the connection, or the domain isn't a custom domain.

**On by default**

`authorize(connection:)` advertises `EmbeddedCapability.verifyPasskey` as part of `EmbeddedCapability.all`, on the platforms that support it, so the server may offer `.verifyPasskey(options:requestJson:)`. Choose the step to present by the **type** of the entry in `nextActions`, never by its **position**: the order is up to the server. To turn passkey sign-in off, pass an explicit list of capabilities without it (tvOS and watchOS have no passkey capability, so there is nothing to turn off there):

```swift
let withoutPasskey = EmbeddedCapability.all.filter { $0 != .verifyPasskey }
try await client.authorize(connection: connection,
                           capabilities: withoutPasskey,
                           scope: "openid profile email offline_access",
                           audience: nil).start()
```

**Sign in with a passkey**

`PasskeyRequestOptions` carries the main options the server sent: `relyingPartyId`, `challengeData`, `timeout` (in milliseconds), `userVerification`, `allowedCredentialIds` and `hints`. The first four are always present, and an offer that lacks one of them, or has a `userVerification` value that your SDK version doesn't recognise, isn't passed to your app. `allowedCredentialIds` and `hints` can be empty. Use the options as sent, and don't reuse the options of an earlier offer. The SDK doesn't build or present any passkey UI: your app builds the platform request from these options, as the `assertionRequest()` helper in the sample below does, and shows it with `ASAuthorizationController`. The helper applies the relying party, the challenge, the user verification preference and the allowed credentials. `timeout` and `hints` have no platform equivalent, so they aren't applied, and the SDK doesn't impose a timeout of its own.

The next action also carries `requestJson`, the complete options object the server sent, as a JSON string. It includes members that `PasskeyRequestOptions` doesn't model. Use it if your app runs the passkey with its own WebAuthn code instead of the system request built from `options`. It holds the challenge, so don't log it, and use it for one attempt only.

```swift
// Compile this code only for iOS, macOS and visionOS: wrap it in `#if !os(tvOS) && !os(watchOS)`
// if your app also targets tvOS or watchOS.
import AuthenticationServices

@MainActor
@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
func signInWithPasskey(options: PasskeyRequestOptions, otherActions: [NextAction]) async throws -> Credentials {
    let sheet = PasskeySheet() // Your wrapper around ASAuthorizationController, see below.
    do {
        let assertion = try await sheet.assertion(for: options)
        return try await client.verifyPasskey(assertion).start()
    } catch let error as ASAuthorizationError where error.code == .canceled {
        // The user cancelled, or has no passkey. The session is still valid: offer another entry from `otherActions`,
        // for example `.identifyEmail`. Don't call verifyPasskey(_:) again with the same options.
        let others = otherActions.filter { if case .verifyPasskey = $0 { return false } else { return true } }
        return try await handleNextActions(others)
    } catch let error as EmbeddedAuthError {
        switch error.reason {
        case .insufficientAuthorization(.invalidPasskey, let nextActions):
            // The passkey couldn't be verified. The previous assertion can't be reused. If the server offers the
            // passkey again, nextActions holds NEW options: run the sheet again with those. Otherwise, or if the
            // user gives up, offer the other entries.
            return try await handleNextActions(nextActions)
        case .insufficientAuthorization(_, let nextActions):
            // For example a second factor after the passkey.
            return try await handleNextActions(nextActions)
        default:
            throw error
        }
    }
}

@MainActor
@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
final class PasskeySheet: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorizationPlatformPublicKeyCredentialAssertion, Error>?
    private var controller: ASAuthorizationController?

    func assertion(for options: PasskeyRequestOptions) async throws -> ASAuthorizationPlatformPublicKeyCredentialAssertion {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [options.assertionRequest()])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        if let assertion = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            continuation?.resume(returning: assertion)
        } else {
            continuation?.resume(throwing: ASAuthorizationError(.failed))
        }
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // … return the window of your app …
    }
}

// Your helper, not part of the SDK: builds the platform request from the options the server sent.
@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
extension PasskeyRequestOptions {
    func assertionRequest() -> ASAuthorizationPlatformPublicKeyCredentialAssertionRequest {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyId)
        let request = provider.createCredentialAssertionRequest(challenge: challengeData)
        switch userVerification {
        case .required:
            request.userVerificationPreference = .required
        case .preferred:
            request.userVerificationPreference = .preferred
        case .discouraged:
            request.userVerificationPreference = .discouraged
        }
        request.allowedCredentials = allowedCredentialIds.map {
            ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: $0)
        }
        return request
    }
}
```

<details>
  <summary>Using callbacks</summary>

```swift
if #available(iOS 16.6, macOS 13.5, visionOS 1.0, *) {
    // `assertion` comes from the ASAuthorizationControllerDelegate.
    client.verifyPasskey(assertion).start { result in
        switch result {
        case .success(let credentials):
            // Use credentials
            break
        case .failure(let error):
            // Switch over error.reason as shown above.
            print("Failed with: \(error)")
        }
    }
}
```
</details>

**Autofill (iOS)**

For the best experience on iOS, offer the passkey in AutoFill on the first screen, with no typing: set `textContentType = .username` on the email field, start `ASAuthorizationController(authorizationRequests: [options.assertionRequest()]).performAutoFillAssistedRequests()` when the screen appears, using the `assertionRequest()` helper from the sample above, and also offer a "Sign in with passkey" button that calls `performRequests()`. Keep the email field and its `identify(_:type:)` flow as the fallback. `performAutoFillAssistedRequests()` is only available on iOS. The result of an AutoFill pick goes to `verifyPasskey(_:)` like any other passkey result.

**What to expect**

| Outcome | What happens |
|---|---|
| Success | `verifyPasskey(_:)` returns `Credentials`. The SDK clears the session after the token exchange succeeds. |
| The user cancels, or has no passkey | Nothing was sent to Auth0, and the session is still valid. Use another entry from the same `nextActions`, for example `identify(_:type:)`. |
| `.insufficientAuthorization(.invalidPasskey, nextActions)` | The passkey couldn't be verified, for any reason; the server doesn't say why. The SDK adopts the rotated session. Look for `.verifyPasskey` in the **new** `nextActions` and run the sheet again with those options, or offer another entry. The server may not offer the passkey again, so don't assume it will. |
| `.insufficientAuthorization(.none, nextActions)` | More steps are needed, for example a second factor. Handle `nextActions` like any other continuation. |
| `.invalidInput(message)` | A local check failed (for example the passkey has no user handle, because only discoverable passkeys are supported). Nothing was sent and the session is kept. The message never contains passkey data. |
| `.network` | The request failed before an answer arrived. The session is kept. The SDK doesn't keep the assertion, so retrying means calling `verifyPasskey(_:)` with the same assertion again. If the failure hit the final token exchange, the server may already have used the challenge and decides what a repeated assertion gets; be ready to start over. |
| `.accessDenied`, `.invalidRequest`, `.tooManyAttempts`, `.tooManyLogins`, `.ipBlocked`, `.unknown` | The flow has ended. Start over with `authorize()`. |

The passkey offer is only valid while it is in the latest `nextActions`. After you submit another step such as `identify(_:type:)`, the offer is gone, and only a new `authorize()` offers it again. Call `verifyPasskey(_:)` right after receiving a `nextActions` that contains `.verifyPasskey`, before submitting anything else. If you call it later, the server decides what happens; expect the request to be rejected and the flow to end.

**Two ways to sign in with a passkey**

Use `verifyPasskey(_:)` inside an embedded flow, where the server offers the passkey as one of the next actions. For a standalone passkey login without the embedded flow, keep using the [Authentication API passkey methods](authentication-api/login-passkey.md). They are unchanged.

#### Sign up

When `nextActions` contains `.signup(identifiers:passwordRequirement:)`, the connection allows self-registration. `identifiers` lists what the server collects for the new account: `.email` and/or `.phone`, each with `isRequired`. Use it to decide which fields to show. Identifiers this SDK does not recognise are left out, so the list can be empty. A username is never offered. `passwordRequirement` says whether the connection also collects a password at the end, see [Sign up with a password](#sign-up-with-a-password).

**Choose the capabilities.** `authorize(connection:)` advertises every capability, including sign-up. To keep sign-up out of a login screen, pass the capabilities explicitly. Without `.signup` and `.confirmSignup` the server never offers it. For a sign-up screen, advertise what sign-up uses:

```swift
// Login: everything except sign-up.
let loginCapabilities = EmbeddedCapability.all.filter { $0 != .signup && $0 != .confirmSignup }

// Sign-up: the sign-up actions, email and phone identification, their challenges and the code check.
let signupCapabilities: [EmbeddedCapability] = [
    .signup, .identifyEmail, .identifyPhone,
    .challengeEmail, .challengePhone, .verifyOTP, .confirmSignup
]

// On the login screen:
try await client.authorize(connection: connection,
                           capabilities: loginCapabilities,
                           scope: "openid profile email offline_access",
                           audience: nil).start()
```

**Collect one or more identifiers.** `signup()` never returns credentials: it always fails with `.insufficientAuthorization` and the `nextActions` for the next step. When `identifiers` lists both `.email` and `.phone`, the registration collects both with the same steps used for login: identify an identifier, send and verify its code, then do the same for the other. The server offers the identify steps it still needs, and your app picks which one to do next, so follow `nextActions` after every step instead of assuming a fixed sequence. Once every required identifier is verified the server offers `.confirmSignup(password:)`. Call `confirmSignup(password: nil)` then, or `confirmSignup(password:)` when the connection collects a password. Like `verifyOtp`, it returns `Credentials` on success. An identifier that is not required can be left out: the server offers `.confirmSignup` without it.

This example signs a user up with an email and a phone number, and a password when the connection collects one. It does the email first, then the phone number. Pass `nil` for an identifier the user left empty. An empty value is never sent, because the server rejects it:

```swift
/// Runs a step that is expected to continue the flow. Returns whether the last code was wrong, and the
/// `nextActions` the server offers.
func continuation(after step: () async throws -> Void) async throws -> (wrongCode: Bool, nextActions: [NextAction]) {
    do {
        try await step()
    } catch let error as EmbeddedAuthError {
        guard case .insufficientAuthorization(let reason, let nextActions) = error.reason else { throw error }
        switch reason {
        case .invalidCode, .invalidIdentifierOrCode: return (true, nextActions)
        default: return (false, nextActions)
        }
    }
    // During sign-up only confirmSignup(password: nil) returns credentials, so a step that succeeds is unexpected.
    throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
}

extension NextAction {
    var isConfirmSignup: Bool {
        if case .confirmSignup = self { return true }
        return false
    }
}

func signUp(email: String?,
            phone: String?,
            password: String?,
            askForCode: (_ sentTo: String?, _ lastCodeWasWrong: Bool) async -> String,
            askForPassword: (_ lastPasswordWasRejected: Bool) async -> String?) async throws -> Credentials {
    var password = password
    var step = try await continuation {
        try await client.authorize(connection: connection,
                                   capabilities: signupCapabilities,
                                   scope: "openid profile email offline_access",
                                   audience: nil).start()
    }
    // Only start the registration if the connection allows it, and every required identifier was provided.
    guard let identifiers = step.nextActions.compactMap({ action -> [SignupIdentifier]? in
        if case .signup(let identifiers, _) = action { return identifiers }
        return nil
    }).first else {
        throw EmbeddedAuthError(info: ["error": "signup_not_offered"], statusCode: 0)
    }
    for identifier in identifiers where identifier.isRequired {
        let value = identifier.type == .email ? email : phone
        if value?.isEmpty != false {
            throw EmbeddedAuthError(info: ["error": "missing_required_identifier"], statusCode: 0)
        }
    }
    step = try await continuation { try await client.signup().start() }

    var identified = Set<IdentifierType>()
    var verified = Set<OtpChannel>()
    for _ in 0..<12 {
        let actions = step.nextActions
        // An identifier the user entered is still sent while the server asks for it, even if sign-up could
        // already be confirmed without it.
        let emailPending = actions.contains(.identifyEmail) && email?.isEmpty == false && !identified.contains(.email)
        let phonePending = actions.contains(.identifyPhone) && phone?.isEmpty == false && !identified.contains(.phone)

        if actions.contains(where: \.isConfirmSignup), !emailPending, !phonePending {
            // Every required identifier is verified: create the account and sign the user in.
            do {
                return try await client.confirmSignup(password: password).start()
            } catch let error as EmbeddedAuthError {
                guard case .insufficientAuthorization(let reason, let nextActions) = error.reason else { throw error }
                switch reason {
                case .passwordRequired:
                    password = await askForPassword(false)
                case .invalidPassword:
                    password = await askForPassword(true)
                case .passwordNotAccepted:
                    // The connection does not collect a password: confirm without one.
                    password = nil
                default:
                    throw error
                }
                // The flow is still live: nextActions offers .confirmSignup again.
                step = (false, nextActions)
                continue
            }
        }
        if let (channel, sentTo) = actions.compactMap({ action -> (OtpChannel, String?)? in
            if case .verifyOTP(let channel, let identifier) = action { return (channel, identifier) }
            return nil
        }).first {
            let code = await askForCode(sentTo, step.wrongCode)
            step = try await continuation {
                _ = try await client.verifyOtp(code, type: channel == .totp ? .totp : .oob).start()
            }
            if !step.wrongCode { verified.insert(channel) }
        } else if !verified.contains(.email), let index = actions.compactMap({ action -> Int? in
            if case .challengeEmail(let index, _) = action { return index }
            return nil
        }).first {
            step = try await continuation { try await client.challengeEmail(index: index).start() }
        } else if !verified.contains(.sms), !verified.contains(.voice),
                  let (index, methods) = actions.compactMap({ action -> (Int, [PhoneDeliveryMethod])? in
                      if case .challengePhone(let index, _, let methods) = action { return (index, methods) }
                      return nil
                  }).first {
            let method = methods.first ?? .text
            step = try await continuation { try await client.challengePhone(index: index, deliveryMethod: method).start() }
        } else if emailPending, let email {
            identified.insert(.email)
            step = try await continuation { try await client.identify(email, type: .email).start() }
        } else if phonePending, let phone {
            identified.insert(.phone)
            step = try await continuation { try await client.identify(phone, type: .phone).start() }
        } else {
            throw EmbeddedAuthError(info: ["error": "unsupported_action"], statusCode: 0)
        }
    }
    throw EmbeddedAuthError(info: ["error": "too_many_steps"], statusCode: 0)
}
```

<details>
  <summary>Using callbacks</summary>

```swift
// When nextActions contains .signup(identifiers:passwordRequirement:) and the user chose to create an account.
// Use the same client instance for every step: it holds the session.
client.signup().start { result in
    switch result {
    case .success:
        // signup() always fails with the next step — unreachable in practice
        break
    case .failure(let error):
        if case .insufficientAuthorization(_, let nextActions) = error.reason {
            // Present nextActions, for example .identifyEmail, then its challenge and verifyOtp steps
            _ = nextActions
        } else {
            // For example .accessDenied: the server rejected the sign-up. Start over with authorize().
            print("Failed with: \(error)")
        }
    }
}

// When nextActions contains .confirmSignup(password:). Pass nil when the connection does not collect a password,
// or when the password is optional and the user skipped it.
client.confirmSignup(password: password).start { result in
    switch result {
    case .success(let credentials):
        // The account is created and the user is signed in
        _ = credentials
    case .failure(let error):
        switch error.reason {
        case .network:
            // The session is kept, but the SDK does not keep the password: call confirmSignup(password:) again with it
            break
        case .insufficientAuthorization(.passwordRequired, _), .insufficientAuthorization(.invalidPassword, _):
            // Ask the user for a (new) password, then call confirmSignup(password:) again
            break
        case .insufficientAuthorization(.passwordNotAccepted, _):
            // The connection does not collect a password: call confirmSignup(password: nil)
            break
        case .passwordLeaked:
            // The password appears in a data breach. The flow has ended: start over with authorize()
            break
        default:
            print("Failed with: \(error)")
        }
    }
}
```
</details>

**Handle rejections.** If the server rejects the new user before registration, for example because of a pre-registration validation or an Action that denies the sign-up, the request fails with `.accessDenied` and the flow ends. Start a new flow with `authorize()` and show the user a generic message. `signup()`, `confirmSignup(password: nil)` and `confirmSignup(password:)` need an active session and fail locally with `.noActiveSession` otherwise. If `confirmSignup(password:)` fails with `.network` while exchanging the code, the session is kept and a retry sends the confirmation again. The server decides whether it can still complete. The SDK never keeps the password, so pass it again when you retry.

**An identifier that already has an account.** Signing up with an email or phone number that already has an account does not return an error, so sign-up can't be used to find out which accounts exist. The server answers each step as it would for a new identifier but sends no code, so any code the user enters fails with `.insufficientAuthorization(.invalidIdentifierOrCode, nextActions)`, the same as a mistyped code, until the attempt limit ends the flow with `.tooManyWrongOtpAttempts`. Requesting codes again is limited too and ends the flow with `.accessDenied`. While that identifier is required, the server never offers `.confirmSignup`. If it is optional, the user can leave it out and the account is created without it. Your app can't tell this case apart from a mistyped code, so on the code screen offer a way out, such as "Already have an account? Sign in", which starts a new login flow with `authorize()`.

##### Sign up with a password

Some connections also collect a password, as the last step of the sign-up. The identifiers are collected and verified as above. The password is sent with `confirmSignup(password:)`, which creates the account.

| Connection | `.signup` `passwordRequirement` | `.confirmSignup` `password` | What the app does |
|---|---|---|---|
| No password | `.none` | `nil` | `confirmSignup(password: nil)` |
| Password required | `.required` | set, `isRequired` is `true` | `confirmSignup(password:)` |
| Password optional | `.optional` | set, `isRequired` is `false` | `confirmSignup(password:)`, with `nil` to skip |

`passwordRequirement` lets the first screen tell the user a password is coming. When the value is wrapped in an `Optional`, write `CredentialRequirement.none`: a bare `.none` is read as `Optional.none`.

`.confirmSignup(password:)` tells you what to render. `password` is `nil` when there is no password to collect. Otherwise show a password field, mandatory when `isRequired` is `true`, and use `complexity` for hints. The server does not repeat `isRequired` at the confirm step: the client remembers it from the sign-up offer at the start of the flow, so use the same client for the whole flow. `isRequired` is `true` only when that offer said the password is required, or after the server has answered with `.passwordRequired`. Otherwise it is `false`, and a skipped password that the connection needs comes back as `.passwordRequired`, which makes `isRequired` `true` from then on.

The hints are advisory. The server is authoritative, so a password that satisfies them can still be rejected:

- `complexity.minLength` counts UTF-16 code units. Count with `password.utf16.count`, not `password.count`.
- `complexity.characterTypes` lists the character types the password must contain; all of them are required. It is empty when the server lists none, and types this SDK does not recognise are left out.
- Rules such as "at least 3 of the 4 character types" are not included, but they are still enforced.

`nil` creates the account without a password, which only works when the password is optional. The password is sent as is and nothing is trimmed, and the server treats an empty string as no password. The SDK does not check the length or the complexity locally: the server and the connection's password policy enforce the limits.

```swift
func finishSignUp(password: SignupPassword?, askForPassword: (_ lastPasswordWasRejected: Bool) async -> String?) async throws -> Credentials {
    var entered: String?
    var networkRetries = 0
    if password != nil { entered = await askForPassword(false) }
    while true {
        do {
            return try await client.confirmSignup(password: entered).start()
        } catch let error as EmbeddedAuthError {
            switch error.reason {
            case .insufficientAuthorization(.passwordRequired, _):
                // The connection needs a password and none was sent: ask for one.
                entered = await askForPassword(false)
            case .insufficientAuthorization(.invalidPassword, _):
                // The connection's password policy rejected it: show the hints again and ask for another one.
                entered = await askForPassword(true)
            case .insufficientAuthorization(.passwordNotAccepted, _):
                // The connection does not collect a password: confirm without one.
                entered = nil
            case .network:
                // The session is kept, but the SDK does not keep the password: send it again, a few times at most.
                networkRetries += 1
                guard networkRetries <= 3 else { throw error }
                try await Task.sleep(nanoseconds: 1_000_000_000)
            case .passwordLeaked:
                // The password appears in a data breach. The flow has ended: start over with authorize().
                throw error
            default:
                throw error
            }
        }
    }
}
```

<details>
  <summary>Using callbacks</summary>

```swift
// Pass nil to skip an optional password, or when the connection does not collect one.
client.confirmSignup(password: enteredPassword).start { result in
    switch result {
    case .success(let credentials):
        _ = credentials
    case .failure(let error):
        switch error.reason {
        case .insufficientAuthorization(.passwordRequired, _), .insufficientAuthorization(.invalidPassword, _):
            // The flow is still live. Ask for a (new) password and call confirmSignup(password:) again.
            break
        case .insufficientAuthorization(.passwordNotAccepted, _):
            // Call confirmSignup(password: nil) instead.
            break
        case .network:
            // The SDK does not keep the password: call confirmSignup(password:) again with it.
            break
        default:
            // For example .passwordLeaked: the flow has ended. Start over with authorize().
            print("Failed with: \(error)")
        }
    }
}
```
</details>

`.passwordRequired`, `.passwordNotAccepted` and `.invalidPassword` keep the flow live on a rotated session, and `nextActions` offers `.confirmSignup` again. If the final token exchange fails with `.network`, the session is kept and the SDK does not keep the password, so call `confirmSignup(password:)` again with it. `.passwordLeaked` ends the flow: the password appears in a data breach, so start a new flow with `authorize()` and let the user choose a different password. Do not log or store the password.

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
        // The password appears in a data breach (at login or sign-up) — the flow has ended: start over with authorize()
        // and ask the user to choose a different password.
        break
    case .accessDenied:
        // Other terminal denial — start over with authorize().
        break
    case .invalidInput(let message):
        // A local check failed — nothing was sent and the session is kept. Fix the input and try the same step again.
        _ = message
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
| `invalid_passkey` | `.invalidPasskey` | The passkey assertion could not be verified. The server doesn't say why. | Show the passkey UI again with the **new** options in `nextActions`, or offer another entry. The server may not offer the passkey again. |
| `slow_down` | `.slowDown` | `verifyOob()` was called before `pollInMs` elapsed. | Wait longer than before, then poll again. |
| `password_required` | `.passwordRequired` | `confirmSignup` was called without a password, but the connection requires one. | Ask for a password and call `confirmSignup(password:)` again. |
| `password_not_accepted` | `.passwordNotAccepted` | `confirmSignup(password:)` was called with a password, but the connection does not collect one. | Call `confirmSignup(password: nil)` without a password. |
| `invalid_password` | `.invalidPassword` | The password does not meet the connection's password policy. | Show the hints again, ask for another password and call `confirmSignup(password:)` again. |

```swift
guard case .insufficientAuthorization(let subReason, let nextActions) = error.reason else {
    throw error
}
switch subReason {
case .invalidIdentifierOrCode, .invalidCode, .invalidIdentifierOrPassword:
    // The user entered something wrong — show an error and present nextActions again.
    break
#if !os(tvOS) && !os(watchOS)
case .invalidPasskey:
    // The passkey couldn't be verified — run the passkey UI again with the new options in nextActions, or offer
    // another entry. Never reuse the previous assertion or options.
    break
#endif
case .authorizationPending, .slowDown:
    // Only returned while polling verifyOob() — see "Push notification (polling)".
    break
case .passwordRequired, .passwordNotAccepted, .invalidPassword:
    // Only returned by confirmSignup(password:) — see "Sign up with a password".
    break
case .none:
    // A plain continuation — present nextActions.first.
    break
}
```

[Go up ⤴](../EXAMPLES.md#examples)
