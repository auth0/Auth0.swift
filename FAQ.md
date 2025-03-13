# Frequently Asked Questions

- [1. How can I disable the _login_ alert box?](#1-how-can-i-disable-the-login-alert-box)
  - [Use ephemeral sessions](#use-ephemeral-sessions)
  - [Use `SFSafariViewController`](#use-sfsafariviewcontroller)
    - [1. Configure a custom URL scheme](#1-configure-a-custom-url-scheme)
    - [2. Capture the callback URL](#2-capture-the-callback-url)
- [2. How can I disable the _logout_ alert box?](#2-how-can-i-disable-the-logout-alert-box)
- [3. How can I change the message in the alert box?](#3-how-can-i-change-the-message-in-the-alert-box)
- [4. How can I programmatically close the alert box?](#4-how-can-i-programmatically-close-the-alert-box)
- [5. How to resolve the _Failed to start this transaction, as there is an active transaction at the moment_ error?](#5-how-to-resolve-the-failed-to-start-this-transaction-as-there-is-an-active-transaction-at-the-moment-error)

---

## 1. How can I disable the _login_ alert box?

![Screenshot of the SSO alert box](https://user-images.githubusercontent.com/5055789/198689762-8f3459a7-fdde-4c14-a13b-68933ef675e6.png)

Under the hood, Auth0.swift uses `ASWebAuthenticationSession` by default to perform web-based authentication, which is the [API provided by Apple](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) for such purpose.

That alert box is displayed and managed by `ASWebAuthenticationSession`, not by Auth0.swift, because by default this API will store the session cookie in the shared Safari cookie jar. This makes single sign-on (SSO) possible. According to Apple, that requires user consent.

> [!NOTE]
> See [this blog post](https://developer.okta.com/blog/2022/01/13/mobile-sso) for a detailed overview of SSO on iOS.

### Use ephemeral sessions

If you don't need SSO, you can disable this behavior by adding `useEphemeralSession()` to the login call. This will configure `ASWebAuthenticationSession` to not store the session cookie in the shared cookie jar, as if using an incognito browser window. With no shared cookie, `ASWebAuthenticationSession` will not prompt the user for consent.

```swift
Auth0
    .webAuth()
    .useEphemeralSession() // No SSO, therefore no alert box
    .start { result in
        // ...
    }
```

Note that with `useEphemeralSession()` you don't need to call `clearSession(federated:)` at all. Just clearing the credentials from the app will suffice. What `clearSession(federated:)` does is clear the shared session cookie, so that in the next login call the user gets asked to log in again. But with `useEphemeralSession()` there will be no shared cookie to remove.

> [!NOTE]
> `useEphemeralSession()` relies on the `prefersEphemeralWebBrowserSession` configuration option of `ASWebAuthenticationSession`.

### Use `SFSafariViewController`

An alternative is to use `SFSafariViewController` instead of `ASWebAuthenticationSession`. You can do so with the built-in `SFSafariViewController` Web Auth provider:

```swift
Auth0
    .webAuth()
    .provider(WebAuthentication.safariProvider()) // Use SFSafariViewController
    .start { result in
        // ...
    }
```

> [!IMPORTANT]
> Since `SFSafariViewController` does not share cookies with the Safari app, SSO will not work either. But it will keep its own cookies, so you can use it to perform SSO between your app and your website as long as you open it inside your app using `SFSafariViewController`. This also means that any feature that relies on the persistence of cookies –like "Remember this device"– will work as expected.

> [!NOTE]
> `SFSafariViewController` does not support using Universal Links as callback URLs.

If you choose to use the `SFSafariViewController` Web Auth provider, you need to perform an additional bit of setup. Unlike `ASWebAuthenticationSession`, `SFSafariViewController` will not automatically capture the callback URL when Auth0 redirects back to your app, so it is necessary to manually resume the Web Auth operation.

#### 1. Configure a custom URL scheme

In Xcode, go to the **Info** tab of your app target settings. In the **URL Types** section, click the **＋** button to add a new entry. There, enter `auth0` into the **Identifier** field and `$(PRODUCT_BUNDLE_IDENTIFIER)` into the **URL Schemes** field.

![Screenshot of the URL Types section inside the app target settings](https://user-images.githubusercontent.com/5055789/198689930-15f12179-15df-437e-ba50-dec26dbfb21f.png)

This registers your bundle identifier as a custom URL scheme, so the callback URL can reach your app.

#### 2. Capture the callback URL

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

## 2. How can I disable the _logout_ alert box?

![Screenshot of the SSO alert box](https://user-images.githubusercontent.com/5055789/198689762-8f3459a7-fdde-4c14-a13b-68933ef675e6.png)

Since `clearSession(federated:)` needs to use `ASWebAuthenticationSession` as well to clear the shared session cookie, the same alert box will be displayed. 

If you need SSO and/or are willing to tolerate the alert box on the login call, but would prefer to get rid of it when calling `clearSession(federated:)`, you can simply not call `clearSession(federated:)` and just clear the credentials from the app. This means that the shared session cookie will not be removed, so to get the user to log in again you need to add the `"prompt": "login"` parameter to the _login_ call.

```swift
Auth0
    .webAuth()
    .useEphemeralSession()
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

If you don't need SSO, consider using `ASWebAuthenticationSession` with ephemeral sessions or `SFSafariViewController` instead. See [1. How can I disable the _login_ alert box?](#1-how-can-i-disable-the-login-alert-box) for more information.

[Go up ⤴](#frequently-asked-questions)
