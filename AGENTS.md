# AI Agent Guidelines for Auth0.swift SDK

This document provides context and guidelines for AI coding assistants working with the Auth0.swift SDK codebase.

## Project Overview

**Auth0.swift** is an idiomatic Swift SDK for integrating Auth0 authentication and authorization into Apple platform applications (iOS, macOS, tvOS, watchOS). The SDK provides a comprehensive solution for:

  - **WebAuth**: Universal Login via `ASWebAuthenticationSession` (iOS 12+ / macOS 10.15+).
  - **Authentication**: Direct API client (Login, Signup, User Info, Passwordless).
  - **Management**: Management API client (Users, Patching).
  - **CredentialsManager**: Secure storage and automatic renewal of credentials.
  - **Support**: Async/Await, Combine, and legacy Callback patterns.

## Repository Structure

```text
Auth0.swift/
├── Auth0/                          # Main SDK Source
│   ├── WebAuth/                    # Web Authentication (Universal Login)
│   ├── Authentication/             # Authentication API Client
│   ├── Management/                 # Management API Client
│   ├── CredentialsManager/         # Secure Storage & Refresh Logic
│   ├── Networking/                 # Network Layer (Request/Response)
│   ├── Utils/                      # Validators, Extensions
│   └── Auth0.swift                 # Main Entry Point
├── Auth0Tests/                     # Unit Tests (XCTest + Quick/Nimble)
├── Package.swift                   # Swift Package Manager Definition
├── Auth0.podspec                   # CocoaPods Definition
├── Cartfile                        # Carthage Definition
└── README.md                       # Documentation
```

## Key Technical Decisions

### Architecture Patterns

- **Protocol-Oriented**: Heavy use of protocols to define API contracts (`Authentication`, `WebAuth`, `CredentialsStorage`).
- **Functional Options**: Used in WebAuth builder pattern (e.g., `.scope()`, `.connection()`).
- **Concurrency**:
  - **Primary**: Swift Concurrency (`async`/`await`) for modern targets.
  - **Secondary**: Combine Publishers (via `.start()` returning `AnyPublisher`).
  - **Legacy**: Result type Closures (`(Result<T, Auth0Error>) -> Void`).

### Authentication Flow

1.  **WebAuth** (Recommended):
    - Uses `ASWebAuthenticationSession` to share cookies with the system browser.
    - Handles PKCE (Proof Key for Code Exchange) automatically.
    - Support for Ephemeral Sessions (no cookies).

2.  **Authentication API**:
    - Direct HTTP calls to Auth0 Authentication endpoints.
    - Used for custom UI (Resource Owner Password) or non-interactive flows.

### Credential Management

- **CredentialsManager**: Abstraction for storing tokens.
- **Storage**: Defaults to `SimpleKeychain` (a distinct Auth0 library) for Keychain access.
- **Automatic Refresh**: Handles checking expiration and refreshing access tokens automatically when requesting credentials.

## Development Guidelines

### Code Style

- **Language**: Swift 5.7+
- **Formatting**: Adheres to SwiftLint rules (see `.swiftlint.yml`).
- **Documentation**: 100% documentation coverage required for public APIs (Triple-slash `///`).

### API Design Principles

When adding or modifying APIs, you must support the **Tri-brid Concurrency Model**:

1.  **Async/Await** (Modern):
    ```swift
    func login() async throws -> Credentials
    ```
2.  **Combine** (Reactive):
    ```swift
    func login() -> AnyPublisher<Credentials, Auth0Error>
    ```
3.  **Completion Handler** (Legacy/ObjC):
    ```swift
    func login(completion: @escaping (Result<Credentials, Auth0Error>) -> Void)
    ```

### Error Handling

- All errors must map to `Auth0Error`.
- Specific domains:
  - `AuthenticationError`: API failures.
  - `WebAuthError`: User cancellation, browser issues.
  - `ManagementError`: Management API failures.

### Testing Requirements

- **Frameworks**: XCTest, Quick, and Nimble.
- **Mocking**: Use protocol-based mocking for `URLSession` and Storage.
- **Coverage**: Ensure tests cover Success, Failure (API error), and Network Failure scenarios.

## Build & Testing Commands

```bash
# Resolve Dependencies
swift package resolve

# Build the SDK
swift build

# Run Tests
swift test

# Generate Documentation (DocC)
swift package generate-documentation
```

## Configuration Files

### Package Management

- **`Package.swift`**: Primary definition (SPM).
- **`Auth0.podspec`**: Kept in sync for CocoaPods.

### Auth0 Configuration

While the SDK can be configured in code, it defaults to reading from `Auth0.plist` (or `Info.plist` in older setups):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ClientId</key>
    <string>YOUR_CLIENT_ID</string>
    <key>Domain</key>
    <string>YOUR_DOMAIN</string>
</dict>
</plist>
```

## Dependencies

- **JWTDecode.swift**: For decoding JWTs to extract claims/expiry.
- **SimpleKeychain**: For Keychain access (iOS/macOS).
- **Quick/Nimble**: (Test Target only) Behavior-driven testing.

## Security Considerations

1.  **PKCE**: Mandatory and automatic for WebAuth.
2.  **State Validation**: Random state strings used to prevent CSRF in web flows.
3.  **Keychain**: Tokens should never be stored in `UserDefaults`; use `CredentialsManager`.
4.  **Pinned Certificates**: Supported via `URLSession` configuration if high security is required.

## Documentation

- **README.md**: Quickstart.
- **EXAMPLES.md**: (If present) or inline Code Snippets in docblocks.
- **MIGRATION.md**: Crucial when moving between major versions (e.g., v1 -> v2).

## Common Pitfalls

- **Bundle Identifier**: The callback URL in the Auth0 Dashboard must match the App's Bundle ID format (e.g., `com.example.app://YOUR_DOMAIN/ios/com.example.app/callback`).
- **Dispatcher**: UI updates must happen on `@MainActor` / Main Thread.
- **Retain Cycles**: Be careful with `self` capture in closures within `CredentialsManager`.
- **Info.plist Configuration**: Ensure `CFBundleURLTypes` is properly configured for callback URL schemes.

## AI Agent Best Practices

When assisting with this codebase:

1.  **Prioritize Async/Await**: Default to `async`/`await` syntax unless the user specifies Combine or Closures.
2.  **Type Safety**: Strictly use `Result<T, Auth0Error>` types.
3.  **Availability Checks**: Check `#available(iOS 13.0, *)` if mixing legacy code.
4.  **Platform Checks**: Be aware of API differences between `iOS` and `macOS` (e.g., `UIApplication` vs `NSApplication`).

## Example Workflows

### Web Authentication (Async/Await)

```swift
import Auth0

func login() async {
    do {
        let credentials = try await Auth0
            .webAuth()
            .scope("openid profile email")
            .start()
        print("AccessToken: \(credentials.accessToken)")
    } catch {
        print("Failed with error: \(error)")
    }
}
```

### Credentials Manager (Storage & Refresh)

```swift
let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

// Get a valid token (refreshes automatically if needed)
func fetchToken() async {
    do {
        let credentials = try await credentialsManager.credentials()
        print("Valid Access Token: \(credentials.accessToken)")
    } catch {
        // Handle login required
    }
}
```

### Direct Authentication (Login with Password)

```swift
import Auth0

func directLogin() {
    Auth0
        .authentication()
        .login(username: "email@example.com", password: "password", realm: "Username-Password-Authentication")
        .start { result in
            switch result {
            case .success(let credentials):
                print("Logged in: \(credentials)")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
}
```
