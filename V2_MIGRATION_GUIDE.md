# V2 MIGRATION GUIDE

Guide to migrating from `1.x` to `2.x`

## Supported platform versions

The deployment targets for each platform have been raised to:

- iOS 12.0
- macOS 10.15
- Mac Catalyst 13.0
- tvOS 12.0
- watchOS 6.2

## Supported languages

### Swift

The minimum supported Swift version is now 5.3.

### Objective-C

Auth0.swift no longer supports Objective-C.

## Supported JWT signature algorithms

ID Tokens signed with the HS256 algorithm are no longer allowed. 
This is because HS256 is a symmetric algorithm, which is not suitable for public clients like mobile apps.
The only algorithm supported now is RS256, an asymmetric algorithm.

If your app is using HS256, you'll need to switch it to RS256 in the dashboard or login will fail with an error:

**Your app's settings > Advanced settings > JSON Web Token (JWT) Signature Algorithm**

## Types removed

### Protocols

The following public protocols have been removed:

- `AuthResumable`
- `AuthCancelable`

Both have been subsumed in `AuthTransaction`.

### Classes

The following Objective-C compatibility wrappers have been removed:

- `_ObjectiveAuthenticationAPI`
- `_ObjectiveManagementAPI`
- `_ObjectiveOAuth2`

## Metods Removed

### Web Auth

Auth0.swift now only supports the [authorization code flow with PKCE](https://auth0.com/blog/oauth-2-best-practices-for-native-apps/), which is used by default. For this reason, the following methods have been removed from the Web Auth builder:

- `usingImplicitGrant()`
- `responseType(_:)`

## Errors Removed

### `WebAuthError` enum

The following cases were removed, as they are no longer necessary:

- `noNonceProvided`
- `invalidIdTokenNonce`

## Types changed

- `UserInfo` was changed from class to struct

## Type properties changed

### `Credentials` class

All the properties are no longer marked with the `@objc` attribute. Additionally, the following properties are no longer optional:

- `accessToken`
- `tokenType`
- `expiresIn`
- `idToken`

### `UserInfo` struct

All the properties are no longer marked with the `@objc` attribute.

### `NSError` extension

These properties have been removed:

- `a0_isManagementError`
- `a0_isAuthenticationError`

## Method signatures changed

### Authentication client

#### Removed `parameters` parameter

The following methods lost the `parameters` parameter:

- `login(phoneNumber:code:audience:scope:)`
- `login(usernameOrEmail:password:realm:audience:scope:)`
- `loginDefaultDirectory(withUsername:password:audience:scope:)`
- `tokenExchange()`

To pass custom parameters to those (or any) method, use the `parameters(_:)` method from `Request`:

```swift
Auth0
    .authentication()
    .tokenExchange() // Returns a Request
    .parameters(["key": "value"]) // 👈🏻
    .start { result in
        print(result)
    }
```

#### Removed `channel` parameter

The `multifactorChallenge(mfaToken:types:authenticatorId:)` method lost its `channel` parameter, which is no longer necessary.

## Behavior changes

### `openid` scope enforced on Web Auth

If the scopes passed via the Web Auth method `.scope(_:)` do not include the `openid` scope, it will be added automatically.

```swift
Auth0
    .webAuth()
    .scope("profile email") // "openid profile email" will be used
    .start { result in
        print(result)
    }
```

### Credentials expiration on `CredentialsManager` 

The `CredentialsManager` class no longer takes into account the ID Token expiration to determine if the credentials are still valid. The only value being considered now is the Access Token expiration.

## Title of change

Description of change

### Before

```swift
// Some code
```

### After

```swift
// Some code
```
