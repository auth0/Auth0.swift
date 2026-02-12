import SwiftUI
import Combine
import Auth0

#if os(iOS) || os(visionOS)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var currentWindow: UIWindow?
    
    var body: some View {
        VStack(spacing: 20) {
            // Web Login Button (Universal Login)
            Button {
                Task {
                    await viewModel.webLogin(presentationWindow: currentWindow)
                }
            } label: {
                Text("Login with Browser")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(viewModel.isLoading)
            
            // Logout Button
            Button {
                Task {
                    await viewModel.logout(presentationWindow: currentWindow)
                }
            } label: {
                Text("Logout")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isLoading || !viewModel.isAuthenticated)
            
            // Authentication Status
            if viewModel.isAuthenticated {
                Text("✓ Authenticated")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .task {
            // Check for existing credentials on appear
            await viewModel.checkAuthentication()
        }
        .onAppear {
            // Capture the current window for multi-window iPad support
#if os(iOS) || os(visionOS)
            currentWindow = getCurrentWindow()
#endif
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .foregroundColor(.blue)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - Window Helper

#if os(iOS) || os(visionOS)
/// Gets the current window for the view's scene
/// This is particularly useful for multi-window iPad apps
private func getCurrentWindow() -> UIWindow? {
    guard let windowScene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
        return nil
    }
    return windowScene.windows.first(where: \.isKeyWindow)
}
#endif

