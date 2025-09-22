import SwiftUI
import Auth0

@main
struct AppAuth0App: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewModel(credentialsManager: CredentialsManager(authentication: Auth0.authentication())))
        }
    }
}
