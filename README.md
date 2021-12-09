# Auth0.swift

[![CircleCI](https://img.shields.io/circleci/project/github/auth0/Auth0.swift.svg?style=flat-square)](https://circleci.com/gh/auth0/Auth0.swift/tree/master)
[![Coverage Status](https://img.shields.io/codecov/c/github/auth0/Auth0.swift/master.svg?style=flat-square)](https://codecov.io/github/auth0/Auth0.swift)
[![Version](https://img.shields.io/cocoapods/v/Auth0.svg?style=flat-square)](https://cocoadocs.org/docsets/Auth0)
[![License](https://img.shields.io/cocoapods/l/Auth0.svg?style=flat-square)](https://cocoadocs.org/docsets/Auth0)
[![Platform](https://img.shields.io/cocoapods/p/Auth0.svg?style=flat-square)](https://cocoadocs.org/docsets/Auth0)
![Swift 5.5](https://img.shields.io/badge/Swift-5.5-orange.svg?style=flat-square)

Swift toolkit that lets you communicate efficiently with many of the [Auth0 API](https://auth0.com/docs/api/info) functions and enables you to seamlessly integrate the Auth0 login.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Next Steps](#next-steps)
- [What is Auth0?](#what-is-auth0)
- [Create a Free Auth0 Account](#create-a-free-auth0-account)
- [Issue Reporting](#issue-reporting)
- [Author](#author)
- [License](#license)

## Requirements

- iOS 12+ / macOS 10.15+ / tvOS 12.0+ / watchOS 6.2+
- Xcode 12.x / 13.x
- Swift 5.3+

## Installation

#### Cocoapods

If you are using [Cocoapods](https://cocoapods.org), add this line to your `Podfile`:

```ruby
pod 'Auth0', '~> 1.38'
```

Then run `pod install`.

> For more information on Cocoapods, check [their official documentation](https://guides.cocoapods.org/using/getting-started.html).

#### Carthage

If you are using [Carthage](https://github.com/Carthage/Carthage), add the following line to your `Cartfile`:

```ruby
github "auth0/Auth0.swift" ~> 1.38
```

Then run `carthage bootstrap --use-xcframeworks`.

> For more information about Carthage usage, check [their official documentation](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos).

#### SPM

If you are using the Swift Package Manager, open the following menu item in Xcode:

**File > Add Packages...**

In the **Search or Enter Package URL** search box enter this url: 

```
https://github.com/auth0/Auth0.swift.git
```

Then select the dependency rule and press **Add Package**.

> For further reference on SPM, check [its official documentation](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app).

## Getting Started

### Authentication with Universal Login (iOS / macOS 10.15+)

1. Import **Auth0** into your project.        
```swift
import Auth0
```

2. Present the Universal Login page.
```swift
Auth0
    .webAuth()
    .audience("https://YOUR_AUTH0_DOMAIN/userinfo")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with \(error)")
        }
    }
```

> This snippet sets the `audience` to ensure OIDC compliant responses, this can also be achieved by enabling the **OIDC Conformant** switch in your Auth0 dashboard under `Application / Settings / Advanced / OAuth`.

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .webAuth()
    .audience("https://YOUR_AUTH0_DOMAIN/userinfo")
    .publisher()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    let credentials = try await Auth0
        .webAuth()
        .audience("https://YOUR_AUTH0_DOMAIN/userinfo")
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with \(error)")
}
```
</details>

### Configuration

In order to use Auth0 you need to provide your Auth0 **ClientId** and **Domain**.

> Auth0 ClientId & Domain can be found in your [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

#### Adding Auth0 Credentials

In your application bundle add a `plist` file named `Auth0.plist` with the following information:

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

As an alternative, you can pass the ClientId & Domain programmatically.

```swift
// When using Universal Login
Auth0.webAuth(clientId: "YOUR_AUTH0_CLIENT_ID", domain: "YOUR_AUTH0_DOMAIN")

// When using the Authentication API
Auth0.authentication(clientId: "YOUR_AUTH0_CLIENT_ID", domain: "YOUR_AUTH0_DOMAIN")
```

#### Configure Callback URLs (iOS / macOS)

Callback URLs are the URLs that Auth0 invokes after the authentication process. Auth0 routes your application back to this URL and appends additional parameters to it, including a token. Since callback URLs can be manipulated, you will need to add your callback URL to the **Allowed Callback URLs** field in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/). This will enable Auth0 to recognize these URLs as valid. If omitted, authentication will not be successful.

In your application's `Info.plist` file, register your iOS / macOS Bundle Identifier as a custom scheme.

```xml
<!-- Info.plist -->

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>None</string>
        <key>CFBundleURLName</key>
        <string>auth0</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_BUNDLE_IDENTIFIER</string>
        </array>
    </dict>
</array>
```

> If your `Info.plist` is not shown in this format, you can **Right Click** on `Info.plist` in Xcode and then select **Open As / Source Code**.

Finally, go to your [Auth0 Dashboard](https://manage.auth0.com/#/applications/) and make sure that your application's **Allowed Callback URLs** field contains the following entry:

```text
YOUR_BUNDLE_IDENTIFIER://YOUR_AUTH0_DOMAIN/ios/YOUR_BUNDLE_IDENTIFIER/callback
```

e.g. If your bundle identifier was `com.company.myapp` and your Auth0 domain was `company.auth0.com`, then this value would be:

```text
com.company.myapp://company.auth0.com/ios/com.company.myapp/callback
```

## Next Steps

### Learning Resources

Check out the [iOS Swift QuickStart Guide](https://auth0.com/docs/quickstart/native/ios-swift) to find out more about the Auth0.swift toolkit and explore our tutorials and sample projects.

### Common Tasks

#### Retrieve user information

```swift
Auth0
   .authentication()
   .userInfo(withAccessToken: accessToken)
   .start { result in
       switch result {
       case .success(let user):
           print("User: \(user)")
       case .failure(let error):
           print("Failed with \(error)")
       }
   }
```

<details>
  <summary>Using Combine</summary>

```swift
Auth0
   .authentication()
   .userInfo(withAccessToken: accessToken)
   .publisher()
   .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
    }, receiveValue: { user in
        print("User: \(user)")
    })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    let user = try await Auth0
        .authentication()
        .userInfo(withAccessToken: accessToken)
        .start()
    print("User: \(user)")
} catch {
    print("Failed with \(error)")
}
```
</details>

#### Renew user credentials

Use a [Refresh Token](https://auth0.com/docs/tokens/refresh-tokens) to renew the user's credentials. It's recommended that you read and understand the refresh token process before implementing.

```swift
Auth0
    .authentication()
    .renew(withRefreshToken: refreshToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained new credentials: \(credentials)")
        case .failure(let error):
            print("Failed with \(error)")
        }
    }
```

<details>
  <summary>Using Combine</summary>

```swift
Auth0
   .authentication()
   .renew(withRefreshToken: refreshToken)
   .publisher()
   .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained new credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .renew(withRefreshToken: refreshToken)
        .start()
    print("Obtained new credentials: \(credentials)")
} catch {
    print("Failed with \(error)")
}
```
</details>

#### Signup with Universal Login

You can make users land directly on the Signup page instead of the Login page by specifying the `"screen_hint": "signup"` parameter when performing Web Authentication. Note that this can be combined with `"prompt": "login"`, which indicates whether you want to always show the authentication page or you want to skip if there's an existing session.

| Parameters                                     | No existing session   | Existing session              |
|:-----------------------------------------------|:----------------------|:------------------------------|
| no extra parameters                            | Shows the login page  | Redirects to the callback url |
| `"screen_hint": "signup"`                      | Shows the signup page | Redirects to the callback url |
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
            print("Failed with \(error)")
        }
    }
```

> The `screen_hint` parameter can only be used with the **New Universal Login Experience**, not the **Classic Experience**.

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .webAuth()
    .parameters(["screen_hint": "signup"])
    .publisher()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    let credentials = try await Auth0
        .webAuth()
        .parameters(["screen_hint": "signup"])
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with \(error)")
}
```
</details>

#### Disable Single Sign On Consent Alert (iOS 13+ / macOS)

This SDK uses `ASWebAuthenticationSession` under the hood to perform Web Authentication on iOS 12+ and macOS. It is Apple's current API for performing web-based authentication. By default, `ASWebAuthenticationSession` will store the Web Authentication cookies in Safari's shared cookie jar. This makes [Single Sign On (SSO)](https://auth0.com/docs/sso) possible, but it also means that `ASWebAuthenticationSession` will prompt the user for consent.

![sso-alert](./sso-alert.png)

To suppress the alert box, add the `useEphemeralSession()` method to the chain. Doing so will make the SDK configure `ASWebAuthenticationSession` with `prefersEphemeralWebBrowserSession` enabled. This will disable SSO, but will also not display the consent alert that otherwise shows up when SSO is enabled. 

 > `prefersEphemeralWebBrowserSession` is only available on iOS 13+ and macOS, so `useEphemeralSession()` will have no effect on older versions of iOS. For more information on `prefersEphemeralBrowserSession`, check [its documentation](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/3237231-prefersephemeralwebbrowsersessio).

```swift
Auth0
    .webAuth()
    .audience("https://YOUR_AUTH0_DOMAIN/userinfo")
    .useEphemeralSession()
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with \(error)")
        }
    }
```

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .webAuth()
    .audience("https://YOUR_AUTH0_DOMAIN/userinfo")
    .useEphemeralSession()
    .publisher()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    let credentials = try await Auth0
        .webAuth()
        .audience("https://YOUR_AUTH0_DOMAIN/userinfo")
        .useEphemeralSession()
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with \(error)")
}
```
</details>

If you're using `useEphemeralSession()`, you do not need to call `clearSession()` to perform logout as there will be no cookies to remove. Just deleting the credentials will suffice. 

### Credentials Management Utility

The credentials manager utility provides a convenience to securely store and retrieve the user's credentials from the Keychain.

```swift
let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
```

#### Store Credentials

Store user credentials securely in the Keychain.

```swift
credentialsManager.store(credentials: credentials)
```

#### Retrieve stored credentials 

Credentials will automatically be renewed (if expired) using the refresh token. The scope `offline_access` is required to ensure the refresh token is returned.

> This method is thread-safe.

```swift
credentialsManager.credentials { result in 
    switch result {
    case .success(let credentials):
        print("Obtained credentials: \(credentials)")
    case .failure(let error):
        print("Failed with \(error)") 
}
```

<details>
  <summary>Using Combine</summary>

```swift
credentialsManager
    .credentials()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    let credentials = try await credentialsManager.credentials()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with \(error)")
}
```
</details>

#### Clearing credentials and revoking refresh tokens

Credentials can be cleared by using the `clear` function, which clears credentials from the Keychain.

```swift
let didClear = credentialsManager.clear()
```

In addition, credentials can be cleared and the refresh token revoked using a single call to `revoke`. This function will attempt to revoke the current refresh token stored by the credential manager and then clear credentials from the Keychain. If revoking the token results in an error, then the credentials are not cleared:

```swift
credentialsManager.revoke { result in
    switch result {
    case .success:
        print("Success")
    case .failure(let error):
        print("Failed with \(error)") 
    }
}
```

<details>
  <summary>Using Combine</summary>

```swift
credentialsManager
    .revoke()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
        print("Success")
    }, receiveValue: { _ in })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    try await credentialsManager.revoke()
    print("Success")
} catch {
    print("Failed with \(error)")
}
```
</details>

#### Biometric authentication

You can enable an additional level of user authentication before retrieving credentials using the biometric authentication supported by your device e.g. Face ID or Touch ID.

```swift
credentialsManager.enableBiometrics(withTitle: "Touch to Login")
```

If needed, you are able to specify specific `LAPolicy` to be used - i.e. you might want to support FaceID, but allow fallback to pin code.

```swift
credentialsManager.enableBiometrics(withTitle: "Touch or enter pincode to Login", 
                                    evaluationPolicy: .deviceOwnerAuthentication)
```

### Native Social Login

#### Sign in With Apple

If you've added [the Sign In with Apple flow](https://developer.apple.com/documentation/authenticationservices/implementing_user_authentication_with_sign_in_with_apple) to your app, you can use the string value from the `authorizationCode` property obtained after a successful Apple authentication to perform a code exchange for Auth0 tokens.

```swift
Auth0
    .authentication()
    .login(appleAuthorizationCode: authCode)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with \(error)")
        }
}
```

<details>
  <summary>Using Combine</summary>

```swift
Auth0
   .authentication()
   .login(appleAuthorizationCode: authCode)
   .publisher()
   .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .login(appleAuthorizationCode: authCode)
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with \(error)")
}
```
</details>

Find out more about [Setting up Sign in with Apple](https://auth0.com/docs/connections/apple-siwa/set-up-apple) with Auth0.

#### Facebook Login

If you've added [the Facebook Login flow](https://developers.facebook.com/docs/facebook-login/ios) to your app, after a successful Faceboook authentication you can request a Session Access Token and the Facebook user profile, and use them to perform a code exchange for Auth0 tokens.

```swift
Auth0
    .authentication()
    .login(facebookSessionAccessToken: sessionAccessToken, profile: profile)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with \(error)")
        }
}
```

<details>
  <summary>Using Combine</summary>

```swift
Auth0
   .authentication()
   .login(facebookSessionAccessToken: sessionAccessToken, profile: profile)
   .publisher()
   .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .login(facebookSessionAccessToken: sessionAccessToken, profile: profile)
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with \(error)")
}
```
</details>

Find out more about [Setting up Facebook Login](https://auth0.com/docs/connections/nativesocial/facebook) with Auth0.

### Organizations

[Organizations](https://auth0.com/docs/organizations) is a set of features that provide better support for developers who build and maintain SaaS and Business-to-Business (B2B) applications. 

Using Organizations, you can:

- Represent teams, business customers, partner companies, or any logical grouping of users that should have different ways of accessing your applications, as organizations.
- Manage their membership in a variety of ways, including user invitation.
- Configure branded, federated login flows for each organization.
- Implement role-based access control, such that users can have different roles when authenticating in the context of different organizations.
- Build administration capabilities into your products, using Organizations APIs, so that those businesses can manage their own organizations.

Note that Organizations is currently only available to customers on our Enterprise and Startup subscription plans.

#### Log in to an organization

```swift
Auth0.webAuth()
    .organization(organizationId)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with \(error)")
        }
    }
```

<details>
  <summary>Using Combine</summary>

```swift
Auth0
   .webAuth()
   .organization(organizationId)
   .publisher()
   .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    let credentials = try await Auth0
        .webAuth()
        .organization(organizationId)
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with \(error)")
}
```
</details>

#### Accept user invitations

To accept organization invitations your app needs to support [Universal Links](https://developer.apple.com/documentation/xcode/allowing_apps_and_websites_to_link_to_your_content/supporting_universal_links_in_your_app). Tapping on the invitation link should open your app (invitations links are `https` only).

When your app gets opened by an invitation link, grab the invitation URL and pass it to `.invitationURL()`:

```swift
if let url = URLContexts.first?.url {
    // You need to wait for the app to enter the foreground before launching WebAuth
    _ = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        .subscribe(on: DispatchQueue.main)
        .prefix(1)
        .sink { _ in
            Auth0.webAuth()
                .invitationURL(url)
                .start { result in
                    switch result {
                    case .success(let credentials):
                        print("Obtained credentials: \(credentials)")
                    case .failure(let error):
                        print("Failed with \(error)")
                    }
                }
        }
}
```

### Authentication API (iOS / macOS / tvOS)

The Authentication API exposes AuthN/AuthZ functionality of Auth0, as well as the supported identity protocols like OpenID Connect, OAuth 2.0, and SAML.
We recommend using [Universal Login](https://auth0.com/docs/universal-login) but if you wish to build your own UI, you can use our API endpoints to do so. However, some Auth flows (grant types) are disabled by default so you must enable them via your Auth0 Dashboard as explained in [Update Grant Types](https://auth0.com/docs/applications/update-grant-types).

These are the required Grant Types that needs to be enabled in your application:

* **Password**: For login with username/password using a realm (or connection name). If you set the grants via API you should activate both `http://auth0.com/oauth/grant-type/password-realm` and `password`, otherwise Auth0 Dashboard will take care of activating both when `Password` is enabled.

#### Login with database connection (via Realm)

```swift
Auth0
    .authentication()
    .login(usernameOrEmail: "support@auth0.com",
           password: "secret-password",
           realm: "Username-Password-Authentication",
           scope: "openid profile")
     .start { result in
         switch result {
         case .success(let credentials):
            print("Obtained credentials: \(credentials)")
         case .failure(let error):
            print("Failed with \(error)")
         }
     }
```

> This requires `Password` Grant or `http://auth0.com/oauth/grant-type/password-realm`.

<details>
  <summary>Using Combine</summary>

```swift
Auth0
   .authentication()
   .login(usernameOrEmail: "support@auth0.com",
          password: "secret-password",
          realm: "Username-Password-Authentication",
          scope: "openid profile")
   .publisher()
   .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .login(usernameOrEmail: "support@auth0.com",
               password: "secret-password",
               realm: "Username-Password-Authentication",
               scope: "openid profile")
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with \(error)")
}
```
</details>

#### Sign up with database connection

```swift
Auth0
    .authentication()
    .createUser(email: "support@auth0.com",
                password: "secret-password",
                connection: "Username-Password-Authentication",
                userMetadata: ["first_name": "First", "last_name": "Last"])
    .start { result in
        switch result {
        case .success(let user):
            print("User signed up: \(user)")
        case .failure(let error):
            print("Failed with \(error)")
        }
    }
```

<details>
  <summary>Using Combine</summary>

```swift
Auth0
   .authentication()
   .createUser(email: "support@auth0.com",
               password: "secret-password",
               connection: "Username-Password-Authentication",
               userMetadata: ["first_name": "First", "last_name": "Last"])
   .publisher()
   .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
    }, receiveValue: { user in
        print("User signed up: \(user)")
    })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    let user = try await Auth0
        .authentication()
        .createUser(email: "support@auth0.com",
                    password: "secret-password",
                    connection: "Username-Password-Authentication",
                    userMetadata: ["first_name": "First", "last_name": "Last"])
        .start()
    print("User signed up: \(user)")
} catch {
    print("Failed with \(error)")
}
```
</details>

### Management API (Users)

You can request more information about a user's profile and manage the user's metadata by accessing the Auth0 [Management API](https://auth0.com/docs/api/management/v2). For security reasons native mobile applications are restricted to a subset of User based functionality.

You can find a detailed guide in this [iOS Swift QuickStart](https://auth0.com/docs/quickstart/native/ios-swift/03-user-sessions#managing-metadata).

#### Link an account

```swift
Auth0
    .users(token: idToken)
    .link("user identifier", withOtherUserToken: "another user token")
    .start { result in
        switch result {
        case .success:
            print("Accounts linked")
        case .failure(let error):
            print("Failed with \(error)")
        }
    }
```

<details>
  <summary>Using Combine</summary>

```swift
Auth0
   .users(token: idToken)
   .link("user identifier", withOtherUserToken: "another user token")
   .publisher()
   .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with \(error)")
        }
        print("Accounts linked")
    }, receiveValue: { _ in })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Using Async/Await</summary>

```swift
do {
    try await Auth0
        .users(token: idToken)
        .link("user identifier", withOtherUserToken: "another user token")
        .start()
    print("Accounts linked")
} catch {
    print("Failed with \(error)")
}
```
</details>

### Custom Domains

If you are using [Custom Domains](https://auth0.com/docs/custom-domains) and need to call an Auth0 endpoint
such as `/userinfo`, please use the Auth0 domain specified for your Application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

Example: `.audience("https://YOUR_AUTH0_DOMAIN/userinfo")`

Users of Auth0 Private Cloud with Custom Domains still on the [legacy behavior](https://auth0.com/docs/private-cloud/private-cloud-migrations/migrate-private-cloud-custom-domains) need to specify a custom issuer to match the Auth0 domain before starting the authentication. Otherwise, the ID Token validation will fail.

Example: `.issuer("https://YOUR_AUTH0_DOMAIN/")`

### Bot Detection

If you are using the [Bot Detection](https://auth0.com/docs/anomaly-detection/bot-detection) feature and performing database login/signup via the Authentication API, you need to handle the `isVerificationRequired` error. It indicates that the request was flagged as suspicious and an additional verification step is necessary to log the user in. That verification step is web-based, so you need to use Universal Login to complete it.

```swift
let email = "support@auth0.com"
let realm = "Username-Password-Authentication"
let scope = "openid profile"

Auth0
    .authentication()
    .login(usernameOrEmail: email,
           password: "secret-password",
           realm: realm,
           scope: scope)
     .start { result in
         switch result {
         case .success(let credentials):
            print("Obtained credentials: \(credentials)")
         case .failure(let error as AuthenticationError) where error.isVerificationRequired:
            DispatchQueue.main.async {
                Auth0
                    .webAuth()
                    .connection(realm)
                    .scope(scope)
                    .useEphemeralSession()
                    // ☝🏼 Otherwise a session cookie will remain
                    .parameters(["login_hint": email])
                    // ☝🏼 So the user doesn't have to type it again
                    .start { result in
                        // Handle result
                    }
            }
         case .failure(let error):
            print("Failed with \(error)")
         }
     }
```

In the case of signup, you can add [an additional parameter](https://auth0.com/docs/universal-login/new-experience#signup) to make the user land directly on the signup page.

```swift
.parameters(["login_hint": email, "screen_hint": "signup"])
```

Check out how to set up Universal Login in the [Getting Started](#getting-started) section.

> You don't need to handle this error if you're using the deprecated login methods.

### Logging

To enable Auth0.swift to log HTTP request and OAuth2 flow for debugging you can call the following method in either `WebAuth`, `Authentication` or `Users` object:

```swift
var auth0 = Auth0.authentication()
auth0.logging(enabled: true)
```

Then for a OAuth2 authentication you'll see something similar to the following:

```
Safari: https://samples.auth0.com/authorize?.....
URL: com.auth0.myapp://samples.auth0.com/ios/com.auth0.MyApp/callback?...
POST https://samples.auth0.com/oauth/token HTTP/1.1
Content-Type: application/json

{"code":"...","client_id":"...","grant_type":"authorization_code","redirect_uri":"com.auth0.MyApp:\/\/samples.auth0.com\/ios\/com.auth0.MyApp\/callback","code_verifier":"..."}

HTTP/1.1 200
Pragma: no-cache
Content-Type: application/json
Strict-Transport-Security: max-age=3600
Date: Thu, 09 Jun 2016 19:04:39 GMT
Content-Length: 57
Cache-Control: no-cache
Connection: keep-alive

{"access_token":"...","token_type":"Bearer"}
```

> Set this flag only when **DEBUGGING** to avoid leaking user's credentials in the device log.

## What is Auth0?

Auth0 helps you to:

* Add authentication with [multiple sources](https://auth0.com/docs/identityproviders), either social identity providers such as **Google, Facebook, Microsoft Account, LinkedIn, GitHub, Twitter, Box, Salesforce** (amongst others), or enterprise identity systems like **Windows Azure AD, Google Apps, Active Directory, ADFS, or any SAML Identity Provider**.
* Add authentication through more traditional **[username/password databases](https://auth0.com/docs/connections/database/custom-db)**.
* Add support for **[linking different user accounts](https://auth0.com/docs/users/user-account-linking)** with the same user.
* Support for generating signed [JSON Web Tokens](https://auth0.com/docs/tokens/json-web-tokens) to call your APIs and **flow the user identity** securely.
* Analytics of how, when, and where users are logging in.
* Pull data from other sources and add it to the user profile through [JavaScript rules](https://auth0.com/docs/rules).

## Create a Free Auth0 Account

1. Go to [Auth0](https://auth0.com) and click **Sign Up**.
2. Use Google, GitHub, or Microsoft Account to login.

## Issue Reporting

If you have found a bug or to request a feature, please [raise an issue](https://github.com/auth0/Auth0.swift/issues). Please do not report security vulnerabilities on the public GitHub issue tracker. The [Responsible Disclosure Program](https://auth0.com/responsible-disclosure-policy) details the procedure for disclosing security issues.

## Author

[Auth0](https://auth0.com)

## License

This project is licensed under the MIT license. See the [LICENSE](LICENSE) file for more info.
