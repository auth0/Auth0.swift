### Web Auth configuration

The following are some of the available Web Auth configuration options. Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/webauth/#topics) for the full list.

> [!IMPORTANT]
> Each configuration method returns a **new copy** of the `WebAuth` instance — it does not modify the original. Always use method chaining, or reassign the return value when configuring conditionally.
>
> The following pattern does **not** work — `audience` is called but its return value is discarded, so it is never applied:
>
> ```swift
> // ⚠️ Does not work
> var webAuth = Auth0.webAuth().scope("openid")
> webAuth.audience("https://api.example.com") // return value discarded — has no effect
> webAuth.start { result in ... }
> ```
>
> Instead, either chain all options in a single expression:
>
> ```swift
> // ✅ Recommended — chain everything
> Auth0
>     .webAuth()
>     .scope("openid")
>     .audience("https://api.example.com")
>     .start { result in ... }
> ```
>
> Or reassign the return value when you need to configure conditionally:
>
> ```swift
> // ✅ Conditional configuration — reassign the return value
> var webAuth = Auth0.webAuth().scope("openid")
> webAuth = webAuth.audience("https://api.example.com")
> webAuth.start { result in ... }
> ```

#### Use any Auth0 connection

Specify an Auth0 connection to directly open that identity provider's login page, skipping the [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login) page itself. The connection must first be enabled for your Auth0 application in the [Dashboard](https://manage.auth0.com/#/applications/).

```swift
Auth0
    .webAuth()
    .connection("github") // Show the GitHub login page
    // ...
```

#### Add an audience value

