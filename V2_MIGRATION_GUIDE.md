# v2 Migration Guide

Auth0.swift v2 includes many significant changes:

- Retrieving credentials from the Credentials Manager is now thread-safe.
- The Credentials Manager is now decoupled from [SimpleKeychain](https://github.com/auth0/SimpleKeychain).
- Usage of the Swift 5 `Result` type.
- Support for custom headers.
- Support for Combine and async/await.
- Simplified error handling.

As expected with a major release, Auth0.swift v2 contains breaking changes. Please review this guide thorougly to understand the changes required to migrate your app to v2.

## Table of contents

- [Supported languages](#supported-languages)
    * [Swift](#swift)
    * [Objective-C](#objective-c)
- [Supported platform versions](#supported-platform-versions)
- [Default values](#default-values)
    * [Scope](#scope)
- [Types removed](#types-removed)
    * [Protocols](#protocols)
    * [Type aliases](#type-aliases)
    * [Enums](#enums)
    * [Structs](#structs)
    * [Classes](#classes)
- [Methods removed](#methods-removed)
    * [Authentication client](#authentication-client)
    * [Web Auth](#web-auth)
    * [Credentials Manager](#credentials-manager)
    * [Errors](#errors)
    * [Extensions](#extensions)
- [Types changed](#types-changed)
- [Type properties changed](#type-properties-changed)
    * [`PasswordlessType` enum](#passwordlesstype-enum)
    * [`AuthenticationError` struct](#authenticationerror-struct)
    * [`ManagementError` struct](#managementerror-struct)
    * [`WebAuthError` struct](#webautherror-struct)
    * [`CredentialsManagerError` struct](#credentialsmanagererror-struct)
    * [`UserInfo` struct](#userinfo-struct)
    * [`Credentials` class](#credentials-class)
    * [`NSError` extension](#nserror-extension)
- [Method signatures changed](#method-signatures-changed)
    * [Authentication client](#authentication-client-1)
    * [Management client](#management-client)
    * [Web Auth](#web-auth-1)
    * [Credentials Manager](#credentials-manager-1)
- [Behavior changes](#behavior-changes)
    + [Web Auth](#web-auth-2)
    + [Credentials Manager](#credentials-manager-2)

## Supported languages

### Swift

The minimum supported Swift version is now **5.3**.

### Objective-C

Auth0.swift no longer supports Objective-C.

## Supported platform versions

The deployment targets for each platform were raised to:

- iOS **12.0**
- macOS **10.15**
- Mac Catalyst **13.0**
- tvOS **12.0**
- watchOS **6.2**

## Default values

### Scope

The default scope value in Web Auth and all the Authentication client methods (except `renew(withRefreshToken:scope:)`, in which `scope` keeps defaulting to `nil`) was changed from an assortment of values to `openid profile email`.

## Types removed

### Protocols

The following protocols were removed:

- `AuthResumable`
- `AuthCancelable`
- `AuthProvider`
- `NativeAuthTransaction`

`AuthResumable` and `AuthCancelable` were subsumed in `AuthTransaction`, which is no longer public.

### Type aliases

The iOS-only type alias `A0URLOptionsKey` was removed, as it is no longer needed.

### Enums

- The custom `Result` enum was removed, along with its shims. Auth0.swift is now using the Swift 5 `Result` type.
- The `Challenge.CodingKeys` enum is no longer public.

### Structs

The following structs were removed, as they were no longer being used:

- `NativeAuthCredentials`
- `ConcatRequest`

### Classes

The following Objective-C compatibility wrappers were removed:

- `_ObjectiveAuthenticationAPI`
- `_ObjectiveManagementAPI`
- `_ObjectiveOAuth2`

The following classes were also removed, as they were no longer being used:

- `Profile`
- `Identity`

You should use `UserInfo` from `userInfo(withAccessToken:)` instead.

## Methods removed

The iOS-only method `resumeAuth(_:options:)` and the macOS-only method `resumeAuth(_:)` were removed from the library, as they are no longer needed. You can safely remove them from your app.

### Authentication client

#### `login(usernameOrEmail:password:multifactorCode:connection:scope:parameters:)`

You should use `login(usernameOrEmail:password:realmOrConnection:audience:scope:)` instead.

#### `signUp(email:username:password:connection:userMetadata:scope:parameters:)`

You should use `signup(email:username:password:connection:userMetadata:rootAttributes:)` and then `login(usernameOrEmail:password:realmOrConnection:audience:scope:)` instead. That is, create the user and then log them in.

#### `tokenInfo(token:)` and `userInfo(token:)`

You should use `userInfo(withAccessToken:)` instead.

#### `tokenExchange(withParameters:)`

You should use `codeExchange(withCode:codeVerifier:redirectURI:)` instead. To pass custom parameters, use the `parameters(_:)` method from `Request`.

<details>
  <summary>Before</summary>

```swift
Auth0
    .authentication()
    .tokenExchange(withParameters: ["key": "value"]) 
    .start { result in
        // ...
    }
```
</details>

<details>
  <summary>After</summary>

```swift
Auth0
    .authentication()
    .codeExchange(withCode: code, 
                  codeVerifier: codeVerifier, 
                  redirectURI: redirectURI) 
    .parameters(["key": "value"])
    .start { result in
        // ...
    }
}
```
</details>

#### `tokenExchange(withAppleAuthorizationCode:scope:audience:fullName:)`

You should use `login(appleAuthorizationCode:fullName:profile:audience:scope:)` instead. 

#### `webAuth(withConnection:)`

You should use Web Auth with its `connection(_:)` method instead.

<details>
  <summary>Before</summary>

```swift
Auth0
    .authentication()
    .webAuth(withConnection: "some-connection")
    .start { result in
        // ...
    }
}
```
</details>

<details>
  <summary>After</summary>

```swift
Auth0
    .webAuth()
    .connection("some-connection")
    .start { result in
        // ...
    }
}
```
</details>

#### Other methods

The following methods were removed and have no replacement, as they rely on deprecated endpoints:

- `loginSocial(token:connection:scope:parameters:)`
- `delegation(withParameters:)`

### Web Auth

Auth0.swift now only supports the [authorization code flow with PKCE](https://auth0.com/blog/oauth-2-best-practices-for-native-apps/), which is used by default. For this reason, the following methods were removed from the Web Auth builder:

- `usingImplicitGrant()`
- `responseType(_:)`

The `useUniversalLink()` method was removed as well, as Universal Links [cannot be used](https://openradar.appspot.com/51091611) for OAuth redirections without user interaction since iOS 10.

`useLegacyAuthentication()` and `useLegacyAuthentication(withStyle:)` were also removed. Auth0.swift now only uses `ASWebAuthenticationSession` to perform web-based authentication.

**Check out the [FAQ](FAQ.md) for more information about the alert box that pops up by default when using Web Auth.**

### Credentials Manager

The method `enableTouchAuth(withTitle:cancelTitle:fallbackTitle:)` was removed. You should use `enableBiometrics(withTitle:cancelTitle:fallbackTitle:evaluationPolicy:)` instead.

### Errors

#### `Auth0Error`

The `init(string: String?, statusCode: Int)` initializer was removed.

#### `AuthenticationError`

The `init(string: String?, statusCode: Int)` initializer was removed.

#### `ManagementError`

The `init(string: String?, statusCode: Int)` initializer was removed.

### Extensions

#### `URL`

The `a0_url(_:)` method is no longer public.

## Types changed

- `UserInfo` was changed from class to struct.
- `Credentials` is now a `final` class that conforms to `Codable` instead of `JSONObjectPayload`.
- `Auth0Error` was renamed to `Auth0APIError`, and `Auth0Error` is now a different protocol.
- `AuthenticationError` was changed from class to struct, and it no longer conforms to `CustomNSError`.
- `ManagementError` was changed from class to struct, and it no longer conforms to `CustomNSError`.
- `WebAuthError` was changed from enum to struct.
- `CredentialsManagerError` was changed from enum to struct.

## Type properties changed

### `PasswordlessType` enum

#### Cases renamed

The following cases were lowercased, as per the naming convention of Swift 3+:

- `.Code` -> `.code`
- `.WebLink` -> `.webLink`
- `.AndroidLink` -> `.androidLink`

### `AuthenticationError` struct

#### Properties removed

The property `description` was removed in favor of `localizedDescription`, as `AuthenticationError` now conforms to `LocalizedError`.

### `ManagementError` struct

#### Properties removed

The property `description` was removed in favor of `localizedDescription`, as `ManagementError` now conforms to `LocalizedError`.

### `WebAuthError` struct

All the former enum cases are now static properties, so to switch over them you will need to add a `default` clause.

<details>
  <summary>Before</summary>

```swift
switch error {
    case .userCancelled: // handle WebAuthError
    // ...
}
```
</details>

<details>
  <summary>After</summary>

```swift
switch error {
    case .userCancelled: // handle WebAuthError
    // ...
    default: // handle unknown errors, e.g. errors added in future versions
}
```
</details>

#### Properties removed

- `infoKey`
- `errorDomain`
- `errorCode`
- `errorUserInfo`

#### Error cases removed

All the following error cases were no longer being used.

- `.noNonceProvided`
- `.invalidIdTokenNonce`
- `.cannotDismissWebAuthController`
- `.missingResponseParam`
- `.missingAccessToken`

#### Error cases renamed

- `.unknownError` was renamed to `.unknown`.
- `.noBundleIdentifierFound` was renamed to `.noBundleIdentifier`.

#### Error cases added

- `.invalidInvitationURL`, for when the invitation URL is missing the `organization` and/or the `invitation` query parameters.
- `.noAuthorizationCode`, for when the callback URL is missing the `code` query parameter.
- `.idTokenValidationFailed`, for when the ID Token validation performed after Web Auth login fails.
- `.other`, for when a different `Error` happens. That error can be accessed via the `cause: Error?` property.

### `CredentialsManagerError` struct

All the former enum cases are now static properties, so to switch over them you will need to add a `default` clause.
As static properties cannot have associated values, to access the underlying `Error` for `.renewFailed`, `.biometricsFailed`, and `.revokeFailed` use the new `cause: Error?` property.

<details>
  <summary>Before</summary>

```swift
switch error {
    case .revokeFailed(let error): handleError(error) // handle underlying Error
    // ...
}
```
</details>

<details>
  <summary>After</summary>

```swift
switch error {
    case .revokeFailed: handleError(error.cause) // handle underlying Error?
    // ...
    default: // handle unknown errors, e.g. errors added in future versions
}
```
</details>

#### Error cases renamed

- `.failedRefresh` was renamed to `.renewFailed`.
- `.touchFailed` was renamed to `.biometricsFailed`.

#### Error cases added

`.largeMinTTL`, for when the requested `minTTL` is greater than the lifetime of the renewed Access Token.

### `UserInfo` struct

It is now a struct, so its properties are no longer marked with the `@objc` attribute.

### `Credentials` class

The properties are no longer marked with the `@objc` attribute. Additionally, the following properties are no longer optional:

- `accessToken`
- `tokenType`
- `expiresIn`
- `idToken`

### `NSError` extension

These properties were removed:

- `a0_isManagementError`
- `a0_isAuthenticationError`

## Method signatures changed

### Authentication client

#### Errors

The methods of the Authentication API client now only yield errors of type `AuthenticationError`. The underlying error (if any) is available via the `cause: Error?` property of the `AuthenticationError`.

<details>
  <summary>Before</summary>

```swift
switch error {
case .success(let credentials): // ...
case .failure(let error as AuthenticationError): // handle AuthenticationError
case .failure(let error): // handle Error
}
```
</details>

<details>
  <summary>After</summary>

```swift
switch error {
case .success(let credentials): // ...
case .failure(let error): // handle AuthenticationError
}
```
</details>

#### Renamed `createUser(email:username:password:connection:userMetadata:rootAttributes:)`

The method `createUser(email:username:password:connection:userMetadata:rootAttributes:)` was renamed to `signup(email:username:password:connection:userMetadata:rootAttributes:)`.

#### Renamed `tokenExchange(withCode:codeVerifier:redirectURI:)`

The method `tokenExchange(withCode:codeVerifier:redirectURI:)` was renamed to `codeExchange(withCode:codeVerifier:redirectURI:)`.

#### Removed `parameters` parameter

The following methods lost the `parameters` parameter:

- `login(phoneNumber:code:audience:scope:)`
- `login(usernameOrEmail:password:realmOrConnection:audience:scope:)`
- `loginDefaultDirectory(withUsername:password:audience:scope:)`

To pass custom parameters to those (or any) method in the Authentication client, use the `parameters(_:)` method from `Request`:

```swift
Auth0
    .authentication()
    .renew(withRefreshToken: refreshToken) // Returns a Request
    .parameters(["key": "value"]) // 👈🏻
    .start { result in
        // ...
    }
```

#### Renamed `realm` parameter

In the method `login(usernameOrEmail:password:realmOrConnection:audience:scope:)` the `realm` parameter was renamed to `realmOrConnection`.

#### Reordered `scope` and `audience` parameters

In the following methods the `scope` and `audience` parameters switched places, for consistency with the rest of the methods in the Authentication client:

- `login(appleAuthorizationCode:fullName:profile:audience:scope:)`
- `login(facebookSessionAccessToken:profile:audience:scope:)`

#### Changed `scope` parameter to be non-optional

In the following methods the `scope` parameter became non-optional (with a default value of `openid profile email`):

- `login(email:code:audience:scope:)`
- `login(phoneNumber:code:audience:scope:)`
- `login(usernameOrEmail:password:realmOrConnection:audience:scope:)`
- `loginDefaultDirectory(withUsername:password:audience:scope:)`
- `login(appleAuthorizationCode:fullName:profile:audience:scope:)`
- `login(facebookSessionAccessToken:profile:audience:scope:)`

#### Removed `channel` parameter

The `multifactorChallenge(mfaToken:types:authenticatorId:)` method lost its `channel` parameter, which is no longer necessary.

### Management client

#### Errors

The methods of the Management API client now only yield errors of type `ManagementError`. The underlying error (if any) is available via the `cause: Error?` property of the `ManagementError`.

<details>
  <summary>Before</summary>

```swift
switch error {
case .success(let user): // ...
case .failure(let error as ManagementError): // handle ManagementError
case .failure(let error): // handle Error
}
```
</details>

<details>
  <summary>After</summary>

```swift
switch error {
case .success(let user): // ...
case .failure(let error): // handle ManagementError
}
```
</details>

### Web Auth

#### Errors

The Web Auth methods now only yield errors of type  `WebAuthError`. The underlying error (if any) is available via the `cause: Error?` property of the `WebAuthError`.

<details>
  <summary>Before</summary>

```swift
switch result {
case .success(let credentials): // ...
case .failure(let error as WebAuthError): // handle WebAuthError
case .failure(let error): // handle Error
}
```
</details>

<details>
  <summary>After</summary>

```swift
switch result {
case .success(let credentials): // ...
case .failure(let error): // handle WebAuthError
}
```
</details>

#### `clearSession(federated:)`

This method now yields a `Result<Void, WebAuthError>`, which is aliased to `WebAuthResult<Void>`. This means you can now check the type of error (e.g. if the user cancelled the operation) and act accordingly.

<details>
  <summary>Before</summary>

```swift
Auth0
    .webAuth()
    .clearSession(federated: false) { outcome in
        switch outcome {
        case true: // success
        case false: // failure
        }
    }
```
</details>

<details>
  <summary>After</summary>

```swift
Auth0
    .webAuth()
    .clearSession() { result in // federated is now false by default
        switch result {
        case .success: // ...
        case .failure(let error): // ...
        }
    }
```
</details>

### Credentials Manager

#### Errors

The methods of the Credentials Manager now only yield errors of type  `CredentialsManagerError`. The underlying error (if any) is available via the `cause: Error?` property of the `CredentialsManagerError`.

<details>
  <summary>Before</summary>

```swift
if let error = error as? CredentialsManagerError {
    // handle CredentialsManagerError
}
```
</details>

<details>
  <summary>After</summary>

```swift
switch result {
case .success(let credentials): // ...
case .failure(let error): // handle CredentialsManagerError
}
```
</details>

#### Initializer

`CredentialsManager` now takes a `CredentialsStorage` protocol as its storage argument rather than an instance of `SimpleKeychain`.

This means you can now provide your own storage layer to `CredentialsManager`.

```swift
class CustomStore: CredentialsStorage {
    var store: [String : Data] = [:]

    func getEntry(forKey: String) -> Data? {
        return store[forKey]
    }

    func setEntry(_ data: Data, forKey: String) -> Bool {
        store[forKey] = data
        return true
    }

    func deleteEntry(forKey: String) -> Bool {
        store[forKey] = nil
        return true
    }
}

let credentialsManager = CredentialsManager(authentication: authentication, 
                                            storage: CustomStore())
```

#### `credentials(withScope:minTTL:parameters:callback)`

This method now yields a `Result<Credentials, CredentialsManagerError>`, which is aliased to `CredentialsManagerResult<Credentials>`.

<details>
  <summary>Before</summary>

```swift
credentialsManager.credentials { error, credentials in
    guard error == nil, let credentials = credentials else {
        // ...
        return
    }
    // ...
}
```
</details>

<details>
  <summary>After</summary>

```swift
credentialsManager.credentials { result in
    switch result {
    case .success(let credentials): // ...
    case .failure(let error): // ...
    }
}
```
</details>

#### `revoke(headers:callback:)`

This method now yields a `Result<Void, CredentialsManagerError>`, which is aliased to `CredentialsManagerResult<Void>`.

<details>
  <summary>Before</summary>

```swift
credentialsManager.revoke { error in
    guard error == nil {
        // ...
        return
    }
    // ...
}
```
</details>

<details>
  <summary>After</summary>

```swift
credentialsManager.revoke { result in
    switch result {
    case .success: // ...
    case .failure(let error): // ...
    }
}
```
</details>

## Behavior changes

### Web Auth

#### Supported JWT signature algorithms

ID Tokens signed with the HS256 algorithm are no longer allowed. 
This is because HS256 is a symmetric algorithm, which is not suitable for public clients like mobile apps.
The only algorithm supported now is RS256, an asymmetric algorithm.

If your app is using HS256, you'll need to switch it to RS256 in the dashboard or login will fail with an error:

**Your app's settings > Advanced settings > JSON Web Token (JWT) Signature Algorithm**

#### Enforcement of the `openid` scope

If the scopes passed via the Web Auth method `.scope(_:)` do not include the `openid` scope, it will be added automatically.

```swift
Auth0
    .webAuth()
    .scope("profile email") // "openid profile email" will be used
    .start { result in
        // ...
    }
```

### Credentials Manager

#### Role of ID Token expiration in credentials validity

The ID Token expiration is no longer used to determine if the credentials are still valid. Only the Access Token expiration is used now.

#### Role of Refresh Token in credentials validity

`hasValid(minTTL:)` no longer returns `true` if a Refresh Token is present. Now, only the Access Token expiration (along with the `minTTL` value) determines the return value of `hasValid(minTTL:)`.

Note that `hasValid(minTTL:)` is no longer being called in `credentials(withScope:minTTL:parameters:callback:)` _before_ the biometrics authentication. If you were relying on this behavior, you'll need to call `hasValid(minTTL:)` before `credentials(withScope:minTTL:parameters:callback:)` yourself.

You'll also need to call `hasValid(minTTL:)` before `credentials(withScope:minTTL:parameters:callback:)` yourself if you're not using a Refresh Token. Otherwise, that method will now produce a `CredentialsManagerError.noRefreshToken` error when the credentials are not valid and there is no Refresh Token available.

#### Thread-safety when renewing credentials

The method `credentials(withScope:minTTL:parameters:callback:)` now executes the credentials renewal serially, to prevent race conditions when Refresh Token Rotation is enabled.
