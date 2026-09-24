## Embedded Auth (iOS / macOS / tvOS / watchOS / visionOS) [EA]

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/embeddedauth)**

> [!IMPORTANT]
> Embedded Login Discovery is currently in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant and application.

- [Discover login options](#discover-login-options)
- [Filter by connection](#filter-by-connection)
- [Inspect the discovered options](#inspect-the-discovered-options)
- [Embedded Auth errors](#embedded-auth-errors)

### Discover login options

The Embedded Login Discovery API returns the live set of login alternatives available for your application, so you can render the right authentication options at runtime without hardcoding them. It calls `GET /e/discovery` and yields a `DiscoveryResult`.

```swift
Auth0
    .embeddedAuth()
    .discover()
    .start { result in
        switch result {
        case .success(let discovery):
            print("Available options: \(discovery.options)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let discovery = try await Auth0
        .embeddedAuth()
        .discover()
        .start()
    print("Available options: \(discovery.options)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .embeddedAuth()
    .discover()
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { discovery in
        print("Available options: \(discovery.options)")
    })
    .store(in: &cancellables)
```
</details>

> [!NOTE]
> `Auth0.embeddedAuth()` loads the Client ID and Domain from the `Auth0.plist` file in your bundle. To supply them programmatically, use `Auth0.embeddedAuth(clientId: "your-client-id", domain: "your-domain")`.

### Filter by connection

Pass a connection name to restrict discovery to a single connection instead of retrieving all alternatives.

```swift
Auth0
    .embeddedAuth()
    .discover(connection: "Username-Password-Authentication")
    .start { result in
        switch result {
        case .success(let discovery):
            print("Available options: \(discovery.options)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let discovery = try await Auth0
        .embeddedAuth()
        .discover(connection: "Username-Password-Authentication")
        .start()
    print("Available options: \(discovery.options)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

### Inspect the discovered options

`DiscoveryResult` exposes the raw `options` array along with convenience accessors that group the alternatives by type, so you can drive your UI directly from the response.

```swift
let discovery = try await Auth0.embeddedAuth().discover().start()

// The distinct grant types the server advertises
let types = discovery.types // e.g. [.passwordRealm, .passkey, .passwordlessOtp]

// Check for a specific capability before showing a button
if discovery.supports(.passkey) {
    // Show the "Sign in with a passkey" option
}

// Typed accessors for each alternative
let realms = discovery.passwordRealms         // [String]
let passkeyConnections = discovery.passkeyConnections // [String]
let otpOptions = discovery.passwordlessOTPOptions // [PasswordlessOTPOption]
let socialProviders = discovery.socialProviders // [String] of subject_token_type values

// Or iterate the options directly
for option in discovery.options {
    switch option {
    case .password:
        print("Password grant against the default directory")
    case .passwordRealm(let realm):
        print("Password realm: \(realm)")
    case .passkey(let connection):
        print("Passkey connection: \(connection)")
    case .passwordlessOtp(let connection, let identifiers, let type):
        print("Passwordless OTP on \(connection) via \(identifiers) (\(type))")
    case .nativeSocial(let subjectTokenType):
        print("Native social: \(subjectTokenType)")
    case .authorizationCode(let connection, let type):
        print("Authorization code: \(connection) (\(type ?? "-"))")
    case .unknown(let rawGrantType, let connection):
        print("Unknown grant \(rawGrantType) on \(connection ?? "-")")
    }
}
```

### Embedded Auth errors

The Embedded Auth client will only produce `EmbeddedAuthError` error values.

- Use the `isFeatureDisabled` property to check if the `embedded_discovery` feature is not enabled for the tenant (a bare `404`).
- Use the `isInvalidRequest` property to check if the request was malformed or `embedded_discovery` is not enabled for the application (`invalid_request`).
- Use the `isInvalidClient` property to check if the `client_id` does not resolve for the tenant (`invalid_client`).
- The `info` property contains additional information about the error.

```swift
Auth0
    .embeddedAuth()
    .discover()
    .start { result in
        switch result {
        case .success(let discovery):
            print("Available options: \(discovery.options)")
        case .failure(let error) where error.isFeatureDisabled:
            print("Embedded discovery is not enabled for this tenant")
        case .failure(let error) where error.isInvalidRequest:
            print("Embedded discovery is not enabled for this application")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/embeddedautherror) to learn more about the available `EmbeddedAuthError` properties.

> [!WARNING]
> Do not parse or otherwise rely on the error messages to handle the errors. The error messages are not part of the API and can change. Use the error properties instead, which are part of the API.

[Go up ⤴](../EXAMPLES.md#examples)
