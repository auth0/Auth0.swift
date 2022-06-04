# Frequently Asked Questions

1. [How can I disable the _login_ alert box?](#1-how-can-i-disable-the-login-alert-box)
2. [How can I disable the _logout_ alert box?](#2-how-can-i-disable-the-logout-alert-box)
3. [How can I change the message in the alert box?](#3-how-can-i-change-the-message-in-the-alert-box)
4. [How can I programmatically close the alert box?](#4-how-can-i-programmatically-close-the-alert-box)

## 1. How can I disable the _login_ alert box?

![sso-alert](assets/sso-alert.png)

Under the hood, Auth0.swift uses `ASWebAuthenticationSession` by default to perform web-based authentication, which is the [API provided by Apple](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) for such purpose.

That alert box is displayed and managed by `ASWebAuthenticationSession`, not by Auth0.swift, because by default this API will store the session cookie in the shared Safari cookie jar. This makes single sign-on (SSO) possible. According to Apple, that requires user consent.

> 💡 See [this blog post](https://developer.okta.com/blog/2022/01/13/mobile-sso) for a detailed overview of SSO on iOS.

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

> ⚠️ `useEphemeralSession()` relies on the `prefersEphemeralWebBrowserSession` configuration option of `ASWebAuthenticationSession`. This option is only available on [iOS 13+](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/3237231-prefersephemeralwebbrowsersessio), so `useEphemeralSession()` will have no effect on iOS 12. To improve the experience for iOS 12 users, see the approach described below.

An alternative is to use `SFSafariViewController` instead of `ASWebAuthenticationSession`. You can do so with the built-in `SFSafariViewController` Web Auth provider:

```swift
Auth0
    .webAuth()
    .provider(WebAuthentication.safariProvider())
    .start { result in
        // ...
    }
```

> ⚠️ Since `SFSafariViewController` does not share cookies with the Safari app, SSO will not work either. But it will keep its own cookies, so you can use it to perform SSO between your app and your website as long as you open it inside your app using `SFSafariViewController`.

If you choose to use the `SFSafariViewController` Web Auth provider, you need to perform an additional bit of setup. Unlike `ASWebAuthenticationSession`, `SFSafariViewController` will not automatically capture the callback URL when Auth0 redirects back to your app, so it's necessary to manually resume the Web Auth operation.

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

// Called when your app is running or suspended in memory
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    WebAuthentication.resume(with: url)
}

// Called when your app is not running
func scene(_ scene: UIScene, 
           willConnectTo session: UISceneSession, 
           options connectionOptions: UIScene.ConnectionOptions) {
    guard let url = connectionOptions.urlContexts.first?.url else { return }
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

![sso-alert](assets/sso-alert.png)

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

> ⚠️ Keeping the shared session cookie may not be an option if you have strong privacy and/or security requirements, for example in the case of a banking app.

## 3. How can I change the message in the alert box?

Auth0.swift has no control whatsoever over the alert box. Its contents cannot be changed. Unfortunately, that's a limitation of `ASWebAuthenticationSession`.

## 4. How can I programmatically close the alert box?

Auth0.swift has no control whatsoever over the alert box. It cannot be closed programmatically. Unfortunately, that's a limitation of `ASWebAuthenticationSession`. 
