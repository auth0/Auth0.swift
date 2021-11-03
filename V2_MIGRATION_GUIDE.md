# V2 MIGRATION GUIDE

Guide to migrating from `1.x` to `2.x`

## Supported platform versions

The deployment targets for each platform have been raised to:

- iOS 12.0
- macOS 10.15
- Mac Catalyst 13.0
- tvOS 12.0
- watchOS 6.2

## Protocols removed

The following public protocols have been removed:

- `AuthResumable`
- `AuthCancelable`

Both have been subsumed in `AuthTransaction`.

## Method signatures changed

### Authentication client

The following methods lost the `parameters` parameter:

- `login(phoneNumber:code:audience:scope:)`
- `login(usernameOrEmail:password:realm:audience:scope:)`
- `loginDefaultDirectory(withUsername:password:audience:scope:)`
- `tokenExchange()`

To pass custom parameters to those (or any) method, use the `parameters()` method from `Request`:

```swift
Auth0
    .authentication()
    .tokenExchange() // Returns a Request
    .parameters(["key": "value"]) // 👈🏻
    .start { result in
        print(result)
    }
```

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
