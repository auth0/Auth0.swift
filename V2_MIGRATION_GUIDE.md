# V2 MIGRATION GUIDE

Guide to migrating from `1.x` to `2.x`

## Supported platform versions

The deployment targets for each platform have been raised to:

- iOS 12.0
- macOS 10.15
- Mac Catalyst 13.0
- tvOS 12.0
- watchOS 6.2

## Removed protocols

The following public protocols have been removed:

- `AuthResumable`
- `AuthCancelable`

Both have been subsumed in `AuthTransaction`.

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
