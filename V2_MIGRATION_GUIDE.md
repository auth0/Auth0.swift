# V2 MIGRATION GUIDE

Guide to migrating from `1.x` to `2.x`

## Supported languages

### Swift

The minimum supported Swift version is now 5.3.

### Objective-C

Auth0.swift no longer supports Objective-C.

## Supported platform versions

The deployment targets for each platform were raised to:

- iOS 12.0
- macOS 10.15
- Mac Catalyst 13.0
- tvOS 12.0
- watchOS 6.2

## Supported JWT signature algorithms

ID Tokens signed with the HS256 algorithm are no longer allowed. 
This is because HS256 is a symmetric algorithm, which is not suitable for public clients like mobile apps.
The only algorithm supported now is RS256, an asymmetric algorithm.

If your app is using HS256, you'll need to switch it to RS256 in the dashboard or login will fail with an error:

**Your app's settings > Advanced settings > JSON Web Token (JWT) Signature Algorithm**

## Default values

### Scope

The default scope value in Web Auth and all the Authentication client methods (except `renew(withRefreshToken:scope:)`, in which `scope` keeps defaulting to `nil`) was changed from an assortment of values to `openid profile email`.

## Types removed

### Protocols

`AuthTransaction` is no longer public, and the following protocols were removed:

- `AuthResumable`
- `AuthCancelable`
- `AuthProvider`
- `NativeAuthTransaction`

`AuthResumable` and `AuthCancelable` were subsumed in `AuthTransaction`.

### Type aliases

The iOS-only type alias `A0URLOptionsKey` was removed, as it is no longer needed.

### Enums

The custom `Result` enum was removed, along with its shims. Auth0.swift is now using the Swift 5 `Result` type.

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

## Methods Removed

The iOS-only method `resumeAuth(_:options:)` and the macOS-only method `resumeAuth(_:)` were removed from the library, as they are no longer needed.

### Authentication client

#### `login(usernameOrEmail:password:multifactorCode:connection:scope:parameters:)`

Use `login(usernameOrEmail:password:realm:audience:scope:)` instead.

#### `signUp(email:username:password:connection:userMetadata:scope:parameters:)`

Use `createUser(email:username:password:connection:userMetadata:rootAttributes:` and then `login(usernameOrEmail:password:realm:audience:scope:)` instead.

#### `tokenInfo(token:)` and `userInfo(token:)`

Use `userInfo(withAccessToken:)` instead.

#### `tokenExchange(withAppleAuthorizationCode:scope:audience:fullName:)`

Use `login(appleAuthorizationCode:fullName:profile:audience:scope:)` instead. 

#### `webAuth(withConnection:)`

Use Web Auth with its `connection(_:)` method instead:

```swift
Auth0.webAuth()
    .connection("some-connection")
    .start { result in
        // ...
    }
```

#### Other methods

The following methods were removed and have no replacement, as they rely on deprecated endpoints:

- `loginSocial(token:connection:scope:parameters:)`
- `delegation(withParameters:)`

### Web Auth

