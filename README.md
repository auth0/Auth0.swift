![Auth0.swift](https://cdn.auth0.com/website/sdks/banners/swift-banner.png)

![Version](https://img.shields.io/cocoapods/v/Auth0.svg?style=flat)
[![CircleCI](https://img.shields.io/circleci/project/github/auth0/Auth0.swift.svg?style=flat)](https://circleci.com/gh/auth0/Auth0.swift/tree/master)
[![Coverage Status](https://img.shields.io/codecov/c/github/auth0/Auth0.swift/master.svg?style=flat)](https://codecov.io/github/auth0/Auth0.swift)
![License](https://img.shields.io/github/license/auth0/Auth0.swift.svg?style=flat)

📚 [**Documentation**](#documentation) • 🚀 [**Getting Started**](#getting-started) • 📃 [**Support Policy**](#support-policy) • 💬 [**Feedback**](#feedback)

Migrating from v1? Check the [Migration Guide](V2_MIGRATION_GUIDE.md).

## Documentation

- [**Quickstart**](https://auth0.com/docs/quickstart/native/ios-swift/interactive)
 - shows how to integrate Auth0.swift into an iOS / macOS app from scratch.
- [**Sample App**](https://github.com/auth0-samples/auth0-ios-swift-sample/tree/master/Sample-01) - a complete, running iOS / macOS app you can try.
- [**Examples**](EXAMPLES.md) - explains how to use most features.
- [**API Documentation**](https://auth0.github.io/Auth0.swift/documentation/auth0) - documentation auto-generated from the code comments that explains all the available features.
  + [Web Auth](https://auth0.github.io/Auth0.swift/documentation/auth0/webauth)
  + [Credentials Manager](https://auth0.github.io/Auth0.swift/documentation/auth0/credentialsmanager)
  + [Authentication API Client](https://auth0.github.io/Auth0.swift/documentation/auth0/authentication)
  + [Management API Client (Users)](https://auth0.github.io/Auth0.swift/documentation/auth0/users)
- [**FAQ**](FAQ.md) - answers some common questions about Auth0.swift.
- [**Auth0 Documentation**](https://auth0.com/docs) - explore our docs site and learn more about Auth0.

## Getting Started

### Requirements

- iOS 12.0+ / macOS 10.15+ / tvOS 12.0+ / watchOS 6.2+
- Xcode 13.x / 14.x
- Swift 5.3+

> ⚠️ Check the [Support Policy](#support-policy) to learn when dropping Xcode, Swift, and platform versions will not be considered a **breaking change**.

### Installation

#### Swift Package Manager

Open the following menu item in Xcode:

**File > Add Packages...**

In the **Search or Enter Package URL** search box enter this URL: 

```text
https://github.com/auth0/Auth0.swift
```

Then, select the dependency rule and press **Add Package**.

#### Cocoapods

Add the following line to your `Podfile`:

```ruby
pod 'Auth0', '~> 2.3'
```

Then, run `pod install`.

#### Carthage

Add the following line to your `Cartfile`:

```text
github "auth0/Auth0.swift" ~> 2.3
```

Then, run `carthage bootstrap --use-xcframeworks`.

### Configure the SDK

Head to the [Auth0 Dashboard](https://manage.auth0.com/#/applications/) and create a new **Native** application.

Auth0.swift needs the **Client ID** and **Domain** of the Auth0 application to communicate with Auth0. You can find these details in the settings page of your Auth0 application. If you are using a [custom domain](https://auth0.com/docs/customize/custom-domains), use the value of your custom domain instead of the value from the settings page.

#### Configure Client ID and Domain with a plist

Create a `plist` file named `Auth0.plist` in your app bundle with the following content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ClientId</key>
    <string>YOUR_AUTH0_CLIENT_ID</string>
    <key>Domain</key>
    <string>YOUR_AUTH0_DOMAIN</string>
</dict>
</plist>
```

#### Configure Client ID and Domain programmatically

<details>
  <summary>For Web Auth</summary>

```swift
Auth0
    .webAuth(clientId: "YOUR_AUTH0_CLIENT_ID", domain: "YOUR_AUTH0_DOMAIN")
    // ...
```
</details>

<details>
  <summary>For the Authentication API client</summary>

```swift
Auth0
    .authentication(clientId: "YOUR_AUTH0_CLIENT_ID", domain: "YOUR_AUTH0_DOMAIN")
    // ...
```
</details>

<details>
  <summary>For the Management API client (Users)</summary>

```swift
Auth0
    .users(token: credentials.accessToken, domain: "YOUR_AUTH0_DOMAIN")
    // ...
```
</details>

### Configure Web Auth (iOS / macOS)

#### Configure callback and logout URLs

The callback and logout URLs are the URLs that Auth0 invokes to redirect back to your app. Auth0 invokes the callback URL after authenticating the user, and the logout URL after removing the session cookie.

Since callback and logout URLs can be manipulated, you will need to add your URLs to the **Allowed Callback URLs** and **Allowed Logout URLs** fields in the settings page of your Auth0 application. This will enable Auth0 to recognize these URLs as valid. If the callback and logout URLs are not set, users will be unable to log in and out of the app and will get an error.

Go to the settings page of your [Auth0 application](https://manage.auth0.com/#/applications/) and add the corresponding URL to **Allowed Callback URLs** and **Allowed Logout URLs**, according to the platform of your app. If you are using a [custom domain](https://auth0.com/docs/customize/custom-domains), replace `YOUR_AUTH0_DOMAIN` with the value of your custom domain instead of the value from the settings page.

##### iOS

```text
YOUR_BUNDLE_IDENTIFIER://YOUR_AUTH0_DOMAIN/ios/YOUR_BUNDLE_IDENTIFIER/callback
```

##### macOS

```text
YOUR_BUNDLE_IDENTIFIER://YOUR_AUTH0_DOMAIN/macos/YOUR_BUNDLE_IDENTIFIER/callback
```

For example, if your iOS bundle identifier was `com.example.MyApp` and your Auth0 Domain was `example.us.auth0.com`, then this value would be:

```text
com.example.MyApp://example.us.auth0.com/ios/com.example.MyApp/callback
```

> ⚠️ Make sure that the **Token Endpoint Authentication Method** setting is set to `None`.

#### Configure custom URL scheme

Back in Xcode, go to the **Info** tab of your app target settings. In the **URL Types** section, click the **＋** button to add a new entry. There, enter `auth0` into the **Identifier** field and `$(PRODUCT_BUNDLE_IDENTIFIER)` into the **URL Schemes** field.

![url-scheme](https://user-images.githubusercontent.com/5055789/198689930-15f12179-15df-437e-ba50-dec26dbfb21f.png)

This registers your bundle identifier as a custom URL scheme, so the callback and logout URLs can reach your app.

### Web Auth login (iOS / macOS)

Import the `Auth0` module in the file where you want to present the login page.

```swift
import Auth0
```

Then, present the [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login) page in the action of your **Login** button.

```swift
Auth0
    .webAuth()
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
    let credentials = try await Auth0.webAuth().start()
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

### Web Auth logout (iOS / macOS)

Logging the user out involves clearing the Universal Login session cookie and then deleting the user's credentials from your app.

Call the `clearSession()` method in the action of your **Logout** button. Once the session cookie has been cleared, [delete the user's credentials](#clear-stored-credentials).

```swift
Auth0
    .webAuth()
    .clearSession { result in
        switch result {
        case .success:
            print("Session cookie cleared")
            // Delete credentials
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    try await Auth0.webAuth().clearSession()
    print("Session cookie cleared")
    // Delete credentials
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
    .clearSession()
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Session cookie cleared")
            // Delete credentials
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }, receiveValue: {})
    .store(in: &cancellables)
```
</details>

### SSO alert box (iOS / macOS)

![sso-alert](https://user-images.githubusercontent.com/5055789/198689762-8f3459a7-fdde-4c14-a13b-68933ef675e6.png)

Check the [FAQ](FAQ.md) for more information about the alert box that pops up **by default** when using Web Auth.

> 💡 See also [this blog post](https://developer.okta.com/blog/2022/01/13/mobile-sso) for a detailed overview of single sign-on (SSO) on iOS.

### Next steps

**Learn about most features in [Examples ↗](EXAMPLES.md)**

- [**Store credentials**](EXAMPLES.md#store-credentials) - store the user's credentials securely in the Keychain.
- [**Check for stored credentials**](EXAMPLES.md#check-for-stored-credentials) - check if the user is already logged in when your app starts up.
- [**Retrieve stored credentials**](EXAMPLES.md#retrieve-stored-credentials) - fetch the user's credentials from the Keychain, automatically renewing them if they have expired.
- [**Clear stored credentials**](EXAMPLES.md#clear-stored-credentials) - delete the user's credentials to complete the logout process.
- [**Retrieve user information**](EXAMPLES.md#retrieve-user-information) - fetch the latest user information from the `/userinfo` endpoint.

## Support Policy

This Policy defines the extent of the support for Xcode, Swift, and platform (iOS, macOS, tvOS, and watchOS) versions in Auth0.swift.

### Xcode

The only supported versions of Xcode are those that can be currently used to submit apps to the App Store. Once a Xcode version becomes unsupported, dropping it from Auth0.swift **will not be considered a breaking change**, and will be done in a **minor** release.

### Swift

The minimum supported Swift minor version is the one released with the oldest-supported Xcode version. Once a Swift minor becomes unsupported, dropping it from Auth0.swift **will not be considered a breaking change**, and will be done in a **minor** release.

### Platforms

Only the last 4 major platform versions are supported, starting from:

- iOS **12**
- macOS **10.15**
- macCatalyst **13**
- tvOS **12**
- watchOS **6.2**

Once a platform version becomes unsupported, dropping it from Auth0.swift **will not be considered a breaking change**, and will be done in a **minor** release. For example, iOS 13 will cease to be supported when iOS 17 gets released, and Auth0.swift will be able to drop it in a minor release.

In the case of macOS, the yearly named releases are considered a major platform version for the purposes of this Policy, regardless of the actual version numbers.

## Feedback

### Contributing

We appreciate feedback and contribution to this repo! Before you get started, please see the following:

- [Auth0's general contribution guidelines](https://github.com/auth0/open-source-template/blob/master/GENERAL-CONTRIBUTING.md)
- [Auth0's code of conduct guidelines](https://github.com/auth0/open-source-template/blob/master/CODE-OF-CONDUCT.md)
- [Auth0.swift's contribution guide](CONTRIBUTING.md)

### Raise an issue

To provide feedback or report a bug, please [raise an issue on our issue tracker](https://github.com/auth0/Auth0.swift/issues).

### Vulnerability reporting

Please do not report security vulnerabilities on the public GitHub issue tracker. The [Responsible Disclosure Program](https://auth0.com/responsible-disclosure-policy) details the procedure for disclosing security issues.

---

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: light)" srcset="https://cdn.auth0.com/website/sdks/logos/auth0_light_mode.png" width="150">
    <source media="(prefers-color-scheme: dark)" srcset="https://cdn.auth0.com/website/sdks/logos/auth0_dark_mode.png" width="150">
    <img alt="Auth0 Logo" src="https://cdn.auth0.com/website/sdks/logos/auth0_light_mode.png" width="150">
  </picture>
</p>

<p align="center">Auth0 is an easy to implement, adaptable authentication and authorization platform. To learn more checkout <a href="https://auth0.com/why-auth0">Why Auth0?</a></p>

<p align="center">This project is licensed under the MIT license. See the <a href="./LICENSE"> LICENSE</a> file for more info.</p>
