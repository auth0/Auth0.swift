import SwiftUI

@main
struct Auth0DemoApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            ContentView()
            #else
            ContentView()
                .withWindowReader()
            #endif
        }
    }
}