Specify an [audience](https://auth0.com/docs/secure/tokens/access-tokens/get-access-tokens#control-access-token-audience) to obtain an access token that can be used to make authenticated requests to a backend. The audience value is the **API Identifier** of your [Auth0 API](https://auth0.com/docs/get-started/apis), for example `https://example.com/api`.

```swift
Auth0
    .webAuth()
    .audience("YOUR_AUTH0_API_IDENTIFIER")
    // ...
```

#### Add a scope value

Specify a [scope](https://auth0.com/docs/get-started/apis/scopes) to request permission to access protected resources, like the user profile. The default scope value is `openid profile email offline_access`. Regardless of the scope value specified, `openid` is always included.

```swift
Auth0
    .webAuth()
    .scope("openid profile email read:todos")
    // ...
```

Use `connectionScope()` to configure a scope value for an Auth0 connection.

```swift
Auth0
    .webAuth()
    .connection("github")
    .connectionScope("public_repo read:user")
    // ...
```

#### Get a refresh token

The default scope already includes `offline_access`, so a [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens) is requested automatically. If you are specifying a custom scope, include `offline_access` explicitly:

```swift
Auth0
    .webAuth()
    .scope("openid profile email offline_access read:todos")
    // ...
```

To opt out of refresh tokens, specify a scope without `offline_access`:

```swift
Auth0
    .webAuth()
    .scope("openid profile email")
    // ...
```

> [!IMPORTANT]
> Make sure that your Auth0 application has the **refresh token** [grant enabled](https://auth0.com/docs/get-started/applications/update-grant-types). If you are also specifying an audience value, make sure that the corresponding Auth0 API has the **Allow Offline Access** [setting enabled](https://auth0.com/docs/get-started/apis/api-settings#access-settings).

#### Use a custom `URLSession` instance

You can specify a custom `URLSession` instance for more advanced networking configuration, such as customizing timeout values.

```swift
Auth0
    .webAuth(session: customURLSession)
    // ...
```

> [!NOTE]
> This custom `URLSession` instance will be used when communicating with the Auth0 Authentication API, not when opening the [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login) page.

#### Specify a presentation window

When building apps that support multiple windows (such as iPad apps with Split View or Stage Manager, or macOS apps with multiple windows), you can specify which window should present the authentication UI using the `presentationWindow()` method.

<details>
  <summary>Using the UIKit app lifecycle</summary>

**iOS / iPadOS:**

```swift
guard let window = view.window else { return }

Auth0
    .webAuth()
    .presentationWindow(window) // Pass the UIWindow
    .start { result in
        // ...
    }
```

**macOS:**

```swift
guard let window = view.window else { return }

Auth0
    .webAuth()
    .presentationWindow(window) // Pass the NSWindow
    .start { result in
        // ...
    }
```

</details>

<details>
  <summary>Using the SwiftUI app lifecycle</summary>

**iOS / iPadOS:**

```swift
import SwiftUI
import Auth0

struct ContentView: View {
    @Environment(\.window) private var window // Custom environment key

    var body: some View {
        Button("Login") {
            Task {
                var webAuth = Auth0.webAuth()

                if let window = window {
                    webAuth = webAuth.presentationWindow(window)
                }

                let credentials = try await webAuth.start()
                // Handle credentials...
            }
        }
    }
}

// MARK: - Window Environment Setup

@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withWindowReader() // Enable window tracking
        }
    }
}

// Window tracking infrastructure
private struct WindowKey: EnvironmentKey {
    static let defaultValue: UIWindow? = nil
}

extension EnvironmentValues {
    var window: UIWindow? {
        get { self[WindowKey.self] }
        set { self[WindowKey.self] = newValue }
    }
}

struct WindowReaderModifier: ViewModifier {
    @State private var window: UIWindow?

    func body(content: Content) -> some View {
        content
            .environment(\.window, window)
            .background(WindowAccessor(window: $window))
    }
}

struct WindowAccessor: UIViewRepresentable {
    @Binding var window: UIWindow?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            self.window = uiView.window
        }
    }
}

extension View {
    func withWindowReader() -> some View {
        self.modifier(WindowReaderModifier())
    }
}
```

**macOS:**

```swift
import SwiftUI
import Auth0

struct ContentView: View {
    @State private var currentWindow: NSWindow?

    var body: some View {
        Button("Login") {
            Task {
                var webAuth = Auth0.webAuth()

                if let window = currentWindow {
                    webAuth = webAuth.presentationWindow(window)
                }

                let credentials = try await webAuth.start()
                // Handle credentials...
            }
        }
        .onAppear {
            currentWindow = getCurrentWindow()
        }
    }

    private func getCurrentWindow() -> NSWindow? {
        if let keyWindow = NSApplication.shared.keyWindow {
            return keyWindow
        }
        if let mainWindow = NSApplication.shared.mainWindow {
            return mainWindow
        }
        return NSApplication.shared.windows.first
    }
}
```

</details>

You can also specify a presentation window when using the `SFSafariViewController` or `WKWebView` providers:

```swift
// SFSafariViewController
Auth0
    .webAuth()
    .provider(WebAuthentication.safariProvider(presentationWindow: window))
    // ...

// WKWebView
Auth0
    .webAuth()
    .provider(WebAuthentication.webViewProvider(presentationWindow: window))
    // ...
```

> [!NOTE]
> If you don't specify a presentation window, Auth0.swift will automatically use the foreground active scene's key window for multi-window iPad apps.

#### Use `SFSafariViewController` instead of `ASWebAuthenticationSession`

You can use the built-in `SFSafariViewController` Web Auth provider to open the [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login) page.

```swift
Auth0
    .webAuth()
    .provider(WebAuthentication.safariProvider()) // Use SFSafariViewController
    .start { result in
        // ...
    }
```

> [!TIP]
> See [`ASWebAuthenticationSession` vs `SFSafariViewController` (iOS)](https://auth0.github.io/Auth0.swift/documentation/auth0/useragents) to help determine which option best suits your use case, depending on your requirements.

> [!NOTE]
> `SFSafariViewController` does not support using Universal Links as callback URLs.

The `SFSafariViewController` Web Auth provider requires an additional bit of setup. Unlike `ASWebAuthenticationSession`, `SFSafariViewController` will not automatically capture the callback URL when Auth0 redirects back to your app, so it is necessary to manually resume the Web Auth operation.

##### 1. Configure a custom URL scheme

In Xcode, go to the **Info** tab of your app target settings. In the **URL Types** section, click the **＋** button to add a new entry. There, enter `auth0` into the **Identifier** field and `$(PRODUCT_BUNDLE_IDENTIFIER)` into the **URL Schemes** field.

![Screenshot of the URL Types section inside the app target settings](https://user-images.githubusercontent.com/5055789/198689930-15f12179-15df-437e-ba50-dec26dbfb21f.png)

This registers your bundle identifier as a custom URL scheme, so the callback URL can reach your app.

##### 2. Capture the callback URL

<details>
  <summary>Using the UIKit app lifecycle</summary>

```swift
// AppDelegate.swift

func application(_ app: UIApplication,
                 open url: URL,
                 options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
    return WebAuthentication.resume(with: url)
}
```
</details>

<details>
  <summary>Using the UIKit app lifecycle with Scenes</summary>

```swift
// SceneDelegate.swift

func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    WebAuthentication.resume(with: url)
}
```
</details>

<details>
  <summary>Using the SwiftUI app lifecycle</summary>

```swift
SomeView()
    .onOpenURL { url in
        WebAuthentication.resume(with: url)
    }
```
</details>

##### Logout

`SFSafariViewController` should only be used for login. According to its docs, `SFSafariViewController` must be used "to visibly present information to users":

![Screenshot of SFSafariViewController's documentation](https://github.com/user-attachments/assets/98de5937-3ca4-4779-9e3c-725d8b628870)

This is the case for login, but not for logout. Instead of calling `logout()`, you can delete the stored credentials –using the Credentials Manager's `clear()` method– and use `"prompt": "login"` to force the login page even if the session cookie is still present. Since the cookies stored by `SFSafariViewController` are scoped to your app, this should not pose an issue.

```swift
Auth0
    .webAuth()
    .provider(WebAuthentication.safariProvider())
    .parameters(["prompt": "login"])
    .start { result in
        // ...
    }
```

#### Use `WKWebView` instead of `ASWebAuthenticationSession`

You can also use the built-in `WKWebView` Web Auth provider to open the [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login) page. Unlike `SFSafariViewController`, `WKWebView` supports using Universal Links as callback URLs.

```swift
Auth0
    .webAuth()
    .provider(WebAuthentication.webViewProvider()) // Use WKWebView
    .start { result in
        // ...
    }
```

> [!NOTE]
> To use Universal Login's biometrics and passkeys with `WKWebView`, you must [set up an associated domain](https://github.com/auth0/Auth0.swift#configure-an-associated-domain).

> [!WARNING]
> The use of `WKWebView` for performing web-based authentication [is not recommended](https://auth0.com/blog/oauth-2-best-practices-for-native-apps), and some social identity providers –such as Google– do not support it.
