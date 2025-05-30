# Examples

- [Web Auth (iOS / macOS / visionOS)](#web-auth-ios--macos--visionos)
- [Credentials Manager (iOS / macOS / TVOS / watchOS / visionOS)](#credentials-manager-ios--macos--tvos--watchos--visionos)
- [Authentication API (iOS / macOS / TVOS / watchOS / visionOS)](#authentication-api-ios--macos--tvos--watchos--visionos)
- [My Account API (iOS / macOS / tvOS / watchOS / visionOS) [EA]](#my-account-api-ios--macos--tvos--watchos--visionos-ea)
- [Management API (Users) (iOS / macOS / TVOS / watchOS / visionOS)](#management-api-users-ios--macos--tvos--watchos--visionos)
- [Logging](#logging)
- [Advanced Features](#advanced-features)

---

## Web Auth (iOS / macOS / visionOS)

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/webauth)**

- [Web Auth signup](#web-auth-signup)
- [Web Auth configuration](#web-auth-configuration)
- [ID token validation](#id-token-validation)
- [Web Auth errors](#web-auth-errors)

### Web Auth signup

You can make users land directly on the Signup page instead of the Login page by specifying the `"screen_hint": "signup"` parameter. Note that this can be combined with `"prompt": "login"`, which indicates whether you want to always show the authentication page or you want to skip if there's an existing session.

| Parameters                                     | No existing session   | Existing session              |
|:-----------------------------------------------|:----------------------|:------------------------------|
| No extra parameters                            | Shows the login page  | Redirects to the callback URL |
| `"screen_hint": "signup"`                      | Shows the signup page | Redirects to the callback URL |
| `"prompt": "login"`                            | Shows the login page  | Shows the login page          |
| `"prompt": "login", "screen_hint": "signup"`   | Shows the signup page | Shows the signup page         |

```swift
Auth0
    .webAuth()
    .parameters(["screen_hint": "signup"])
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

> [!NOTE]
> The `screen_hint` parameter will work with the **New Universal Login Experience** without any further configuration. If you are using the **Classic Universal Login Experience**, you need to customize the [login template](https://manage.auth0.com/#/login_page) to look for this parameter and set the `initialScreen` [option](https://github.com/auth0/lock/blob/master/EXAMPLES.md#database-options) of the `Auth0Lock` constructor.

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await Auth0
        .webAuth()
        .parameters(["screen_hint": "signup"])
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .webAuth()
    .parameters(["screen_hint": "signup"])
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

### Web Auth configuration

The following are some of the available Web Auth configuration options. Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/webauth/#topics) for the full list.

#### Use any Auth0 connection

Specify an Auth0 connection to directly open that identity provider's login page, skipping the [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login) page itself. The connection must first be enabled for your Auth0 application in the [Dashboard](https://manage.auth0.com/#/applications/).

```swift
Auth0
    .webAuth()
    .connection("github") // Show the GitHub login page
    // ...
```

#### Add an audience value

Specify an [audience](https://auth0.com/docs/secure/tokens/access-tokens/get-access-tokens#control-access-token-audience) to obtain an access token that can be used to make authenticated requests to a backend. The audience value is the **API Identifier** of your [Auth0 API](https://auth0.com/docs/get-started/apis), for example `https://example.com/api`.

```swift
Auth0
    .webAuth()
    .audience("YOUR_AUTH0_API_IDENTIFIER")
    // ...
```

#### Add a scope value

Specify a [scope](https://auth0.com/docs/get-started/apis/scopes) to request permission to access protected resources, like the user profile. The default scope value is `openid profile email`. Regardless of the scope value specified, `openid` is always included.

```swift
Auth0
    .webAuth()
    .scope("openid profile email read:todos")
    // ...
```

Use `connectionScope()` to configure a scope value for an Auth0 connection.

```swift
Auth0
    .webAuth()
    .connection("github")
    .connectionScope("public_repo read:user")
    // ...
```

#### Get a refresh token

You must request the `offline_access` [scope](https://auth0.com/docs/get-started/apis/scopes) when logging in to get a [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens) from Auth0.

```swift
Auth0
    .webAuth()
    .scope("openid profile email offline_access read:todos")
    // ...
```

> [!IMPORTANT]
> Make sure that your Auth0 application has the **refresh token** [grant enabled](https://auth0.com/docs/get-started/applications/update-grant-types). If you are also specifying an audience value, make sure that the corresponding Auth0 API has the **Allow Offline Access** [setting enabled](https://auth0.com/docs/get-started/apis/api-settings#access-settings).

#### Use a custom `URLSession` instance

You can specify a custom `URLSession` instance for more advanced networking configuration, such as customizing timeout values.

```swift
Auth0
    .webAuth(session: customURLSession)
    // ...
```

> [!NOTE]
> This custom `URLSession` instance will be used when communicating with the Auth0 Authentication API, not when opening the [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login) page.

#### Use `SFSafariViewController` instead of `ASWebAuthenticationSession`

You can use the built-in `SFSafariViewController` Web Auth provider to open the [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login) page.

```swift
Auth0
    .webAuth()
    .provider(WebAuthentication.safariProvider()) // Use SFSafariViewController
    .start { result in
        // ...
    }
```

> [!TIP]
> See [`ASWebAuthenticationSession` vs `SFSafariViewController` (iOS)](https://auth0.github.io/Auth0.swift/documentation/auth0/useragents) to help determine which option best suits your use case, depending on your requirements.

> [!NOTE]
> `SFSafariViewController` does not support using Universal Links as callback URLs.

The `SFSafariViewController` Web Auth provider requires an additional bit of setup. Unlike `ASWebAuthenticationSession`, `SFSafariViewController` will not automatically capture the callback URL when Auth0 redirects back to your app, so it is necessary to manually resume the Web Auth operation.

##### 1. Configure a custom URL scheme

In Xcode, go to the **Info** tab of your app target settings. In the **URL Types** section, click the **＋** button to add a new entry. There, enter `auth0` into the **Identifier** field and `$(PRODUCT_BUNDLE_IDENTIFIER)` into the **URL Schemes** field.

![Screenshot of the URL Types section inside the app target settings](https://user-images.githubusercontent.com/5055789/198689930-15f12179-15df-437e-ba50-dec26dbfb21f.png)

This registers your bundle identifier as a custom URL scheme, so the callback URL can reach your app.

##### 2. Capture the callback URL

<details>
  <summary>Using the UIKit app lifecycle</summary>

```swift
// AppDelegate.swift

func application(_ app: UIApplication,
                 open url: URL,
                 options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
    return WebAuthentication.resume(with: url)
}
```
</details>

<details>
  <summary>Using the UIKit app lifecycle with Scenes</summary>

```swift
// SceneDelegate.swift

func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    WebAuthentication.resume(with: url)
}
```
</details>

<details>
  <summary>Using the SwiftUI app lifecycle</summary>

```swift
SomeView()
    .onOpenURL { url in
        WebAuthentication.resume(with: url)
    }
```
</details>

##### Logout

`SFSafariViewController` should only be used for login. According to its docs, `SFSafariViewController` must be used "to visibly present information to users":

![Screenshot of SFSafariViewController's documentation](https://github.com/user-attachments/assets/98de5937-3ca4-4779-9e3c-725d8b628870)

This is the case for login, but not for logout. Instead of calling `clearSession()`, you can delete the stored credentials –using the Credentials Manager's `clear()` method– and use `"prompt": "login"` to force the login page even if the session cookie is still present. Since the cookies stored by `SFSafariViewController` are scoped to your app, this should not pose an issue.

```swift
Auth0
    .webAuth()
    .provider(WebAuthentication.safariProvider())
    .parameters(["prompt": "login"])
    .start { result in
        // ...
    }
```

#### Use `WKWebView` instead of `ASWebAuthenticationSession`

You can also use the built-in `WKWebView` Web Auth provider to open the [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login) page. Unlike `SFSafariViewController`, `WKWebView` supports using Universal Links as callback URLs.

```swift
Auth0
    .webAuth()
    .provider(WebAuthentication.webViewProvider()) // Use WKWebView
    .start { result in
        // ...
    }
```

> [!NOTE]
> To use Universal Login's biometrics and passkeys with `WKWebView`, you must [set up an associated domain](https://github.com/auth0/Auth0.swift#configure-an-associated-domain).

> [!WARNING]
> The use of `WKWebView` for performing web-based authentication [is not recommended](https://auth0.com/blog/oauth-2-best-practices-for-native-apps), and some social identity providers –such as Google– do not support it.

### ID token validation

Auth0.swift automatically [validates](https://auth0.com/docs/secure/tokens/id-tokens/validate-id-tokens) the ID token obtained from Web Auth login, following the [OpenID Connect specification](https://openid.net/specs/openid-connect-core-1_0.html). This ensures the contents of the ID token have not been tampered with and can be safely used.

### Web Auth errors

Web Auth will only produce `WebAuthError` error values. You can find the underlying error (if any) in the `cause: Error?` property of the `WebAuthError`. Not all error cases will have an underlying `cause`. Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/webautherror) to learn more about the error cases you need to handle, and which ones include a `cause` value.

> [!WARNING]
> Do not parse or otherwise rely on the error messages to handle the errors. The error messages are not part of the API and can change. Run a switch statement on the [error cases](https://auth0.github.io/Auth0.swift/documentation/auth0/webautherror/#topics) instead, which are part of the API.

[Go up ⤴](#examples)

## Credentials Manager (iOS / macOS / tvOS / watchOS / visionOS)

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/credentialsmanager)**

- [Store credentials](#store-credentials)
- [Check for stored credentials](#check-for-stored-credentials)
- [Retrieve stored credentials](#retrieve-stored-credentials)
- [Renew stored credentials](#renew-stored-credentials)
- [Retrieve stored user information](#retrieve-stored-user-information)
- [Clear stored credentials](#clear-stored-credentials)
- [Biometric authentication](#biometric-authentication)
- [Other credentials](#other-credentials)
- [Credentials Manager errors](#credentials-manager-errors)

The Credentials Manager utility allows you to securely store and retrieve the user's credentials from the Keychain.

```swift
let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
```

> [!CAUTION]
> The Credentials Manager is not thread-safe, except for the following methods: 
> 
> - `credentials()`
> - `apiCredentials()`
> - `ssoCredentials()`
> - `renew()`
> 
> To avoid concurrency issues, do not call its non thread-safe methods and properties from different threads without proper synchronization.

### Store credentials

When your users log in, store their credentials securely in the Keychain. You can then check if their credentials are still valid when they open your app again.

```swift
let didStore = credentialsManager.store(credentials: credentials)
```

### Check for stored credentials

When the users open your app, check for stored credentials. If they exist and are valid / can be renewed, you can retrieve them and redirect the users to the app's main flow without any additional login steps.

#### If you are using refresh tokens

```swift
guard credentialsManager.canRenew() else {
    // No renewable credentials exist, present the login page
}
// Retrieve the stored credentials
```

See [Get a refresh token](#get-a-refresh-token) to learn how to obtain a [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens).

#### If you are not using refresh tokens

```swift
guard credentialsManager.hasValid() else {
    // No valid credentials exist, present the login page
}
// Retrieve the stored credentials
```

### Retrieve stored credentials

The credentials will be automatically renewed (if expired) using the [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens). **This method is thread-safe.**

See [Get a refresh token](#get-a-refresh-token) to learn how to obtain a refresh token.

```swift
credentialsManager.credentials { result in 
    switch result {
    case .success(let credentials):
        print("Obtained credentials: \(credentials)")
    case .failure(let error):
        print("Failed with: \(error)") 
    }
}
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await credentialsManager.credentials()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
credentialsManager
    .credentials()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

> [!CAUTION]
> Do not call `store(credentials:)` afterward. The Credentials Manager automatically persists the renewed credentials. Since this method is thread-safe and `store(credentials:)` is not, calling it anyway can cause concurrency issues.

> [!CAUTION]
> To ensure that no concurrent renewal requests get made, do not call this method from multiple Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.

### Renew stored credentials

The `credentials()` method automatically renews the stored credentials when needed, using the [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens). However, you can also force a renewal using the `renew()` method. **This method is thread-safe**.

See [Get a refresh token](#get-a-refresh-token) to learn how to obtain a refresh token.

```swift
credentialsManager.renew { result in
    switch result {
    case .success(let credentials):
        print("Renewed credentials: \(credentials)")
    case .failure(let error):
        print("Failed with: \(error)")
    }
}
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await credentialsManager.renew()
    print("Renewed credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
credentialsManager
    .renew()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Renewed credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

> [!CAUTION]
> Do not call `store(credentials:)` afterward. The Credentials Manager automatically persists the renewed credentials. Since this method is thread-safe and `store(credentials:)` is not, calling it anyway can cause concurrency issues.

> [!CAUTION]
> To ensure that no concurrent renewal requests get made, do not call this method from multiple Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.

### Retrieve stored user information

The stored [ID token](https://auth0.com/docs/secure/tokens/id-tokens) contains a copy of the user information at the time of authentication (or renewal, if the credentials were renewed). That user information can be retrieved from the Keychain synchronously, without checking if the credentials expired.

```swift
let user = credentialsManager.user
```

To get the latest user information, you can use the `renew()` [method](#renew-stored-credentials). Calling this method will automatically update the stored user information. You can also use the `userInfo(withAccessToken:)` [method](#retrieve-user-information) of the Authentication API client, but it will not update the stored user information.

### Clear stored credentials

The stored credentials can be removed from the Keychain by using the `clear()` method.

```swift
let didClear = credentialsManager.clear()
```

### Biometric authentication

You can enable an additional level of user authentication before retrieving credentials using the biometric authentication supported by the device, such as Face ID or Touch ID.

```swift
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID")
```

If needed, you can specify a particular `LAPolicy` to be used. For example, you might want to support Face ID or Touch ID, but also allow fallback to passcode.

```swift
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID or passcode", 
                                    evaluationPolicy: .deviceOwnerAuthentication)
```

> [!NOTE]
> Retrieving the user information with `credentialsManager.user` will not be protected by biometric authentication.

### Other credentials

#### API credentials [EA]

> [!NOTE]
> This feature is currently available in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant.

When the user logs in, you can request an access token for a specific API by passing its API identifier as the [audience](#add-an-audience-value) value. The access token in the resulting credentials can then be used to make authenticated requests to that API.

However, if you need an access token for a different API, you can exchange the [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens) for credentials containing an access token specific to this other API. **This method is thread-safe**.

> [!IMPORTANT]
> Currently, only the Auth0 My Account API is supported. Support for other APIs will be added in the future.

```swift
credentialsManager.apiCredentials(forAudience: "https://example.com/me",
                                  scope: "create:me:authentication_methods") { result in
    switch result {
    case .success(let apiCredentials):
        print("Obtained API credentials: \(apiCredentials)")
    case .failure(let error):
        print("Failed with: \(error)")
    }
}
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let apiCredentials = try await credentialsManager.apiCredentials(forAudience: "https://example.com/me",
                                                                     scope: "create:me:authentication_methods")
    print("Obtained API credentials: \(apiCredentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
credentialsManager
    .apiCredentials(forAudience: "https://example.com/me",
                    scope: "create:me:authentication_methods")
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { apiCredentials in
        print("Obtained API credentials: \(apiCredentials)")
    })
    .store(in: &cancellables)
```
</details>

See [Get a refresh token](#get-a-refresh-token) to learn how to obtain a refresh token.

> [!CAUTION]
> To ensure that no concurrent exchange requests get made, do not call this method from multiple Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.

#### SSO credentials [EA]

> [!NOTE]  
> This feature is currently available in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant.

To implement single sign-on (SSO) with Universal Login, you can use either `ASWebAuthenticationSession` or `SFSafariViewController` as the in-app browser. Each [has its own advantages and disadvantages](https://auth0.github.io/Auth0.swift/documentation/auth0/useragents), and suit different use cases.

An alternative way to implement SSO is by making use of a session transfer token. This is a single-use, short-lived token you must send to your website –either via query parameter or cookie– when opening it from your app. Your website then needs to redirect the user to Auth0's `/authorize` endpoint, passing along the session transfer token. Auth0 will set the respective session cookies and then redirect the user back to your website. Now, the user will be logged in on your website too. **This solution will work with any browser and webview –even standalone browser apps**.

First, you need to exchange the [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens) for a set of SSO credentials containing a session transfer token. **This method is thread-safe**.

```swift
credentialsManager.ssoCredentials { result in
    switch result {
    case .success(let ssoCredentials):
        print("Obtained SSO credentials: \(ssoCredentials)")
    case .failure(let error):
        print("Failed with: \(error)")
    }
}
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let ssoCredentials = try await credentialsManager.ssoCredentials()
    print("Obtained SSO credentials: \(ssoCredentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
credentialsManager
    .ssoCredentials()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { ssoCredentials in
        print("Obtained SSO credentials: \(ssoCredentials)")
    })
    .store(in: &cancellables)
```
</details>

See [Get a refresh token](#get-a-refresh-token) to learn how to obtain a refresh token.

> [!CAUTION]
> To ensure that no concurrent exchange requests get made, do not call this method from multiple Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.

Then, when opening your website on any browser or web view, add the session transfer token to the URL as a query parameter.
For example, `https://example.com/login?session_transfer_token=THE_TOKEN`.

If you're using `WKWebView` to open your website, you can place the session transfer token inside a cookie instead. It will be automatically sent to the `/authorize` endpoint.

```swift
let cookie = HTTPCookie(properties: [
    .domain: "YOUR_AUTH0_DOMAIN", // Or custom domain, if your website is using one
    .path: "/",
    .name: "auth0_session_transfer_token",
    .value: ssoCredentials.sessionTransferToken,
    .expires: ssoCredentials.expiresIn,
    .secure: true
])!

webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
```

> [!IMPORTANT]
> Make sure the cookie's domain matches the Auth0 domain your *website* is using, regardless of the one your mobile app is using. Otherwise, the `/authorize` endpoint will not receive the cookie. If your website is using the default Auth0 domain (like `example.us.auth0.com`), set the cookie's domain to this value. On the other hand, if your website is using a custom domain, use this value instead.

### Credentials Manager errors

The Credentials Manager will only produce `CredentialsManagerError` error values. You can find the underlying error (if any) in the `cause: Error?` property of the `CredentialsManagerError`. Not all error cases will have an underlying `cause`. Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/credentialsmanagererror) to learn more about the error cases you need to handle, and which ones include a `cause` value.

> [!WARNING]
> Do not parse or otherwise rely on the error messages to handle the errors. The error messages are not part of the API and can change. Run a switch statement on the [error cases](https://auth0.github.io/Auth0.swift/documentation/auth0/credentialsmanagererror/#topics) instead, which are part of the API.

[Go up ⤴](#examples)

## Authentication API (iOS / macOS / tvOS / watchOS / visionOS)

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/authentication)**

- [Log in with database connection](#log-in-with-database-connection)
- [Sign up with database connection](#sign-up-with-database-connection)
- [Log in with passkey [EA]](#log-in-with-passkey-ea)
- [Sign up with passkey [EA]](#sign-up-with-passkey-ea)
- [Passwordless login](#passwordless-login)
- [Retrieve user information](#retrieve-user-information)
- [Renew credentials](#renew-credentials)
- [Get SSO credentials [EA]](#get-sso-credentials-ea)
- [Authentication API client configuration](#authentication-api-client-configuration)
- [Authentication API client errors](#authentication-api-client-errors)

The Authentication API exposes the AuthN/AuthZ functionality of Auth0, as well as the supported identity protocols like OpenID Connect, OAuth 2.0, and SAML.
We recommend using [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login), but if you prefer to build your own UI you can use our API endpoints to do so. However, some Auth flows (grant types) are disabled by default so you must enable them in the settings page of your [Auth0 application](https://manage.auth0.com/#/applications/), as explained in [Update Grant Types](https://auth0.com/docs/get-started/applications/update-grant-types).

For login or signup with username/password, the `Password` grant type needs to be enabled in your Auth0 application. If you set the grants via the Management API you should activate both `http://auth0.com/oauth/grant-type/password-realm` and `Password`. Otherwise, the Auth0 Dashboard will take care of activating both when enabling `Password`.

> [!NOTE] 
> If your Auth0 tenant has the **Bot Detection** feature enabled, your requests might be flagged for verification. Check how to handle this scenario in the [Bot Detection](#bot-detection) section.

> [!WARNING]
> The ID tokens obtained from Web Auth login are automatically validated by Auth0.swift, ensuring their contents have not been tampered with. **This is not the case for the ID tokens obtained from the Authentication API client**, including the ones received when renewing the credentials using the refresh token. You must [validate](https://auth0.com/docs/secure/tokens/id-tokens/validate-id-tokens) any ID tokens received from the Authentication API client before using the information they contain.

### Log in with database connection

```swift
Auth0
    .authentication()
    .login(usernameOrEmail: "support@auth0.com",
           password: "secret-password",
           realmOrConnection: "Username-Password-Authentication",
           scope: "openid profile email offline_access")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .login(usernameOrEmail: "support@auth0.com",
               password: "secret-password",
               realmOrConnection: "Username-Password-Authentication",
               scope: "openid profile email offline_access")
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .login(usernameOrEmail: "support@auth0.com",
           password: "secret-password",
           realmOrConnection: "Username-Password-Authentication",
           scope: "openid profile email offline_access")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

> [!NOTE]
> The default scope value is `openid profile email`. Regardless of the scope value specified, `openid` is always included.

### Sign up with database connection

```swift
Auth0
    .authentication()
    .signup(email: "support@auth0.com",
            password: "secret-password",
            connection: "Username-Password-Authentication",
            userMetadata: ["first_name": "John", "last_name": "Appleseed"])
    .start { result in
        switch result {
        case .success(let user):
            print("User signed up: \(user)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

You might want to log the user in after signup. See [Log in with database connection](#log-in-with-database-connection) above for an example.

<details>
  <summary>Using async/await</summary>

```swift
do {
    let user = try await Auth0
        .authentication()
        .signup(email: "support@auth0.com",
                password: "secret-password",
                connection: "Username-Password-Authentication",
                userMetadata: ["first_name": "John", "last_name": "Appleseed"])
        .start()
    print("User signed up: \(user)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .signup(email: "support@auth0.com",
            password: "secret-password",
            connection: "Username-Password-Authentication",
            userMetadata: ["first_name": "John", "last_name": "Appleseed"])
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { user in
        print("User signed up: \(user)")
    })
    .store(in: &cancellables)
```
</details>

### Log in with passkey [EA]

> [!NOTE]
> This feature is currently available in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant.

Logging a user in with a passkey is a three-step process. First, you request a login challenge from Auth0. Then, you pass that challenge to Apple's [`AuthenticationServices`](https://developer.apple.com/documentation/authenticationservices) APIs to request an **existing passkey credential**. Finally, you use the resulting passkey credential and the original challenge to log the user in.

#### Prerequisites

- A custom domain configured for your Auth0 tenant.
- The **Passkeys** grant to be enabled for your Auth0 application.
- The iOS **Device Settings** configured for your Auth0 application.

Check [our documentation](https://auth0.com/docs/native-passkeys-for-mobile-applications#before-you-begin) for more information.

#### 1. Request a login challenge

If a database connection name is not specified, your tenant's default directory will be used.

```swift
Auth0
    .authentication()
    .passkeyLoginChallenge(connection: "Username-Password-Authentication")
    .start { result in
        switch result {
        case .success(let loginChallenge):
            print("Obtained login challenge: \(loginChallenge)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let loginChallenge = try await Auth0
        .authentication()
        .passkeyLoginChallenge(connection: "Username-Password-Authentication")
        .start()
    print("Obtained login challenge: \(loginChallenge)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .passkeyLoginChallenge(connection: "Username-Password-Authentication")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { loginChallenge in
        print("Obtained login challenge: \(loginChallenge)")
    })
    .store(in: &cancellables)
```
</details>

#### 2. Request an existing passkey credential

Use the login challenge with [`ASAuthorizationPlatformPublicKeyCredentialProvider`](https://developer.apple.com/documentation/authenticationservices/asauthorizationplatformpublickeycredentialprovider) from the `AuthenticationServices` framework to request an existing passkey credential. Check out [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Connect-to-a-service-with-an-existing-account) to learn more.

```swift
let credentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
    relyingPartyIdentifier: loginChallenge.relyingPartyId
)

let request = credentialProvider.createCredentialAssertionRequest(
    challenge: loginChallenge.challengeData
)

let authController = ASAuthorizationController(authorizationRequests: [request])
authController.delegate = self // ASAuthorizationControllerDelegate
authController.presentationContextProvider = self
authController.performRequests()
```

The resulting passkey credential will be delivered through the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate) delegate.

```swift
func authorizationController(controller: ASAuthorizationController,
                             didCompleteWithAuthorization authorization: ASAuthorization) {
    switch authorization.credential {
    case let loginPasskey as ASAuthorizationPlatformPublicKeyCredentialAssertion:
        // ...
    default:
        print("Unrecognized credential: \(authorization.credential)")
    }

    // ...
}
```

#### 3. Log the user in

Use the resulting passkey credential and the login challenge to log the user in.

```swift
Auth0
    .authentication()
    .login(passkey: loginPasskey,
           challenge: loginChallenge,
           connection: "Username-Password-Authentication",
           scope: "openid profile email offline_access")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .login(passkey: loginPasskey,
               challenge: loginChallenge,
               connection: "Username-Password-Authentication",
               scope: "openid profile email offline_access")
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .login(passkey: loginPasskey,
           challenge: loginChallenge,
           connection: "Username-Password-Authentication",
           scope: "openid profile email offline_access")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

### Sign up with passkey [EA]

> [!NOTE]
> This feature is currently available in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant.

Signing a user up with a passkey is a three-step process. First, you request a signup challenge from Auth0. Then, you pass that challenge to Apple's [`AuthenticationServices`](https://developer.apple.com/documentation/authenticationservices) APIs to create a **new passkey credential**. Finally, you use the created passkey credential and the original challenge to log the new user in.

#### Prerequisites

- A custom domain configured for your Auth0 tenant.
- The **Passkeys** grant to be enabled for your Auth0 application.
- The iOS **Device Settings** configured for your Auth0 application.

Check [our documentation](https://auth0.com/docs/native-passkeys-for-mobile-applications#before-you-begin) for more information.

#### 1. Request a signup challenge

You need to provide at least one user identifier when requesting the challenge, along with an optional user display name, and an optional database connection name. If a connection name is not specified, your tenant's default directory will be used.

By default, database connections require a valid `email`. If you have enabled [Flexible Identifiers](https://auth0.com/docs/authenticate/database-connections/activate-and-configure-attributes-for-flexible-identifiers) for your database connection, you may use any combination of `email`, `phoneNumber`, or `username`. These user identifiers can be required or optional and must match your Flexible Identifiers configuration.

```swift
Auth0
    .authentication()
    .passkeySignupChallenge(email: "support@auth0.com",
                            name: "John Appleseed",
                            connection: "Username-Password-Authentication")
    .start { result in
        switch result {
        case .success(let signupChallenge):
            print("Obtained signup challenge: \(signupChallenge)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let signupChallenge = try await Auth0
        .authentication()
        .passkeySignupChallenge(email: "support@auth0.com",
                                name: "John Appleseed",
                                connection: "Username-Password-Authentication")
        .start()
    print("Obtained signup challenge: \(signupChallenge)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .passkeySignupChallenge(email: "support@auth0.com",
                            name: "John Appleseed",
                            connection: "Username-Password-Authentication")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { signupChallenge in
        print("Obtained signup challenge: \(signupChallenge)")
    })
    .store(in: &cancellables)
```
</details>

#### 2. Create a new passkey credential

Use the signup challenge with [`ASAuthorizationPlatformPublicKeyCredentialProvider`](https://developer.apple.com/documentation/authenticationservices/asauthorizationplatformpublickeycredentialprovider) from the `AuthenticationServices` framework to generate a new passkey credential. Check out [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Register-a-new-account-on-a-service) to learn more.

```swift
let credentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
    relyingPartyIdentifier: signupChallenge.relyingPartyId
)

let request = credentialProvider.createCredentialRegistrationRequest(
    challenge: signupChallenge.challengeData,
    name: signupChallenge.userName,
    userID: signupChallenge.userId
)

let authController = ASAuthorizationController(authorizationRequests: [request])
authController.delegate = self // ASAuthorizationControllerDelegate
authController.presentationContextProvider = self
authController.performRequests()
```

The created passkey credential will be delivered through the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate) delegate.

```swift
func authorizationController(controller: ASAuthorizationController,
                             didCompleteWithAuthorization authorization: ASAuthorization) {
    switch authorization.credential {
    case let signupPasskey as ASAuthorizationPlatformPublicKeyCredentialRegistration:
        // ...
    default:
        print("Unrecognized credential: \(authorization.credential)")
    }

    // ...
}
```

#### 3. Log the new user in

Use the created passkey credential and the signup challenge to log the new user in. This completes the signup process.

```swift
Auth0
    .authentication()
    .login(passkey: signupPasskey,
           challenge: signupChallenge,
           connection: "Username-Password-Authentication",
           scope: "openid profile email offline_access")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .login(passkey: signupPasskey,
               challenge: signupChallenge,
               connection: "Username-Password-Authentication",
               scope: "openid profile email offline_access")
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .login(passkey: signupPasskey,
           challenge: signupChallenge,
           connection: "Username-Password-Authentication",
           scope: "openid profile email offline_access")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

### Passwordless login

Passwordless is a two-step authentication flow that requires the **Passwordless OTP** grant to be enabled for your Auth0 application. Check [our documentation](https://auth0.com/docs/get-started/applications/application-grant-types) for more information.

#### 1. Start the passwordless flow

Request a code to be sent to the user's email or phone number. For email scenarios, a link can be sent in place of the code.

```swift
Auth0
    .authentication()
    .startPasswordless(email: "support@auth0.com")
    .start { result in
        switch result {
        case .success:
            print("Code sent")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    try await Auth0
        .authentication()
        .startPasswordless(email: "support@auth0.com")
        .start()
    print("Code sent")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .startPasswordless(email: "support@auth0.com")
    .start()
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Code sent")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }, receiveValue: {})
    .store(in: &cancellables)
```
</details>

> [!NOTE]
> Use `startPasswordless(phoneNumber:)` to send a code to the user's phone number instead.

#### 2. Login with the received code

To complete the authentication, you must send back that code the user received along with the email or phone number used to start the flow.

```swift
Auth0
    .authentication()
    .login(email: "support@auth0.com", code: "123456")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .login(email: "support@auth0.com", code: "123456")
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .login(email: "support@auth0.com", code: "123456")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

> [!NOTE]
> Use `login(phoneNumber:code:)` if the code was sent to the user's phone number.

### Retrieve user information

Fetch the latest user information from the `/userinfo` endpoint.

This method will yield a `UserInfo` instance. Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/userinfo) to learn more about its available properties.

```swift
Auth0
   .authentication()
   .userInfo(withAccessToken: credentials.accessToken)
   .start { result in
       switch result {
       case .success(let user):
           print("Obtained user: \(user)")
       case .failure(let error):
           print("Failed with: \(error)")
       }
   }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let user = try await Auth0
        .authentication()
        .userInfo(withAccessToken: credentials.accessToken)
        .start()
    print("Obtained user: \(user)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .userInfo(withAccessToken: credentials.accessToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { user in
        print("Obtained user: \(user)")
    })
    .store(in: &cancellables)
```
</details>

### Renew credentials

Use a [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens) to renew the user's credentials. It is recommended that you read and understand the refresh token process beforehand.

See [Get a refresh token](#get-a-refresh-token) to learn how to obtain a refresh token.

```swift
Auth0
    .authentication()
    .renew(withRefreshToken: credentials.refreshToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained new credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .renew(withRefreshToken: credentials.refreshToken)
        .start()
    print("Obtained new credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .renew(withRefreshToken: credentials.refreshToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained new credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

### Get SSO credentials [EA]

> [!NOTE]  
> This feature is currently available in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant.

To implement single sign-on (SSO) with Universal Login, you can use either `ASWebAuthenticationSession` or `SFSafariViewController` as the in-app browser. Each [has its own advantages and disadvantages](https://auth0.github.io/Auth0.swift/documentation/auth0/useragents), and suit different use cases.

An alternative way to implement SSO is by making use of a session transfer token. This is a one-use, short-lived token you must send to your website –either via query parameter or cookie– when opening it from your app. Your website then needs to redirect the user to Auth0's `/authorize` endpoint, passing along the session transfer token. Auth0 will set the respective session cookies and then redirect the user back to your website. Now, the user will be logged in on your website too. **This solution will work with any browser and webview –even standalone browser apps**.

First, you need to exchange the [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens) for a set of SSO credentials containing a session transfer token.

```swift
Auth0
    .authentication()
    .ssoExchange(withRefreshToken: credentials.refreshToken)
    .start { result in
        switch result {
        case .success(let ssoCredentials):
            print("Obtained SSO credentials: \(ssoCredentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let ssoCredentials = try await Auth0
        .authentication()
        .ssoExchange(withRefreshToken: credentials.refreshToken)
        .start()
    print("Obtained SSO credentials: \(ssoCredentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .ssoExchange(withRefreshToken: credentials.refreshToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { ssoCredentials in
        print("Obtained SSO credentials: \(ssoCredentials)")
    })
    .store(in: &cancellables)
```
</details>

See [Get a refresh token](#get-a-refresh-token) to learn how to obtain a refresh token.

> [!IMPORTANT]
> You don't need to store the SSO credentials. The session transfer token is single-use and short-lived. However, if you're using [refresh token rotation](https://auth0.com/docs/secure/tokens/refresh-tokens/refresh-token-rotation), you will get a new refresh token with the SSO credentials. You should store the new refresh token, replacing the previous one that is now invalid.
>
> If you're using the Credentials Manager to store the user's credentials, you should use its `ssoCredentials()` method to perform the exchange. It will automatically handle the refresh tokens for you. And it's also thread-safe, whereas this method is not.

Then, when opening your website on any browser or web view, add the session transfer token to the URL as a query parameter.
For example, `https://example.com/login?session_transfer_token=THE_TOKEN`.

If you're using `WKWebView` to open your website, you can place the session transfer token inside a cookie instead. It will be automatically sent to the `/authorize` endpoint.

```swift
let cookie = HTTPCookie(properties: [
    .domain: "YOUR_AUTH0_DOMAIN", // Or custom domain, if your website is using one
    .path: "/",
    .name: "auth0_session_transfer_token",
    .value: ssoCredentials.sessionTransferToken,
    .expires: ssoCredentials.expiresIn,
    .secure: true
])!

webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
```

> [!IMPORTANT]
> Make sure the cookie's domain matches the Auth0 domain your *website* is using, regardless of the one your mobile app is using. Otherwise, the `/authorize` endpoint will not receive the cookie. If your website is using the default Auth0 domain (like `example.us.auth0.com`), set the cookie's domain to this value. On the other hand, if your website is using a custom domain, use this value instead.

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

### Authentication API client errors

The Authentication API client will only produce `AuthenticationError` error values.

- The `info` property contains additional information about the error.
- The `cause` property contains the underlying error value, if any.
- Use the `isNetworkError` property to check if the request failed due to networking issues.

Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/authenticationerror) to learn more about the available `AuthenticationError` properties.

> [!WARNING]
> Do not parse or otherwise rely on the error messages to handle the errors. The error messages are not part of the API and can change. Use the [error types](https://auth0.github.io/Auth0.swift/documentation/auth0/authenticationerror/#topics) instead, which are part of the API.

[Go up ⤴](#examples)

## My Account API (iOS / macOS / tvOS / watchOS / visionOS) [EA]

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/myaccount)**

- [Enroll a new passkey](#enroll-a-new-passkey)
- [My Account API client errors](#my-account-api-client-errors)

> [!NOTE]
> The My Account API is currently available in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant.

Use the Auth0 My Account API to manage the current user's account.

To call the My Account API, you need an access token issued specifically for this API, including any required scopes for the operations you want to perform. See [API credentials [EA]](#api-credentials-ea) to learn how to obtain one.

### Enroll a new passkey

**Scopes required:** `create:me:authentication_methods`

Enrolling a new passkey is a three-step process. First, you request an enrollment challenge from Auth0. Then, you pass that challenge to Apple's [`AuthenticationServices`](https://developer.apple.com/documentation/authenticationservices) APIs to create a new passkey credential. Finally, you use the created passkey credential and the original challenge to enroll the passkey with Auth0.

#### Prerequisites

- A custom domain configured for your Auth0 tenant.
- The **Passkeys** grant to be enabled for your Auth0 application.
- The iOS **Device Settings** configured for your Auth0 application.

Check [our documentation](https://auth0.com/docs/native-passkeys-for-mobile-applications#before-you-begin) for more information.

#### 1. Request an enrollment challenge

You can specify an optional user identity identifier and/or a database connection name to help Auth0 find the user. The user identity identifier will be needed if the user logged in with a [linked account](https://auth0.com/docs/manage-users/user-accounts/user-account-linking).

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .passkeyEnrollmentChallenge()
    .start { result in
        switch result {
        case .success(let enrollmentChallenge):
            print("Obtained enrollment challenge: \(enrollmentChallenge)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let enrollmentChallenge = try await Auth0
        .myAccount(token: apiCredentials.accessToken)
        .authenticationMethods
        .passkeyEnrollmentChallenge()
        .start()
    print("Obtained enrollment challenge: \(enrollmentChallenge)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .passkeyEnrollmentChallenge()
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { enrollmentChallenge in
        print("Obtained enrollment challenge: \(enrollmentChallenge)")
    })
    .store(in: &cancellables)
```
</details>

#### 2. Create a new passkey credential

Use the enrollment challenge with [`ASAuthorizationPlatformPublicKeyCredentialProvider`](https://developer.apple.com/documentation/authenticationservices/asauthorizationplatformpublickeycredentialprovider) from the `AuthenticationServices` framework to generate a new passkey credential. Check out [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Register-a-new-account-on-a-service) to learn more.

```swift
let credentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
    relyingPartyIdentifier: enrollmentChallenge.relyingPartyId
)

let request = credentialProvider.createCredentialRegistrationRequest(
    challenge: enrollmentChallenge.challengeData,
    name: enrollmentChallenge.userName,
    userID: enrollmentChallenge.userId
)

let authController = ASAuthorizationController(authorizationRequests: [request])
authController.delegate = self // ASAuthorizationControllerDelegate
authController.presentationContextProvider = self
authController.performRequests()
```

The created passkey credential will be delivered through the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate) delegate.

```swift
func authorizationController(controller: ASAuthorizationController,
                             didCompleteWithAuthorization authorization: ASAuthorization) {
    switch authorization.credential {
    case let newPasskey as ASAuthorizationPlatformPublicKeyCredentialRegistration:
        // ...
    default:
        print("Unrecognized credential: \(authorization.credential)")
    }

    // ...
}
```

#### 3. Enroll the passkey

Use the created passkey credential and the enrollment challenge to enroll the passkey with Auth0.

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .enroll(passkey: newPasskey,
            challenge: enrollmentChallenge)
    .start { result in
        switch result {
        case .success(let authenticationMethod):
            print("Enrolled passkey: \(authenticationMethod)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let authenticationMethod = try await Auth0
        .myAccount(token: apiCredentials.accessToken)
        .authenticationMethods
        .enroll(passkey: newPasskey,
                challenge: enrollmentChallenge)
        .start()
    print("Enrolled passkey: \(authenticationMethod)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .enroll(passkey: newPasskey,
            challenge: enrollmentChallenge)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticationMethod in
        print("Enrolled passkey: \(authenticationMethod)")
    })
    .store(in: &cancellables)
```
</details>

### My Account API client errors

The My Account API client will only produce `MyAccountError` error values.

- The `info` property contains additional information about the error.
- The `cause` property contains the underlying error value, if any.
- Use the `isNetworkError` property to check if the request failed due to networking issues.

See the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/myaccounterror) to learn more about the available `MyAccountError` properties.

[Go up ⤴](#examples)

## Management API (Users) (iOS / macOS / tvOS / watchOS / visionOS)

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/users)**

- [Retrieve user metadata](#retrieve-user-metadata)
- [Update user metadata](#update-user-metadata)
- [Link an account](#link-an-account)
- [Management API client configuration](#management-api-client-configuration)
- [Management API client errors](#management-api-client-errors)

You can request more information from a user's profile and manage the user's metadata by accessing the Auth0 [Management API](https://auth0.com/docs/api/management/v2).

To call the Management API, you need an access token that has the API Identifier of the Management API as a target [audience](https://auth0.com/docs/secure/tokens/access-tokens/get-access-tokens#control-access-token-audience) value. Specify `https://YOUR_AUTH0_DOMAIN/api/v2/` as the audience when logging in to achieve this. 

For example, if you are using Web Auth:

```swift
Auth0
    .webAuth()
    .audience("https://YOUR_AUTH0_DOMAIN/api/v2/")
    // ...
```

> [!NOTE]
> For security reasons, mobile apps are restricted to a subset of the Management API functionality.

> [!IMPORTANT]
> Auth0 access tokens [do not support](https://community.auth0.com/t/how-do-i-specify-multiple-audiences/10830) multiple custom audience values. If you are already using the API Identifier of your own API as the audience because you need to make authenticated requests to your backend, you cannot add the Management API one, and vice versa. Consider instead exposing API endpoints in your backend to perform operations that require interacting with the Management API, and then calling them from your app.

### Retrieve user metadata

To call this method, you must request the `read:current_user` scope when logging in. You can get the user ID value from the `sub` [claim](https://auth0.com/docs/get-started/apis/scopes/openid-connect-scopes#standard-claims) of the user's ID token, or from the `sub` property of a `UserInfo` instance.

```swift
Auth0
    .users(token: credentials.accessToken)
    .get("user-id", fields: ["user_metadata"])
    .start { result in
        switch result {
        case .success(let user):
            print("Obtained user with metadata: \(user)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let user = try await Auth0
        .users(token: credentials.accessToken)
        .get("user-id", fields: ["user_metadata"])
        .start()
    print("Obtained user with metadata: \(user)") 
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .users(token: credentials.accessToken)
    .get("user-id", fields: ["user_metadata"])
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { user in
        print("Obtained user with metadata: \(user)")
    })
    .store(in: &cancellables)
```
</details>

> [!TIP]
> An alternative is to use a [post-login Action](https://auth0.com/docs/customize/actions/flows-and-triggers/login-flow/api-object) to add the metadata to the ID token as a custom claim.

### Update user metadata

To call this method, you must request the `update:current_user_metadata` scope when logging in. You can get the user ID value from the `sub` [claim](https://auth0.com/docs/get-started/apis/scopes/openid-connect-scopes#standard-claims) of the user's ID token, or from the `sub` property of a `UserInfo` instance.

```swift
Auth0
    .users(token: credentials.accessToken)
    .patch("user-id", 
           userMetadata: ["first_name": "John", "last_name": "Appleseed"])
    .start { result in
        switch result {
        case .success(let user):
            print("Updated user: \(user)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let user = try await Auth0
        .users(token: credentials.accessToken)
        .patch("user-id", 
               userMetadata: ["first_name": "John", "last_name": "Appleseed"])
        .start()
    print("Updated user: \(user)") 
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .users(token: credentials.accessToken)
    .patch("user-id", 
           userMetadata: ["first_name": "John", "last_name": "Appleseed"])
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { user in
        print("Updated user: \(user)") 
    })
    .store(in: &cancellables)
```
</details>

### Link an account

Your users may want to link their other accounts to the account they are logged in to. To achieve this, you need the user ID for the primary account and the idToken for the secondary account. You also need to request the `update:current_user_identities` scope when logging in.

You can get the primary user ID value from the `sub` [claim](https://auth0.com/docs/get-started/apis/scopes/openid-connect-scopes#standard-claims) of the primary user's ID token, or from the `sub` property of a `UserInfo` instance.

```swift
Auth0
    .users(token: credentials.accessToken)
    .link("primary-user-id", withOtherUserToken: "secondary-id-token")
    .start { result in
        switch result {
        case .success:
            print("Accounts linked")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    _ = try await Auth0
        .users(token: credentials.accessToken)
        .link("primary-user-id", withOtherUserToken: "secondary-id-token")
        .start()
    print("Accounts linked")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .users(token: credentials.accessToken)
    .link("primary-user-id", withOtherUserToken: "secondary-id-token")
    .start()
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Accounts linked")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }, receiveValue: { _ in })
    .store(in: &cancellables)
```
</details>

### Management API client configuration

#### Add custom parameters

Use the `parameters()` method to add custom parameters to any request.

```swift
Auth0
    .users(token: credentials.accessToken)
    .patch(userId, userMetadata: userMetadata) // Any request
    .parameters(["key": "value"])
    // ...
```

#### Add custom headers

Use the `headers()` method to add custom headers to any request.

```swift
Auth0
    .users(token: credentials.accessToken)
    .patch(userId, userMetadata: userMetadata) // Any request
    .headers(["key": "value"])
    // ...
```

#### Use a custom `URLSession` instance

You can specify a custom `URLSession` instance for more advanced networking configuration, such as customizing timeout values.

```swift
Auth0
    .users(session: customURLSession)
    // ...
```

### Management API client errors

The Management API client will only produce `ManagementError` error values.

- The `info` property contains additional information about the error.
- The `cause` property contains the underlying error value, if any.
- Use the `isNetworkError` property to check if the request failed due to networking issues.

Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/managementerror) to learn more about the available `ManagementError` properties.

[Go up ⤴](#examples)

## Logging

Auth0.swift can print HTTP requests and responses for debugging purposes. Enable it by calling the following method in either `WebAuth`, `Authentication` or `Users`:

```swift
Auth0
    .webAuth()
    .logging(enabled: true)
    // ...
```

> [!CAUTION]
> Set this flag only when **DEBUGGING** to avoid leaking user's credentials in the device log.

With a successful authentication you should see something similar to the following:

```text
ASWebAuthenticationSession: https://example.us.auth0.com/authorize?.....
Callback URL: com.example.MyApp://example.us.auth0.com/ios/com.example.MyApp/callback?...
POST https://example.us.auth0.com/oauth/token HTTP/1.1
Content-Type: application/json
Auth0-Client: eyJ2ZXJzaW9uI...

{"code":"...","client_id":"...","grant_type":"authorization_code","redirect_uri":"com.example.MyApp:\/\/example.us.auth0.com\/ios\/com.example.MyApp\/callback","code_verifier":"..."}

HTTP/1.1 200
Pragma: no-cache
Content-Type: application/json
Strict-Transport-Security: max-age=3600
Date: Wed, 27 Apr 2022 19:04:39 GMT
Content-Length: 57
Cache-Control: no-cache
Connection: keep-alive

{"access_token":"...","token_type":"Bearer"}
```

> [!TIP]
> When troubleshooting, you can also check the logs in the [Auth0 Dashboard](https://manage.auth0.com/#/logs) for more information.

[Go up ⤴](#examples)

## Advanced Features

- [Native social login](#native-social-login)
- [Organizations](#organizations)
- [Bot detection](#bot-detection)

### Native social login

#### Sign in With Apple

If you've added the [Sign In with Apple flow](https://developer.apple.com/documentation/authenticationservices/implementing_user_authentication_with_sign_in_with_apple) to your app, after a successful Sign in With Apple authentication you can use the value of the `authorizationCode` property to perform a code exchange for Auth0 credentials.

```swift
Auth0
    .authentication()
    .login(appleAuthorizationCode: "auth-code")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .login(appleAuthorizationCode: "auth-code")
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .login(appleAuthorizationCode: "auth-code")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

> [!NOTE]
> See the [Setting up Sign In with Apple](https://auth0.com/docs/authenticate/identity-providers/social-identity-providers/apple-native) guide for more information about integrating Sign In with Apple with Auth0.

#### Facebook Login

If you've added the [Facebook Login flow](https://developers.facebook.com/docs/facebook-login/ios) to your app, after a successful Facebook authentication you can request a [session info access token](https://developers.facebook.com/docs/facebook-login/guides/access-tokens/get-session-info) and the Facebook user profile, and then use them both to perform a token exchange for Auth0 credentials.

```swift
Auth0
    .authentication()
    .login(facebookSessionAccessToken: "session-info-access-token",
           profile: ["key": "value"])
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .login(facebookSessionAccessToken: "session-info-access-token",
               profile: ["key": "value"])
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .login(facebookSessionAccessToken: "session-info-access-token",
           profile: ["key": "value"])
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

> [!NOTE]
> See the [Setting up Facebook Login](https://auth0.com/docs/authenticate/identity-providers/social-identity-providers/facebook-native) guide for more information about integrating Facebook Login with Auth0.

### Organizations

[Organizations](https://auth0.com/docs/manage-users/organizations) is a set of features that provide better support for developers who build and maintain SaaS and Business-to-Business (B2B) apps. 

> [!NOTE]
> Organizations is currently only available to customers on our Enterprise and Startup subscription plans.

#### Log in to an organization

```swift
Auth0
    .webAuth()
    .organization("YOUR_AUTH0_ORGANIZATION_NAME_OR_ID")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await Auth0
        .webAuth()
        .organization("YOUR_AUTH0_ORGANIZATION_NAME_OR_ID")
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .webAuth()
    .organization("YOUR_AUTH0_ORGANIZATION_NAME_OR_ID")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

#### Accept user invitations

To accept organization invitations your app needs to support [Universal Links](https://developer.apple.com/documentation/xcode/allowing_apps_and_websites_to_link_to_your_content/supporting_universal_links_in_your_app), as invitation links are HTTPS-only. Tapping on the invitation link should open your app.

When your app gets opened by an invitation link, grab the invitation URL and pass it to `invitationURL()`.

```swift
guard let url = URLContexts.first?.url else { return }

// You need to wait for the app to enter the foreground before launching Web Auth
NotificationCenter.default
    .publisher(for: UIApplication.didBecomeActiveNotification)
    .subscribe(on: DispatchQueue.main)
    .prefix(1)
    .setFailureType(to: WebAuthError.self) // Necessary for iOS 13
    .flatMap { _ in
        Auth0
            .webAuth()
            .invitationURL(url) // 👈🏼
            .start()
    }
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```

### Bot Detection

If you are performing database login/signup via the Authentication API and would like to use the [Bot Detection](https://auth0.com/docs/secure/attack-protection/bot-detection) feature, you need to handle the `isVerificationRequired` error. It indicates that the request was flagged as suspicious and an additional verification step is necessary to log the user in. That verification step is web-based, so you need to use Web Auth to complete it.

```swift
Auth0
    .authentication()
    .login(usernameOrEmail: email, 
           password: password, 
           realmOrConnection: connection, 
           scope: scope)
    .start { result in
        switch result {
        case .success(let credentials): // ...
        case .failure(let error) where error.isVerificationRequired:
            DispatchQueue.main.async {
                Auth0
                    .webAuth()
                    .useHTTPS() // Use a Universal Link callback URL on iOS 17.4+ / macOS 14.4+
                    .connection(connection)
                    .scope(scope)
                    .useEphemeralSession() // Otherwise a session cookie will remain
                    .parameters(["login_hint": email]) // So the user doesn't have to type it again
                    .start { result in
                        // ...
                    }
            }
        case .failure(let error): // ...
        }
    }
```

In the case of signup, you can add an [additional parameter](#web-auth-signup) to make the user land directly on the signup page.

```swift
Auth0
    .webAuth()
    .parameters(["login_hint": email, "screen_hint": "signup"])
    // ...
```

Check how to set up Web Auth in the [Web Auth Configuration](#web-auth-configuration) section.

---

[Go up ⤴](#examples)
