# Frequently Asked Questions

1. [How can I disable the _login_ alert box?](#1-how-can-i-disable-the-login-alert-box)
2. [How can I disable the _logout_ alert box?](#2-how-can-i-disable-the-logout-alert-box)
3. [Is there a way to disable the _login_ alert box without `useEphemeralSession()`?](#3-is-there-a-way-to-disable-the-login-alert-box-without-useephemeralsession)
4. [How can I change the message in the alert box?](#4-how-can-i-change-the-message-in-the-alert-box)
5. [How can I programmatically close the alert box?](#5-how-can-i-programmatically-close-the-alert-box)

## 1. How can I disable the _login_ alert box?

![sso-alert](./sso-alert.png)

Under the hood, Auth0.swift uses `ASWebAuthenticationSession` to perform web-based authentication, which is the [API provided by Apple](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) for such purpose.

That alert box is displayed and managed by `ASWebAuthenticationSession`, not by Auth0.swift, because by default this API will store the session cookie in the shared Safari cookie jar. This makes Single Sign On (SSO) possible. According to Apple, that requires user consent.

If you don't need SSO, you can disable this behavior by adding `useEphemeralSession()` to the login call. This will configure `ASWebAuthenticationSession` to not store the session cookie in the shared cookie jar, as if using an incognito browser window. With no shared cookie, `ASWebAuthenticationSession` will not prompt the user for consent.

```swift
Auth0
    .webAuth()
    .useEphemeralSession() // no alert box, and no SSO
    .start { result in
        // ...
    }
```

Note that with `useEphemeralSession()` you don't need to call `clearSession(federated:)` at all. Just clearing the credentials from the app will suffice. What `clearSession(federated:)` does is clear the shared session cookie, so that in the next login call the user gets asked to log in again. But with `useEphemeralSession()` there will be no shared cookie to remove.

> `useEphemeralSession()` relies on the `prefersEphemeralWebBrowserSession` configuration option of `ASWebAuthenticationSession`. This option is only available on [iOS 13+ and macOS](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/3237231-prefersephemeralwebbrowsersessio), so `useEphemeralSession()` will have no effect on iOS 12. To improve the experience for iOS 12 users, check out the approach described below.

## 2. How can I disable the _logout_ alert box?

![sso-alert](./sso-alert.png)

If you need SSO and/or are willing to tolerate the alert box on the login call, but would like to get rid of it when calling `clearSession(federated:)`, you can simply not call `clearSession(federated:)` and just clear the credentials from the app. This means that the shared cookie will not be removed, so to get the user to log in again you'll need to add the `"prompt": "login"` parameter to the _login_ call.

```swift
Auth0
    .webAuth()
    .useEphemeralSession()
    .parameters(["prompt": "login"]) // force the login page, having cookie or not
    .start { result in
        // ...
    }
```

Otherwise, the browser modal will close right away and the user will be automatically logged in again, as the cookie will still be there.

## 3. Is there a way to disable the _login_ alert box without `useEphemeralSession()`?

No. According to Apple, storing the session cookie in the shared Safari cookie jar requires user consent. The only way to not have a shared cookie is to configure `ASWebAuthenticationSession` with `prefersEphemeralWebBrowserSession` set to `true`, which is what `useEphemeralSession()` does.

## 4. How can I change the message in the alert box?

Auth0.swift has no control whatsoever over the alert box. Its contents cannot be changed. Unfortunately, that's a limitation of `ASWebAuthenticationSession`.

## 5. How can I programmatically close the alert box?

Auth0.swift has no control whatsoever over the alert box. It cannot be closed programmatically. Unfortunately, that's a limitation of `ASWebAuthenticationSession`. 
