# Change Log

## [1.5.0](https://github.com/auth0/Auth0.swift/tree/1.5.0) (2017-03-27)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.4.0...1.5.0)

**Added**
- Method to check native auth availability for provider in the device [\#104](https://github.com/auth0/Auth0.swift/pull/104) ([cocojoe](https://github.com/cocojoe))

## [1.4.0](https://github.com/auth0/Auth0.swift/tree/1.4.0) (2017-03-16)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.3.0...1.4.0)

**Added**
- Added scope to refresh token [\#102](https://github.com/auth0/Auth0.swift/pull/102) ([hzalaz](https://github.com/hzalaz))

## [1.3.0](https://github.com/auth0/Auth0.swift/tree/1.3.0) (2017-03-13)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.2.0...1.3.0)

**Added**
- Authentication can now create WebAuth instances for given connection [\#98](https://github.com/auth0/Auth0.swift/pull/98) ([cocojoe](https://github.com/cocojoe))
- Added connection scopes to web auth [\#96](https://github.com/auth0/Auth0.swift/pull/96) ([hzalaz](https://github.com/hzalaz))

**Changed**
- Restrict webauth only to iOS [\#101](https://github.com/auth0/Auth0.swift/pull/101) ([hzalaz](https://github.com/hzalaz))

**Fixed**
- Avoid WebAuth to retain UIApplication root ViewController [\#95](https://github.com/auth0/Auth0.swift/pull/95) ([cocojoe](https://github.com/cocojoe))

## [1.2.0](https://github.com/auth0/Auth0.swift/tree/1.2.0) (2017-02-06)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.1.1...1.2.0)


**Added**
- Native Authentication support [\#86](https://github.com/auth0/Auth0.swift/pull/86) ([cocojoe](https://github.com/cocojoe))
- Added SwiftLint to project [\#84](https://github.com/auth0/Auth0.swift/pull/84) ([cocojoe](https://github.com/cocojoe))
- Profile timestamp to expect epoch, fallback to ISO8601 [\#83](https://github.com/auth0/Auth0.swift/pull/83) ([cocojoe](https://github.com/cocojoe))

**Fixed**
- Support OIDC /userInfo in Profile [\#89](https://github.com/auth0/Auth0.swift/pull/89) ([cocojoe](https://github.com/cocojoe))

## [1.1.1](https://github.com/auth0/Auth0.swift/tree/1.1.1) (2017-01-02)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.1.0...1.1.1)


**Fixed**
- Ensure state set correctly when set via parameters [\#77](https://github.com/auth0/Auth0.swift/pull/77) ([cocojoe](https://github.com/cocojoe))

## [1.1.0](https://github.com/auth0/Auth0.swift/tree/1.1.0) (2016-12-16)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.1...1.1.0)

**Closed issues**
- Missing API [\#59](https://github.com/auth0/Auth0.swift/issues/59)
- Delegation for Firebase [\#55](https://github.com/auth0/Auth0.swift/issues/55)

**Added**
- Credentials exposes expires_in if returned after auth [\#72](https://github.com/auth0/Auth0.swift/pull/72) ([cocojoe](https://github.com/cocojoe))
- Added grant type password realm support [\#71](https://github.com/auth0/Auth0.swift/pull/71) ([cocojoe](https://github.com/cocojoe))
- Support refresh token authentication [\#69](https://github.com/auth0/Auth0.swift/pull/69) ([cocojoe](https://github.com/cocojoe))
- Support for audience parameter for WebAuth [\#67](https://github.com/auth0/Auth0.swift/pull/67) ([cocojoe](https://github.com/cocojoe))
- Multiple respone_type support [\#65](https://github.com/auth0/Auth0.swift/pull/65) ([cocojoe](https://github.com/cocojoe))
- Support id_token response type [\#62](https://github.com/auth0/Auth0.swift/pull/62) ([cocojoe](https://github.com/cocojoe))

**Changed**
- Expose credentials init [\#73](https://github.com/auth0/Auth0.swift/pull/73) ([cocojoe](https://github.com/cocojoe))

**Deprecated**
- Deprecate tokeninfo [\#70](https://github.com/auth0/Auth0.swift/pull/70) ([cocojoe](https://github.com/cocojoe))

## [1.0.1](https://github.com/auth0/Auth0.swift/tree/1.0.1) (2016-11-23)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.0...1.0.1)

**Fixed**
- Expose authentication wrapper [\#60](https://github.com/auth0/Auth0.swift/pull/60) ([cocojoe](https://github.com/cocojoe))

## [1.0.0](https://github.com/auth0/Auth0.swift/tree/1.0.0) (2016-10-06)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.0-rc.4...1.0.0)

**Closed issues**
- Facebook Login web page does not redirect to the application at the first login [\#51](https://github.com/auth0/Auth0.swift/issues/51)

**Fixed**
- Properly parse authorize response [\#56](https://github.com/auth0/Auth0.swift/pull/56) ([hzalaz](https://github.com/hzalaz))

## [1.0.0-rc.4](https://github.com/auth0/Auth0.swift/tree/1.0.0-rc.4) (2016-09-18)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.0-rc.3...1.0.0-rc.4)

This version (and future ones) requires Xcode 8 and Swift 3. For Swift 2.3 please check the branch [v1@swift-2.3](https://github.com/auth0/Auth0.swift/tree/v1@swift-2.3)

**Closed issues:**
- Auth0 Swift 3 support [\#45](https://github.com/auth0/Auth0.swift/issues/45) ([aqeelb](https://github.com/aqeelb))

**Changed:**
- Swift 3 [\#49](https://github.com/auth0/Auth0.swift/pull/49) ([hzalaz](https://github.com/hzalaz))
- Use protocols [\#47](https://github.com/auth0/Auth0.swift/pull/47) ([hzalaz](https://github.com/hzalaz))

## [1.0.0-rc.3](https://github.com/auth0/Auth0.swift/tree/1.0.0-rc.3) (2016-09-14)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.0-rc.2...1.0.0-rc.3)

**Closed issues:**

- Xcode 8 Support? [\#44](https://github.com/auth0/Auth0.swift/issues/44) ([gbejarano01](https://github.com/gbejarano01))

**Changed:**

- Update for Swift 2.3 & Xcode 8 [\#46](https://github.com/auth0/Auth0.swift/pull/46) ([hzalaz](https://github.com/hzalaz))

## [1.0.0-rc.2](https://github.com/auth0/Auth0.swift/tree/1.0.0-rc.2) (2016-09-09)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.0-rc.1...1.0.0-rc.2)

**Changed:**

- Rework Logging [\#43](https://github.com/auth0/Auth0.swift/pull/43) ([hzalaz](https://github.com/hzalaz))

**Breaking changes:**

The function `enableLogging()` was removed, so now to enable logging in the library you should enable it per-client instead of globally.

For Auth API
```swift
var auth = Auth0.authentication()
auth.logging(enabled: true)
```

For Users API
```swift
var users = Auth0.users(token: "token")
users.logging(enabled: true)
```

Also now you can provide a custom Logger to replace the default one (which just uses Swift `print`). It only needs to implement the protocol `Logger`

```swift
let logger = MyCustomLogger()
var auth = Auth0.authentication()
auth.usingLogger(logger)
```

## [1.0.0-rc.1](https://github.com/auth0/Auth0.swift/tree/1.0.0-rc.1) (2016-08-17)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.0-beta.7...1.0.0-rc.1)

**Added:**

- Handle too many attempts error [\#42](https://github.com/auth0/Auth0.swift/pull/42) ([hzalaz](https://github.com/hzalaz))
- Add WebAuth protocol [\#41](https://github.com/auth0/Auth0.swift/pull/41) ([hzalaz](https://github.com/hzalaz))

## [1.0.0-beta.7](https://github.com/auth0/Auth0.swift/tree/1.0.0-beta.7) (2016-07-29)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.0-beta.6...1.0.0-beta.7)

**Added:**

- Add tvOS & watchOS targets [\#40](https://github.com/auth0/Auth0.swift/pull/40) ([hzalaz](https://github.com/hzalaz))

**Changed:**

- Improve error handling and Auth session management [\#39](https://github.com/auth0/Auth0.swift/pull/39) ([hzalaz](https://github.com/hzalaz))
- Avoid using global telemetry. [\#38](https://github.com/auth0/Auth0.swift/pull/38) ([hzalaz](https://github.com/hzalaz))

## [1.0.0-beta.6](https://github.com/auth0/Auth0.swift/tree/1.0.0-beta.6) (2016-07-26)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.0-beta.5...1.0.0-beta.6)

**Added:**

- Unlink method in ObjC bridge [\#36](https://github.com/auth0/Auth0.swift/pull/36) ([sebacancinos](https://github.com/sebacancinos))
- Load Auth0 credentials from plist from ObjC [\#37](https://github.com/auth0/Auth0.swift/pull/37) ([hzalaz](https://github.com/hzalaz))

## [1.0.0-beta.5](https://github.com/auth0/Auth0.swift/tree/1.0.0-beta.5) (2016-06-30)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.0-beta.4...1.0.0-beta.5)

**Changed:**

- Renamed `UserProfile` to `Profile` [\#34](https://github.com/auth0/Auth0.swift/pull/34) ([hzalaz](https://github.com/hzalaz))

**Breaking changes:**

The `UserProfile` is not named `Profile` (in Objective C is `A0Profile`).

## [1.0.0-beta.4](https://github.com/auth0/Auth0.swift/tree/1.0.0-beta.4) (2016-06-30)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.0-beta.3...1.0.0-beta.4)

**Added:**

- Allow to override telemetry info [\#32](https://github.com/auth0/Auth0.swift/pull/32) ([hzalaz](https://github.com/hzalaz))

**Fixed:**

- Made `start()` of `ConcatRequest` public [\#31](https://github.com/auth0/Auth0.swift/pull/31) ([pablolvillar](https://github.com/pablolvillar))
- Send Authorization header was sent for Users API [\#33](https://github.com/auth0/Auth0.swift/pull/33) ([hzalaz](https://github.com/hzalaz))

## [1.0.0-beta.3](https://github.com/auth0/Auth0.swift/tree/1.0.0-beta.3) (2016-06-20)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.0-beta.2...1.0.0-beta.3)

**Added:**

- Show better error when PKCE is not enabled in client [\#30](https://github.com/auth0/Auth0.swift/pull/30) ([hzalaz](https://github.com/hzalaz))
- Auth0 telemetry information [\#29](https://github.com/auth0/Auth0.swift/pull/29) ([hzalaz](https://github.com/hzalaz))
- Multifactor support for `/oauth/ro` [\#28](https://github.com/auth0/Auth0.swift/pull/28) ([hzalaz](https://github.com/hzalaz))

**Changed:**

- Added parameter labels in Authentication API methods [\#27](https://github.com/auth0/Auth0.swift/pull/27) ([hzalaz](https://github.com/hzalaz))
- Reworked Error handling [\#26](https://github.com/auth0/Auth0.swift/pull/26) ([hzalaz](https://github.com/hzalaz))

**Breaking changes:**

Most of the Authentication API methods first parameters labels are required so for example this call:

```swift
Auth0
    .login("mail@mail.com", password: "secret", connection: "connection")
```

now needs to have the `usernameOrEmail` parameter label

```swift
Auth0
    .login(usernameOrEmail: "mail@mail.com", password: "secret", connection: "connection")
```

Now all `Result` object return `ErrorType` instead of a specific error, this means that OS errors like no network, or connection could not be established are not wrapped in any Auth0 error anymore.

Also the error types that **Auth0.swift** API clients can return are no longer an enum but a simple object:

* Authentication API: `AuthenticationError`
* Management API: `ManagementError`

Each of them has it's own values according at what each api returns when the request fails. Now to handle **Auth0.swift** errors in your callback, you can do the following:

```swift
Auth0
    .login(usernameOrEmail: "mail@mail.com", password: "secret", connection: "connection")
    .start { result in
        switch result {
        case .Success(let credentials):
            print(credentials)
        case .Failure(let cause as AuthenticationError):
            print("Auth0 error was \(cause)")
        case .Failure(let cause):
            print("Unknown error: \(cause)")
        }
    }
```

Also, `AuthenticationError` has some helper methods to check for common failures:

```swift
Auth0
    .login(usernameOrEmail: "mail@mail.com", password: "secret", connection: "connection")
    .start { result in
        switch result {
        case .Success(let credentials):
            print(credentials)
        case .Failure(let cause as AuthenticationError) where cause.isMultifactorRequired:
            print("Need to ask the user for his mfa code!")
        case .Failure(let cause):
            print("Login failed with error: \(cause)")
        }
    }
```

## [1.0.0-beta.2](https://github.com/auth0/Auth0.swift/tree/1.0.0-beta.2) (2016-06-09)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/1.0.0-beta.1...1.0.0-beta.2)

**Added:**

- Authenticate a user using web-based authentication with Auth0, e.g. social authentication. (iOS Only) [\#19](https://github.com/auth0/Auth0.swift/pull/19),[\#20](https://github.com/auth0/Auth0.swift/pull/20) & [\#24](https://github.com/auth0/Auth0.swift/pull/24) ([hzalaz](https://github.com/hzalaz))
- Load Auth0 clientId & domain from a plist file [\#21](https://github.com/auth0/Auth0.swift/pull/21) ([hzalaz](https://github.com/hzalaz))
- Request Logging support [\#23](https://github.com/auth0/Auth0.swift/pull/23) ([hzalaz](https://github.com/hzalaz))

**Fixed:**

- Date parsing format in `UserProfile` [\#22](https://github.com/auth0/Auth0.swift/pull/22) ([srna](https://github.com/srna))

## [1.0.0-beta.1](https://github.com/auth0/Auth0.swift/tree/1.0.0-beta.1) (2016-05-25)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/0.3.0...1.0.0-beta.1)

**Added:**

- Auth0 Authentication API endpoints, now you can use **Auth0.swift** to write your own login box.

**Changed:**

- Dropped support for iOS 8
- Reworked Swift API and updated to Swift 2.2
- Removed Alamofire as dependency, all networking is done with `NSURLSession` directly
- Request callbacks, in Swift, have a single value of enum `Result<Payload,ErrorType>`
- Improved code docs

## [0.3.0](https://github.com/auth0/Auth0.swift/tree/0.3.0) (2016-04-25)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/0.2.0...0.3.0)

**Closed issues:**

- Alamofire dependency [\#5](https://github.com/auth0/Auth0.swift/issues/5)

**Merged pull requests:**

- Update dependencies and fix compile issues [\#7](https://github.com/auth0/Auth0.swift/pull/7) ([hzalaz](https://github.com/hzalaz))
- Load domain from Auth0.plist if not in main infoDictionary [\#4](https://github.com/auth0/Auth0.swift/pull/4) ([bradfol](https://github.com/bradfol))

## [0.2.0](https://github.com/auth0/Auth0.swift/tree/0.2.0) (2015-09-17)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/0.1.2...0.2.0)

**Merged pull requests:**

- Swift 2.0 [\#2](https://github.com/auth0/Auth0.swift/pull/2) ([hzalaz](https://github.com/hzalaz))

## [0.1.2](https://github.com/auth0/Auth0.swift/tree/0.1.2) (2015-07-03)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/0.1.1...0.1.2)

**Merged pull requests:**

- Allow to call method users from Auth0 struct [\#1](https://github.com/auth0/Auth0.swift/pull/1) ([hzalaz](https://github.com/hzalaz))

## [0.1.1](https://github.com/auth0/Auth0.swift/tree/0.1.1) (2015-07-02)
[Full Changelog](https://github.com/auth0/Auth0.swift/compare/0.1.0...0.1.1)

## [0.1.0](https://github.com/auth0/Auth0.swift/tree/0.1.0) (2015-07-02)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
