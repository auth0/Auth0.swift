### Get SSO credentials

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

See [Get a refresh token](../web-auth/configuration.md#get-a-refresh-token) to learn how to obtain a refresh token.

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
    .expires: ssoCredentials.expiresAt,
    .secure: true
])!

webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
```

> [!IMPORTANT]
> Make sure the cookie's domain matches the Auth0 domain your *website* is using, regardless of the one your mobile app is using. Otherwise, the `/authorize` endpoint will not receive the cookie. If your website is using the default Auth0 domain (like `example.us.auth0.com`), set the cookie's domain to this value. On the other hand, if your website is using a custom domain, use this value instead.