Auth0.swift now only supports the [authorization code flow with PKCE](https://auth0.com/blog/oauth-2-best-practices-for-native-apps/), which is used by default. For this reason, the following methods were removed from the Web Auth builder:

- `usingImplicitGrant()`
- `responseType(_:)`

The `useUniversalLink()` method was removed as well, as Universal Links [cannot be used](https://openradar.appspot.com/51091611) for OAuth redirections without user interaction since iOS 10.

### Credentials Manager

The method `enableTouchAuth(withTitle:cancelTitle:fallbackTitle:)` was removed. Use `enableBiometrics(withTitle:cancelTitle:fallbackTitle:evaluationPolicy:)` instead.

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

### `AuthenticationError` struct

#### Properties removed

`info: [String: Any]` is no longer public. Use the new subscript to access its values straight from the error; e.g. `error["code"]`.

#### Properties renamed

`description` was renamed to `localizedDescription`, as `AuthenticationError` now conforms to `CustomStringConvertible`.

### `ManagementError` struct

#### Properties removed

`info: [String: Any]` is no longer public. Use the new subscript to access its values straight from the error; e.g. `error["code"]`.

#### Properties renamed

`description` was renamed to `localizedDescription`, as `ManagementError` now conforms to `CustomStringConvertible`.

### `WebAuthError` struct

All the former enum cases are now static properties, so to switch over them you will need to add a `default` clause.

##### Before

```swift
switch error {
    case .userCancelled: handleError(error)
    // ...
}
```

##### After

```swift
switch error {
    case .userCancelled: handleError(error)
    // ...
    default: // handle unknown errors, e.g. errors added in future versions
}
```

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

- `.malformedInvitationURL`, for when the invitation URL is missing the `organization` and/or the `invitation` query parameters.
- `.noAuthorizationCode`, for when the callback URL is missing the `code` query parameter.
- `.idTokenValidationFailed`, for when the ID Token validation performed after Web Auth login fails.
- `.other`, for when a different `Error` happens. That error can be acessed via the `cause: Error?` property.

### `CredentialsManagerError` struct

All the former enum cases are now static properties, so to switch over them you will need to add a `default` clause.
As static properties cannot have asociated values, to access the `Error` for `.refreshFailed`, `.biometricsFailed`, and `.revokeFailed` use the new `cause: Error?` property.

##### Before

```swift
switch error {
    case .revokeFailed(let error): handleError(error) // handle underlying error
    // ...
}
```

##### After

```swift
switch error {
    case .revokeFailed: handleError(error.cause) // handle underlying error
    // ...
    default: // handle unknown errors, e.g. errors added in future versions
}
```

#### Error cases renamed

- `.failedRefresh` was renamed to `.refreshFailed`.
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

The Authentication API client methods will now only yield errors of type `AuthenticationError`. The underlying error (if any) is available via the `cause: Error?` property of the `AuthenticationError`.

#### Removed `parameters` parameter

The following methods lost the `parameters` parameter:

- `login(phoneNumber:code:audience:scope:)`
- `login(usernameOrEmail:password:realm:audience:scope:)`
- `loginDefaultDirectory(withUsername:password:audience:scope:)`
- `tokenExchange()`

To pass custom parameters to those (or any) method in the Authentication client, use the `parameters(_:)` method from `Request`:

```swift
Auth0
    .authentication()
    .tokenExchange() // Returns a Request
    .parameters(["key": "value"]) // 👈🏻
    .start { result in
        // ...
    }
```

#### Reordered `scope` and `audience` parameters

In the following methods the `scope` and `audience` parameters switched places, for consistency with the rest of the methods in the Authentication client:

- `login(appleAuthorizationCode:fullName:profile:audience:scope:)`
- `login(facebookSessionAccessToken:profile:audience:scope:)`

#### Changed `scope` parameter to be non-optional

In the following methods the `scope` parameter became non-optional (with a default value of `openid profile email`):

- `login(email:code:audience:scope:)`
- `login(phoneNumber:code:audience:scope:)`
- `login(usernameOrEmail:password:realm:audience:scope:)`
- `loginDefaultDirectory(withUsername:password:audience:scope:)`
- `login(appleAuthorizationCode:fullName:profile:audience:scope:)`
- `login(facebookSessionAccessToken:profile:audience:scope:)`

#### Removed `channel` parameter

The `multifactorChallenge(mfaToken:types:authenticatorId:)` method lost its `channel` parameter, which is no longer necessary.

### Management client

#### Errors

The Management API client methods will now only yield errors of type `ManagementError`. The underlying error (if any) is available via the `cause: Error?` property of the `ManagementError`.

### Web Auth

#### Errors

The Web Auth methods will now only yield errors of type `WebAuthError`. The underlying error (if any) is available via the `cause: Error?` property of the `WebAuthError`.

### Credentials Manager

#### Errors

The Credentials Manager methods will now only yield errors of type `CredentialsManagerError`. The underlying error (if any) is available via the `cause: Error?` property of the `CredentialsManagerError`.

#### Initializer

`CredentialsManager` now takes a `CredentialsStorage` protocol as it's storage argument rather than an instance of `SimpleKeychain`.

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

let credentialsManager = CredentialsManager(authentication: authentication, storage: CustomStore());
```

#### `credentials(withScope:minTTL:parameters:callback)` 

This method now yields a `Result<Credentials, CredentialsManagerError>`, which is aliased to `CredentialsManagerResult<Credentials>`.

##### Before

```swift
credentialsManager.credentials { error, credentials in
    guard error == nil, let credentials = credentials else { 
        return handleError(error) 
    }
    // credentials retrieved
```

##### After

```swift
credentialsManager.credentials { result in
    switch result {
    case .success(let credentials): // credentials retrieved
    case .failure(let error): handleError(error) 
    }
}
```

## Behavior changes

### `openid` scope enforced on Web Auth

If the scopes passed via the Web Auth method `.scope(_:)` do not include the `openid` scope, it will be added automatically.

```swift
Auth0
    .webAuth()
    .scope("profile email") // "openid profile email" will be used
    .start { result in
        // ...
    }
```

### Credentials expiration on `CredentialsManager` 

The `CredentialsManager` class no longer takes into account the ID Token expiration to determine if the credentials are still valid. The only value being considered now is the Access Token expiration.

### Thread-safety when renewing credentials with the `CredentialsManager` 

The method `credentials(withScope:minTTL:parameters:callback:)` of the `CredentialsManager` class will now execute the credentials renewal serially, to prevent race conditions when Refresh Token Rotation is enabled.
