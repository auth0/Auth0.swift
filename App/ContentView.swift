import SwiftUI
import Combine
import Auth0

#if !os(macOS)
   import UIKit
#else
   import AppKit
#endif


struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    #if os(macOS)
    @State private var currentWindow: WindowRepresentable?
    #else
    @Environment(\.window) private var window
    #endif

    var body: some View {
        VStack(spacing: 20) {

            Button {
                Task {
                    #if os(macOS)
                    await viewModel.webLogin(presentationWindow: currentWindow)
                    #else
                    await viewModel.webLogin(presentationWindow: window)
                    #endif
                }
            } label: {
                VStack(spacing: 4) {
                    Text("Login")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isLoading)

            Divider()
                .padding(.vertical)

            Button {
                Task {
                    #if os(macOS)
                    await viewModel.logout(presentationWindow: currentWindow)
                    #else
                    await viewModel.logout(presentationWindow: window)
                    #endif
                }
            } label: {
                Text("Logout")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isLoading || !viewModel.isAuthenticated)

            if viewModel.isAuthenticated {
                Text("✓ Authenticated")
                    .foregroundColor(.green)
                    .font(.caption)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .task {
            await viewModel.checkAuthentication()
        }
        #if os(macOS)
        .onAppear {
            // Capture the window on appear for macOS
            currentWindow = getCurrentWindow()
        }
        #endif
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

#if os(macOS)
private func getCurrentWindow() -> NSWindow? {
    if let keyWindow = NSApplication.shared.keyWindow {
        return keyWindow
    }

    if let mainWindow = NSApplication.shared.mainWindow {
        return mainWindow
    }

    return NSApplication.shared.windows.first
}

#else
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
            .background(
                WindowAccessor(window: $window)
            )
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

#endif

