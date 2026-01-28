import SwiftUI
import Combine
import Auth0

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                        
                        // Web Login Button (Universal Login)
                        Button {
                            Task {
                                await viewModel.webLogin()
                            }
                        } label: {
                            Text("Login with Browser")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(viewModel.isLoading)
                        
                        // Logout Button
                        Button {
                            Task {
                                await viewModel.logout()
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
            }
        }
        .task {
            // Check for existing credentials on appear
            await viewModel.checkAuthentication()
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

