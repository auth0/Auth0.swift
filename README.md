# Auth0.swift

[![CI Status](http://img.shields.io/travis/auth0/Auth0.swift.svg?style=flat-square)](https://travis-ci.org/auth0/Auth0.swift)
[![Coverage Status](https://img.shields.io/codecov/c/github/auth0/Auth0.swift/master.svg?style=flat-square)](https://codecov.io/github/auth0/Auth0.swift)
[![Version](https://img.shields.io/cocoapods/v/Auth0.svg?style=flat-square)](http://cocoadocs.org/docsets/Auth0)
[![License](https://img.shields.io/cocoapods/l/Auth0.svg?style=flat-square)](http://cocoadocs.org/docsets/Auth0)
[![Platform](https://img.shields.io/cocoapods/p/Auth0.svg?style=flat-square)](http://cocoadocs.org/docsets/Auth0)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)
![Swift 3.0](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat-square)

Swift toolkit for Auth0 API

## Requirements

iOS 9+ and Xcode 8 (Swift 3.0)

> For Swift 2.3 you need to use [v1@swift-2.3](https://github.com/auth0/Auth0.swift/tree/v1@swift-2.3) branch

If using CocoaPods we recommend version 1.1.0 or later.

## Installation

###CocoaPods

Auth0.swift is available through [CocoaPods](http://cocoapods.org). 
To install it, simply add the following line to your Podfile:

```ruby
pod "Auth0", '~> 1.1'
```

###Carthage

In your Cartfile add this line

```
github "auth0/Auth0.swift" ~> 1.1
```

## Usage

### Auth0.plist

To avoid specifying clientId & domain you can add a `Auth0.plist` file to your main bundle. Here is an example of the file contents:

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

> This will load clientId & domain in authentication API & OAuth2 methods, and only domain for management API methods.

### Authentication API

#### Login with database connection

```swift
Auth0
   .authentication()
   .login(
       usernameOrEmail: "support@auth0.com", 
       password: "a secret password", 
       connection: "Username-Password-Authentication"
       )
   .start { result in
       switch result {
       case .success(let credentials):
           print("access_token: \(credentials.accessToken)")
       case .failure(let error):
           print(error)
       }
   }
```

#### Passwordless Login

```swift
Auth0
   .authentication()
   .startPasswordless(email: "support@auth0.com", connection: "email")
   .start { result in
       switch result {
       case .success:
           print("Sent OTP to support@auth0.com!")
       case .failure(let error):
           print(error)
       }
   }
```


```swift
Auth0
   .authentication()
   .login(
       usernameOrEmail: "support@auth0.com", 
       password: "email OTP", 
       connection: "email"
       )
   .start { result in
       switch result {
       case .success(let credentials):
           print("access_token: \(credentials.accessToken)")
       case .failure(let error):
           print(error)
       }
   }
```


#### Sign Up with database connection

```swift
Auth0
   .authentication()
   .signUp(
       email: "support@auth0.com", 
       password: "a secret password", 
       connection: "Username-Password-Authentication"
       )
   .start { result in
       switch result {
       case .success(let credentials):
           print("access_token: \(credentials.accessToken)")
       case .failure(let error):
           print(error)
       }
   }
```


#### Get user information

```swift
Auth0
   .authentication()
   .tokenInfo(token: "user id_token")
   .start { result in
       switch result {
       case .success(let profile):
           print("profile email: \(profile.email)")
       case .failure(let error):
           print(error)
       }
   }
```

### Management API (Users)

#### Update user_metadata

```swift
Auth0
    .users(token: "user token")
    .patch("user identifier", userMetadata: ["first_name": "John", "last_name": "Doe"])
    .start { result in
        switch result {
        case .success(let userInfo):
            print("user: \(userInfo)")
        case .failure(let error):
            print(error)
        }
    }
```

#### Link users

```swift
Auth0
   .users(token: "user token")
   .link(userId, withOtherUserToken: "another user token")
   .start { result in
      switch result {
      case .success(let userInfo):
         print("user: \(userInfo)")
      case .failure(let error):
         print(error)
      }
   }
```

### Web-based Auth (iOS Only)

First go to [Auth0 Dashboard](https://manage.auth0.com/#/applications) and go to application's settings. Make sure you have in *Allowed Callback URLs* a URL with the following format:

```
{YOUR_BUNDLE_IDENTIFIER}://{YOUR_AUTH0_DOMAIN}/ios/{YOUR_BUNDLE_IDENTIFIER}/callback
```

In your application's `Info.plist` file register your iOS Bundle Identifier as a custom scheme like this:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>None</string>
        <key>CFBundleURLName</key>
        <string>auth0</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>{YOUR_BUNDLE_IDENTIFIER}</string>
        </array>
    </dict>
</array>
```

> **Auth0.swift** will only handle URLs with your Auth0 domain as host, e.g. `com.auth0.MyApp://samples.auth0.com/ios/com.auth0.MyApp/callback`

and add the following method in your application's `AppDelegate`

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    return Auth0.resumeAuth(url, options:options)
}
```

#### Authenticate with any Auth0 connection

```swift
Auth0
    .webAuth()
    .connection("facebook")
    .start { result in
        switch result {
        case .success(let credentials):
            print("credentials: \(credentials)")
        case .failure(let error):
            print(error)
        }
    }
```

#### Specify scope

```swift
Auth0
    .webAuth()
    .scope("openid email")
    .connection("google-oauth2")
    .start { result in
        switch result {
        case .success(let credentials):
            print("credentials: \(credentials)")
        case .failure(let error):
            print(error)
        }
    }
```

#### Authenticate with Auth0 hosted login page

```swift
Auth0
    .webAuth()
    .start { result in
        switch result {
        case .success(let credentials):
            print("credentials: \(credentials)")
        case .failure(let error):
            print(error)
        }
    }
```

### Logging

To enable Auth0.swift to log HTTP request and OAuth2 flow for debugging you can call the following method in either `WebAuth`, `Authentication` or `Users` object:

```swift
var auth0 = Auth0.authentication()
auth0.logging(enabled: true)
```

Then for a OAuth2 authentication you'll see in the console:

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

> Only set this flag for **DEBUG** only or you'll be leaking user's credentials in the device log.

## What is Auth0?

Auth0 helps you to:

* Add authentication with [multiple authentication sources](https://docs.auth0.com/identityproviders), either social like **Google, Facebook, Microsoft Account, LinkedIn, GitHub, Twitter, Box, Salesforce, amont others**, or enterprise identity systems like **Windows Azure AD, Google Apps, Active Directory, ADFS or any SAML Identity Provider**.
* Add authentication through more traditional **[username/password databases](https://docs.auth0.com/mysql-connection-tutorial)**.
* Add support for **[linking different user accounts](https://docs.auth0.com/link-accounts)** with the same user.
* Support for generating signed [Json Web Tokens](https://docs.auth0.com/jwt) to call your APIs and **flow the user identity** securely.
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
