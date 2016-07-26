# Change Log

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