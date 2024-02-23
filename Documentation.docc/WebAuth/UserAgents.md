# ASWebAuthenticationSession vs SFSafariViewController (iOS)

## Overview

Web-based authentication needs an in-app browser. Auth0.swift offers the choice of two system-provided browser APIs: [`ASWebAuthenticationSession`](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) and [`SFSafariViewController`](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller).

## When to use ASWebAuthenticationSession

`ASWebAuthenticationSession` is an API provided specifically for performing web-based authentication. It is not meant for general-purpose browsing, and exposes a pretty limited API. `ASWebAuthenticationSession` can be used with or without ephemeral sessions enabled –through the [`prefersEphemeralWebBrowserSession`](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/3237231-prefersephemeralwebbrowsersessio) option.

> Note: `ASWebAuthenticationSession` supports using Universal Links as callback and logout URLs on iOS 174+ and macOS 14.4+.

### Without ephemeral sessions (the default)

```swift
Auth0
    .webAuth()
    .start { result in
        // ...
    }
```

By default, Auth0.swift uses `ASWebAuthenticationSession` with `prefersEphemeralWebBrowserSession` set to `false`. This means that:

- The session cookie will be shared with the Safari app.
- An alert box will be shown when logging in –and logging out– asking for consent, as the session cookie will be placed in a shared jar. This alert box is displayed and managed by `ASWebAuthenticationSession`, not Auth0.swift, and unfortunately it is not customizable.

#### You want this if...

- **You need SSO between your app and your website**, when your website is accessed through the Safari app. SSO will not work with any other browser, like Chrome or Firefox.
- **You need SSO across apps**. Since the session cookie will be placed in a shared cookie jar, it will be available for `ASWebAuthenticationSession` across *all* apps.

### With ephemeral sessions

Auth0.swift allows to set `prefersEphemeralWebBrowserSession` to `true`, by calling `useEphemeralSession()`.

```swift
Auth0
    .webAuth()
    .useEphemeralSession()
    .start { result in
        // ...
    }
```

`prefersEphemeralWebBrowserSession` being set to `true` means that:

- The session cookie will not be persisted. As soon as the `ASWebAuthenticationSession` window closes, the cookie will be gone. This is akin to using a desktop browser in incognito mode.
- Any features that rely on the persistence of cookies –like SSO, or "Remember this device"– **will not work**.
- No consent alert box will be shown, as the session cookie won't be placed in a shared cookie jar.
- There will be no need to call `clearSession()`. What `clearSession()` does is remove the persisted session cookie. Now there will be no session cookie to remove, so it won't do anything. To log the user out, just delete any stored credentials –for example, by calling the `clear()` method of the Credentials Manager.

#### You want this if...

- **You don't need SSO at all**. Since the session cookie won't be persisted, SSO will be effectively disabled.
- **You don't need any features that rely on the persistence of cookies**, like "Remember this device".

## When to use SFSafariViewController

```swift
Auth0
    .webAuth()
    .provider(WebAuthentication.safariProvider())
    .start { result in
        // ...
    }
```

`SFSafariViewController` is a general purpose in-app browser that can also be used to perform web-based authentication. When used for this purpose, it acts as a middle ground between `ASWebAuthenticationSession` with and without ephemeral sessions. It persists cookies, but won't share them outside of your app. This means that:

- All the `SFSafariViewController` instances used in your app will have access to the persisted session cookie.
- No consent alert box will be shown, as the session cookie won't be placed in a shared cookie jar.
- All the features that rely on the persistence of cookies –like "Remember this device"– **will work** as expected.

> Note: `SFSafariViewController` does not support using Universal Links as callback URLs.

#### You want this if...

- **You need SSO between your app and your website**, when your website is accessed through another `SFSafariViewController` instance in your app.

## See Also

- [FAQ](https://github.com/auth0/Auth0.swift/blob/master/FAQ.md)
