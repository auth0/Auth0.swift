# Auth0.swift

[![CI Status](http://img.shields.io/travis/auth0/Auth0.swift.svg?style=flat-square)](https://travis-ci.org/auth0/Auth0.swift)
[![Version](https://img.shields.io/cocoapods/v/Auth0.svg?style=flat-square)](http://cocoadocs.org/docsets/Auth0)
[![License](https://img.shields.io/cocoapods/l/Auth0.svg?style=flat-square)](http://cocoadocs.org/docsets/Auth0)
[![Platform](https://img.shields.io/cocoapods/p/Auth0.svg?style=flat-square)](http://cocoadocs.org/docsets/Auth0)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)

Swift toolkit for Auth0 API (Authentication & Management)

## Requirements

iOS 9+ and Xcode 7.3 (Swift 2.2)

## Installation

###CocoaPods

Auth0.swift is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Auth0", '~> 1.0.0-beta.1'
```

###Carthage

In your Cartfile add this line

```
github "auth0/Auth0.swift"
```

## Auth0.swift

### Authentication API

#### Login with database connection

```swift
     Auth0
        .authentication("ClientId", domain: "samples.auth0.com")
        .login(
            "support@auth0.com", 
            password: "a secret password", 
            connection: "Username-Password-Authentication"
            )
        .start { result in
            switch result {
            case .Success(let credentials):
                print("access_token: \(credentials.accessToken)")
            case .Failure(let error):
                print(error)
            }
        }
```

#### Passwordless Login

```swift
     Auth0
        .authentication("ClientId", domain: "samples.auth0.com")
        .startPasswordless(email: "support@auth0.com", connection: "email")
        .start { result in
            switch result {
            case .Success:
                print("Sent OTP to support@auth0.com!")
            case .Failure(let error):
                print(error)
            }
        }
```


```swift
     Auth0
        .authentication("ClientId", domain: "samples.auth0.com")
        .login(
            "support@auth0.com", 
            password: "email OTP", 
            connection: "email"
            )
        .start { result in
            switch result {
            case .Success(let credentials):
                print("access_token: \(credentials.accessToken)")
            case .Failure(let error):
                print(error)
            }
        }
```


#### Sign Up with database connection

```swift
     Auth0
        .authentication("ClientId", domain: "samples.auth0.com")
        .signUp(
            "support@auth0.com", 
            password: "a secret password", 
            connection: "Username-Password-Authentication"
            )
        .start { result in
            switch result {
            case .Success(let credentials):
                print("access_token: \(credentials.accessToken)")
            case .Failure(let error):
                print(error)
            }
        }
```


#### Get user information

```swift
     Auth0
        .authentication("ClientId", domain: "samples.auth0.com")
        .tokenInfo("user id_token")
        .start { result in
            switch result {
            case .Success(let profile):
                print("profile email: \(profile.email)")
            case .Failure(let error):
                print(error)
            }
        }
```

### Management API (Users)

#### Update user_metadata

```swift
    Auth0
        .users("user token", domain: "samples.auth0.com")
        .patch("user identifier", userMetadata: ["first_name": "John", "last_name": "Doe"])
        .start { result in
            switch result {
            case .Success(let userInfo):
                print("user: \(userInfo)")
            case .Failure(let error):
                print(error)
            }
        }
```

### OAuth2 (iOS Only)

First go to [Auth0 Dashboard](https://manage.auth0.com/#/applications) and go to application's settings. Make sure you have in *Allowed Callback URLs* a URL with the following format:

```
{YOUR_BUNDLE_IDENTIFIER}://{YOUR_AUTH0_DOMAIN}/ios/{YOUR_BUNDLE_IDENTIFIER}/callback
```

In your application's `Info.plist` file register your iOS Bundle Identifier as a custom scheme like this:

```
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

> **Auth0.swift** will only handle URLs with your Auth0 domain as host, e.g. `com.auth0.OAuth2://samples.auth0.com/ios/com.auth0.OAuth2/callback`

and add the following method in your application's `AppDelegate`

```swift
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return Auth0.resumeAuth(url, options: options)
    }
```

#### Authenticate with any Auth0 connection

```swift
    Auth0
        .oauth2("ClientId", domain: "samples.auth0.com")
        .connection("facebook")
        .start { result in
            switch result {
            case .Success(let credentials):
                print("credentials: \(credentials)")
            case .Failure(let error):
                print(error)
            }
        }
```

#### Authenticate with any Auth0 connection

```swift
    Auth0
        .oauth2("ClientId", domain: "samples.auth0.com")
        .connection("facebook")
        .start { result in
            switch result {
            case .Success(let credentials):
                print("credentials: \(credentials)")
            case .Failure(let error):
                print(error)
            }
        }
```

#### Authenticate with Auth0 hosted login page

```swift
    Auth0
        .oauth2("ClientId", domain: "samples.auth0.com")
        .start { result in
            switch result {
            case .Success(let credentials):
                print("credentials: \(credentials)")
            case .Failure(let error):
                print(error)
            }
        }
```

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
