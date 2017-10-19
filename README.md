# Auth0.swift

[![CircleCI](https://img.shields.io/circleci/project/github/auth0/Auth0.swift.svg?style=flat-square)](https://circleci.com/gh/auth0/Auth0.swift/tree/master)
[![Coverage Status](https://img.shields.io/codecov/c/github/auth0/Auth0.swift/master.svg?style=flat-square)](https://codecov.io/github/auth0/Auth0.swift)
[![Version](https://img.shields.io/cocoapods/v/Auth0.svg?style=flat-square)](http://cocoadocs.org/docsets/Auth0)
[![License](https://img.shields.io/cocoapods/l/Auth0.svg?style=flat-square)](http://cocoadocs.org/docsets/Auth0)
[![Platform](https://img.shields.io/cocoapods/p/Auth0.svg?style=flat-square)](http://cocoadocs.org/docsets/Auth0)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)
![Swift 3.2](https://img.shields.io/badge/Swift-3.2-orange.svg?style=flat-square)

Swift toolkit that lets you communicate efficiently with many of the [Auth0 API](https://auth0.com/docs/api/info) functions and enables you to seamlessly integrate the Auth0 login.

## Requirements

- iOS 9 or later
- Xcode 8.3 / 9.0
- Swift 3.2

## Installation

#### Carthage

If you are using Carthage, add the following lines to your `Cartfile`:

```ruby
github "auth0/Auth0.swift" ~> 1.9
```

Then run `carthage bootstrap`.

> For more information about Carthage usage, check [their official documentation](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos).

#### Cocoapods

If you are using [Cocoapods](https://cocoapods.org/), add these lines to your `Podfile`:

```ruby
use_frameworks!
pod 'Auth0', '~> 1.9'
```

Then run `pod install`.

> For further reference on Cocoapods, check [their official documentation](http://guides.cocoapods.org/using/getting-started.html).

> ### Upgrade Notes
> If you are using the [clearSession](https://github.com/auth0/Auth0.swift/blob/master/Auth0/WebAuth.swift#L235) method in iOS 11+. You will need to ensure that the **Callback URL** has been added to the **Allowed Logout URLs** section of your client in the [Auth0 Dashboard](https://manage.auth0.com/#/clients/).



## Getting started

### Authentication with hosted login page (iOS Only)

1. Import **Auth0** into your project.        
```swift
import Auth0
```

2. Present the hosted login page.
```swift
Auth0
    .webAuth()
    .audience("https://{YOUR_AUTH0_DOMAIN}/userinfo")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with \(error)")
        }
    }
```

> This snippet sets the `audience` to ensure OIDC compliant responses, this can also be achieved by enabling the **OIDC Conformant** switch in your Auth0 dashboard under `Client / Settings / Advanced OAuth`. For more information please check [this documentation](https://auth0.com/docs/api-auth/intro#how-to-use-the-new-flows).

3. Allow Auth0 to handle authentication callbacks. In your `AppDelegate.swift` add the following:
```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
    return Auth0.resumeAuth(url, options: options)
}
```

### Configuration

In order to use Auth0 you need to provide your Auth0 **ClientId** and **Domain**.

> Auth0 ClientId & Domain can be found in your [Auth0 Dashboard](https://manage.auth0.com)

#### Adding Auth0 Credentials

In your application bundle add a `plist` file named `Auth0.plist` with the following information.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>ClientId</key>
  <string>{YOUR_CLIENT_ID}</string>
  <key>Domain</key>
  <string>{YOUR_DOMAIN}</string>
</dict>
</plist>
```

#### Configure Callback URLs (iOS Only)

Callback URLs are the URLs that Auth0 invokes after the authentication process. Auth0 routes your application back to this URL and appends additional parameters to it, including a token. Since callback URLs can be manipulated, you will need to add your application's URL to your client's **Allowed Callback URLs** for security. This will enable Auth0 to recognize these URLs as valid. If omitted, authentication will not be successful.

In your application's `Info.plist` file, register your iOS Bundle Identifer as a custom scheme:

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
            <string>$(YOUR_BUNDLE_IDENTIFIER)</string>
        </array>
    </dict>
</array>
```

> If your `Info.plist` is not shown in this format, you can **Right Click** on `Info.plist` in Xcode and then select **Open As / Source Code**.

Finally, go to your [Auth0 Dashboard](${manage_url}/#/applications/${account.clientId}/settings) and make sure that **Allowed Callback URLs** contains the following entry:

```text
{YOUR_BUNDLE_IDENTIFIER}://${YOUR_AUTH0_DOMAIN}/ios/{YOUR_BUNDLE_IDENTIFIER}/callback
```

e.g. If your bundle identifier was `com.company.myapp` and your domain was `company.auth0.com` then this value would be

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
       case .success(let profile):
           print("User Profile: \(profile)")
       case .failure(let error):
           print("Failed with \(error)")
       }
   }
```

#### Renew user credentials

Use a [Refresh Token](https://auth0.com/docs/tokens/refresh-token/) to renew user credentials. It's recommended that you read and understand the refresh token process before implementing.

```swift
Auth0
    .authentication()
    .renew(withRefreshToken: refreshToken)
    .start { result in
        switch(result) {
        case .success(let credentials):
            print("Obtained new credentials: \(credentials)")
        case .failure(let error):
            print("Failed with \(error)")
        }
    }
```

### Credentials Management Utility (iOS Only)

```swift
let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
```

#### Store Credentials

Store user credentials securely in the KeyChain.

```swift
credentialsManager.store(credentials: credentials)
```

#### Retrieve stored credentials and auto-renew if expired

```swift
credentialsManager.credentials { error, credentials in
    guard error == nil else { return print("Failed with \(error)") }
    print("Obtained credentials: \(credentials)")
}
```

### Authentication API (iOS / macOS / tvOS)

The Authentication API exposes AuthN/AuthZ functionality of Auth0, as well as the supported identity protocols like OpenID Connect, OAuth 2.0, and SAML.
We recommend using our Hosted Login Page but if you wish to build your own UI you can use our API endpoints to do so. However some Auth flows (Grant types) are disabled by default so you will need to enable them via your Auth0 Dashboard as explained in [this guide](https://auth0.com/docs/clients/client-grant-types#edit-available-grant_types).

These are the required Grant Types that needs to be enabled in your client:

* **Password**: For login with username/password using a realm (or connection name). If you set the grants via API you should activate both `http://auth0.com/oauth/grant-type/password-realm` and `password`, otherwise Auth0 Dashboard will take care of activating both when `Password` is enabled.

#### Login with database connection (via Realm)

```swift
Auth0
    .authentication()
    .login(
        usernameOrEmail: "support@auth0.com",
        password: "secret-password",
        realm: "Username-Password-Authentication",
        scope: "openid")
     .start { result in
         switch result {
         case .success(let credentials):
            print("Obtained credentials: \(credentials)")
         case .failure(let error):
            print("Failed with \(error)")
         }
     }
```

> This requires `Password` Grant or `http://auth0.com/oauth/grant-type/password-realm`

#### Sign Up with database connection

```swift
Auth0
    .authentication()
    .createUser(
        email: "support@auth0.com",
        password: "secret-password",
        connection: "Username-Password-Authentication",
        userMetadata: ["first_name": "First",
                       "last_name": "Last"]
    )
    .start { result in
        switch result {
        case .success(let user):
            print("User Signed up: \(user)")
        case .failure(let error):
            print("Failed with \(error)")
        }
    }
```

### Management API (Users)

#### Retrieve user_metadata

```swift
Auth0
    .users(token: idToken)
    .get("user identifier", fields: ["user_metadata"], include: true)
    .start { result in
        switch result {
        case .success(let userInfo):
            print("user: \(userInfo)")
        case .failure(let error):
            print(error)
        }
    }
```

#### Update user_metadata

```swift
Auth0
    .users(token: idToken)
    .patch("user identifier", userMetadata: ["first_name": "John", "last_name": "Doe"])
    .start { result in
        switch result {
        case .success(let userInfo):
            print("User: \(userInfo)")
        case .failure(let error):
            print("Failed with \(error)")
        }
    }
```

#### Link an account

```swift
Auth0
    .users(token: idToken)
    .link("user identifier", withOtherUserToken: "another user token")
    .start { result in
        switch result {
        case .success(let userInfo):
            print("User: \(userInfo)")
        case .failure(let error):
            print("Failed with \(error)")
        }
    }
```

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

* Add authentication with [multiple authentication sources](https://docs.auth0.com/identityproviders), either social like **Google, Facebook, Microsoft Account, LinkedIn, GitHub, Twitter, Box, Salesforce, amont others**, or enterprise identity systems like **Windows Azure AD, Google Apps, Active Directory, ADFS or any SAML Identity Provider**.
* Add authentication through more traditional **[username/password databases](https://docs.auth0.com/mysql-connection-tutorial)**.
* Add support for **[linking different user accounts](https://docs.auth0.com/link-accounts)** with the same user.
* Support for generating signed [JSON Web Tokens](https://docs.auth0.com/jwt) to call your APIs and **flow the user identity** securely.
* Analytics of how, when and where users are logging in.
* Pull data from other sources and add it to the user profile, through [JavaScript rules](https://docs.auth0.com/rules).

## Create a free Auth0 Account

1. Go to [Auth0](https://auth0.com) and click Sign Up.
2. Use Google, GitHub or Microsoft Account to login.

## Issue Reporting

If you have found a bug or if you have a feature request, please report them at this repository issues section. Please do not report security vulnerabilities on the public GitHub issue tracker. The [Responsible Disclosure Program](https://auth0.com/whitehat) details the procedure for disclosing security issues.

## Author

[Auth0](auth0.com)

## License

This project is licensed under the MIT license. See the [LICENSE](LICENSE.txt) file for more info.
