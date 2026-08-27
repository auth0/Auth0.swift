### Other credentials

#### API credentials [EA]

> [!NOTE]
> This feature is currently available in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant.

When the user logs in, you can request an access token for a specific API by passing its API identifier as the [audience](../web-auth/configuration.md#add-an-audience-value) value. The access token in the resulting credentials can then be used to make authenticated requests to that API.

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

See [Get a refresh token](../web-auth/configuration.md#get-a-refresh-token) to learn how to obtain a refresh token.

> [!CAUTION]
> To ensure that no concurrent exchange requests get made, do not call this method from multiple Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.

#### SSO credentials

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

See [Get a refresh token](../web-auth/configuration.md#get-a-refresh-token) to learn how to obtain a refresh token.

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
    .expires: ssoCredentials.expiresAt,
    .secure: true
])!

webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
```

> [!IMPORTANT]
> Make sure the cookie's domain matches the Auth0 domain your *website* is using, regardless of the one your mobile app is using. Otherwise, the `/authorize` endpoint will not receive the cookie. If your website is using the default Auth0 domain (like `example.us.auth0.com`), set the cookie's domain to this value. On the other hand, if your website is using a custom domain, use this value instead.
