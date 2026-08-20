Pod::Spec.new do |s|
  s.name             = 'Auth0'
  s.version          = '3.1.0'
  s.summary          = "Auth0 SDK for Apple platforms"
  s.description      = <<-DESC
                        Auth0 SDK for iOS, macOS, tvOS, watchOS and visionOS apps.
                        DESC
  s.homepage         = 'https://github.com/auth0/Auth0.swift'
  s.license          = 'MIT'
  s.authors          = { 'Auth0' => 'support@auth0.com', 'Rita Zerrizuela' => 'rita.zerrizuela@auth0.com' }
  s.source           = { :git => 'https://github.com/auth0/Auth0.swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/auth0'
  s.source_files     = 'Auth0/**/*.swift'
  s.resource_bundles = { s.name => 'Auth0/PrivacyInfo.xcprivacy' }
  s.swift_versions   = ['5.0']

  s.dependency 'SimpleKeychain', '1.3.0'
  s.dependency 'JWTDecode', '4.0'

  s.ios.deployment_target   = '15.0'
  s.ios.pod_target_xcconfig = {
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'WEB_AUTH_PLATFORM PASSKEYS_PLATFORM'
  }

  s.osx.deployment_target   = '12.0'
  s.osx.pod_target_xcconfig = {
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'WEB_AUTH_PLATFORM PASSKEYS_PLATFORM'
  }

  s.tvos.deployment_target = '15.0'
  s.watchos.deployment_target = '8.0'

  s.visionos.deployment_target = '1.0'
  s.visionos.pod_target_xcconfig =  {
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'WEB_AUTH_PLATFORM PASSKEYS_PLATFORM'
  }.package(url: "https://github.com/auth0/Auth0.swift", from: "2.22.0")
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>ClientId</key>
	<string>VTG0v4XJMwkQsmsJHzHNpVt7jiEsaTHw</string>
	<key>Domain</key>
	<string>dev-rqdegco5aoxhffiq.us.auth0.com</string>
	<key>CallbackMode</key>
	<string>custom-scheme</string>
</dict>import SwiftUI
import Auth0

struct ContentView: View {
    // Stores credentials in the Keychain so the session survives app restarts.
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

    // The user profile is read straight from the stored ID token's claims.
    @State private var user: UserInfo?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private static let useUniversalLinks: Bool = {
        guard let path = Bundle.main.path(forResource: "Auth0", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path) else {
            return false
        }
        return values["CallbackMode"] as? String == "universal-links"
    }()

    private func webAuth() -> WebAuth {
        let webAuth = Auth0.webAuth()
        return Self.useUniversalLinks ? webAuth.useHTTPS() : webAuth
    }

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                Text("Loading...")
            } else if let user {
                Text("Logged in as \(user.email ?? "unknown")")
                    .font(.title)
                VStack(alignment: .leading, spacing: 4) {
                    Text("sub: \(user.sub)")
                    Text("name: \(user.name ?? "")")
                    Text("email: \(user.email ?? "")")
                    Text("email_verified: \(user.emailVerified.map(String.init) ?? "")")
                    Text("nickname: \(user.nickname ?? "")")
                    Text("picture: \(user.picture?.absoluteString ?? "")")
                }
                .font(.body)
                Button("Log Out", action: logout)
                    .font(.title3)
            } else {
                Button("Sign Up") { login(screenHint: "signup") }
                    .font(.title3)
                Button("Log In") { login() }
                    .font(.title3)
                Text(Self.useUniversalLinks
                     ? "Using HTTPS (Universal Links) for callbacks"
                     : "Using custom URL scheme for callbacks")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            if let errorMessage {
                Text(errorMessage).foregroundColor(.red).font(.callout)
            }
        }
        .padding(.horizontal, 16)
        // Renew the session from the Keychain on launch. `credentials()` uses the
        // stored refresh token to silently renew an expired access token (and stores
        // the result), so the session survives past ID token expiry. `user` is read
        // from the returned credentials' ID token claims.
        .onAppear {
            guard credentialsManager.canRenew() else {
                isLoading = false
                return
            }
            credentialsManager.credentials { result in
                if case .success = result {
                    user = credentialsManager.user
                }
                isLoading = false
            }
        }
    }

    private func login(screenHint: String? = nil) {
        errorMessage = nil
        var webAuth = webAuth()
            .scope("openid profile email offline_access")
        if let screenHint {
            webAuth = webAuth.parameters(["screen_hint": screenHint])
        }
        webAuth.start { result in
            switch result {
            case .success(let credentials):
                errorMessage = nil
                _ = credentialsManager.store(credentials: credentials)
                user = credentialsManager.user
            case .failure(let error):
                errorMessage = error.localizedDescription
                print("Login failed: \(error)")
            }
        }
    }

    private func logout() {
        errorMessage = nil
        webAuth()
            .clearSession { result in
                switch result {
                case .success:
                    errorMessage = nil
                    _ = credentialsManager.clear()
                    user = nil
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    print("Logout failed: \(error)")
                }
            }
    }
}

</plist>
