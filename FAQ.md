# Frequently Asked Questions

- [1. How can I disable the _login_ alert box?](#1-how-can-i-disable-the-login-alert-box)
  - [If you don't need SSO](#if-you-dont-need-sso)
    - [Use ephemeral sessions](#use-ephemeral-sessions)
    - [Use `SFSafariViewController`](#use-sfsafariviewcontroller)
    - [Use `WKWebview`](#use-wkwebview)
  - [If you need SSO](#if-you-need-sso)
- [2. How can I disable the _logout_ alert box?](#2-how-can-i-disable-the-logout-alert-box)
- [3. How can I change the message in the alert box?](#3-how-can-i-change-the-message-in-the-alert-box)
- [4. How can I programmatically close the alert box?](#4-how-can-i-programmatically-close-the-alert-box)
- [5. How to resolve the _Failed to start this transaction, as there is an active transaction at the moment_ error?](#5-how-to-resolve-the-failed-to-start-this-transaction-as-there-is-an-active-transaction-at-the-moment-error)
  - [Workarounds](#workarounds)
    - [Clear the login transaction when handling the `transactionActiveAlready` error](#clear-the-login-transaction-when-handling-the-transactionactivealready-error)
    - [Clear the login transaction when the app moves to the background/foreground](#clear-the-login-transaction-when-the-app-moves-to-the-backgroundforeground)
    - [Avoid the login/logout alert box](#avoid-the-loginlogout-alert-box)

---

## 1. How can I disable the _login_ alert box?

![Screenshot of the SSO alert box](https://user-images.githubusercontent.com/5055789/198689762-8f3459a7-fdde-4c14-a13b-68933ef675e6.png)

Under the hood, Auth0.swift uses `ASWebAuthenticationSession` by default to perform web-based authentication, which is the [API provided by Apple](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) for such purpose.

That alert box is displayed and managed by `ASWebAuthenticationSession`, not by Auth0.swift, because by default this API will store the session cookie in the shared Safari cookie jar. This makes single sign-on (SSO) possible. According to Apple, that requires user consent.

> [!NOTE]
> See [this blog post](https://developer.okta.com/blog/2022/01/13/mobile-sso) for a detailed overview of SSO on iOS.

### If you don't need SSO

#### Use ephemeral sessions

You can disable this behavior by adding `provider(WebAuthentication.asProvider(ephemeralSession: true))` to the login call. This will configure `ASWebAuthenticationSession` to not store the session cookie in the shared cookie jar, as if using an incognito browser window. With no shared cookie, `ASWebAuthenticationSession` will not prompt the user for consent.

```swift
Auth0
    .webAuth()
    .provider(WebAuthentication.asProvider(ephemeralSession: true)) // No SSO, therefore no alert box
    .start { result in
        // ...
    }
```

Note that with ephemeral sessions you don't need to call `clearSession(federated:)` at all. Just clearing the credentials from the app will suffice. What `clearSession(federated:)` does is clear the shared session cookie, so that in the next login call the user gets asked to log in again. But with ephemeral sessions there will be no shared cookie to remove.

> [!NOTE]
> Ephemeral sessions rely on the `prefersEphemeralWebBrowserSession` configuration option of `ASWebAuthenticationSession`.

#### Use `SFSafariViewController`

See [Use `SFSafariViewController` instead of `ASWebAuthenticationSession`](EXAMPLES.md#use-sfsafariviewcontroller-instead-of-aswebauthenticationsession).

#### Use `WKWebview`

See [Use `WKWebview` instead of `ASWebAuthenticationSession`](EXAMPLES.md#use-wkwebview-instead-of-aswebauthenticationsession).

### If you need SSO

See:
- [`ASWebAuthenticationSession` vs `SFSafariViewController` (iOS)](https://auth0.github.io/Auth0.swift/documentation/auth0/useragents) to help determine if `SFSafariViewController` suits your use case, depending on your SSO requirements.
- [Use `SFSafariViewController` instead of `ASWebAuthenticationSession`](EXAMPLES.md#use-sfsafariviewcontroller-instead-of-aswebauthenticationsession) for the setup instructions.

## 2. How can I disable the _logout_ alert box?

![Screenshot of the SSO alert box](https://user-images.githubusercontent.com/5055789/198689762-8f3459a7-fdde-4c14-a13b-68933ef675e6.png)

Since `clearSession(federated:)` needs to use `ASWebAuthenticationSession` as well to clear the shared session cookie, the same alert box will be displayed. 

If you need SSO with `ASWebAuthenticationSession` and/or are willing to tolerate the alert box on the login call, but would prefer to do away with it when calling `clearSession(federated:)`, you can simply not call `clearSession(federated:)` and just clear the credentials from the app. This means that the shared session cookie will not be removed, so to get the user to log in again you need to add the `"prompt": "login"` parameter to the _login_ call.

```swift
Auth0
    .webAuth()
    .provider(WebAuthentication.asProvider(ephemeralSession: true))
    .parameters(["prompt": "login"]) // Ignore the cookie (if present) and show the login page
    .start { result in
        // ...
    }
```

Otherwise, the browser modal will close right away and the user will be automatically logged in again, as the cookie will still be there.

> [!WARNING]
> Keeping the shared session cookie may not be an option if you have strong privacy and/or security requirements, for example in the case of a banking app.

## 3. How can I change the message in the alert box?

Auth0.swift has no control whatsoever over the alert box. Its contents cannot be changed. Unfortunately, that is a limitation of `ASWebAuthenticationSession`.

## 4. How can I programmatically close the alert box?

Auth0.swift has no control whatsoever over the alert box. It cannot be closed programmatically. Unfortunately, that is a limitation of `ASWebAuthenticationSession`. 

## 5. How to resolve the _Failed to start this transaction, as there is an active transaction at the moment_ error?

Users might encounter this error when the app moves to the background and then back to the foreground while the login/logout alert box is displayed, for example by locking and unlocking the device. The alert box would get dismissed but when the user tries to log in again, the Web Auth operation fails with the `transactionActiveAlready` error.

This is a known issue with `ASWebAuthenticationSession` and it is not specific to Auth0.swift. We have already filed a bug report with Apple and are awaiting for a response from them.

### Workarounds

#### Clear the login transaction when handling the `transactionActiveAlready` error

You can invoke `WebAuthentication.cancel()` to manually clear the current login transaction upon encountering this error. Then, you can retry login. For example:

```swift
switch result {
case .failure(let error) where error == .transactionActiveAlready:
    WebAuthentication.cancel()
    // ... retry login
// ...
}
```

#### Clear the login transaction when the app moves to the background/foreground

You can invoke `WebAuthentication.cancel()` to manually clear the current login transaction when the app moves to the background or back to the foreground. However, you need to make sure to not cancel valid login attempts –for example, when the user switches briefly to another app while the login page is open.

#### Avoid the login/logout alert box

If you don't need SSO, consider using `ASWebAuthenticationSession` with ephemeral sessions, or using `SFSafariViewController` or `WKWebView` instead. See [1. How can I disable the _login_ alert box?](#1-how-can-i-disable-the-login-alert-box) for more information.

[Go up ⤴](#frequently-asked-questions)
