# Auth0.swift

[![Auth0.swift](https://cdn.auth0.com/website/sdks/banners/swift-banner.png)]

[![Version](https://img.shields.io/cocoapods/v/Auth0.svg!style=flat)]
[![Build Status](https://img.shields.io/github/actions/workflow/status/auth0/Auth0.swift/main.yml!style=flat)]
[![Coverage Status](https://img.shields.io/codecov/c/github/auth0/Auth0.swift/master.svg!style=flat)](https://codecov.io/github/auth0/Auth0.swift)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/auth0/Auth0.swift)
[![License](https://img.shields.io/github/license/auth0/Auth0.swift.svg!style=flat)]

Auth0.swift is the official Auth0 SDK for Apple platforms, including iOS, macOS, tvOS, watchOS, and visionOS.

## Features

- Native login with Auth0 Universal Login
- Secure token storage with Credentials Manager
- Refresh token renewal and session handling
- MFA support
- DPoP and passkeys support
- Async and callback styles for modern Swift apps

## Requirements

- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 8.0+
- visionOS 1.0+
- Xcode 26.x
- Swift 6.0+

## Installation

### Swift Package Manager

Open Xcode and add this package URL:

```text
https://github.com/auth0/Auth0.swift
```

### CocoaPods

```ruby
pod 'Auth0', '~> 3.1.0'
```

### Carthage

```text
github "auth0/Auth0.swift" ~> 3.1.0
```

## Quick Start

### Configure the SDK

Create an `Auth0.plist` file in your app bundle:

```xml
<!xml version="1.0" encoding="UTF-8"!>
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

### Web Auth login

```swift
import Auth0

Auth0
    .webAuth()
    .useHTTPS()
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

### Async and await

```swift
do {
    let credentials = try await Auth0.webAuth().useHTTPS().start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```

## Credentials Manager

```swift
let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

 do {
    try credentialsManager.store(credentials: credentials)
} catch {
    print("Failed to store credentials: \(error)")
}
```

## Documentation

- Quickstart guide
- API docs
- Sample app
- Examples and feature guides

## Support

Auth0.swift follows the support policy for Apple platform versions and toolchains in the project documentation.

## License

This project is licensed under the MIT license.
