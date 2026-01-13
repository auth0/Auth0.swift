import SwiftUI
import Combine
import Auth0

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // List Section
                    VStack(alignment: .leading, spacing: 10) {
                        
                        if let enrollmentTypes = viewModel.enrollmentTypes {
                            Text("Enrollments")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(enrollmentTypes, id: \.self) { enrollmentType in
                                NavigationLink {
                                    if enrollmentType.type == "otp" || enrollmentType.type == "push-notification" {
                                        QRView(viewModel: QRViewModel(mfaToken: viewModel.mfaToken, type: enrollmentType.type))
                                    } else if enrollmentType.type == "phone" {
                                        PhoneView(viewModel: PhoneViewModel(mfaToken: viewModel.mfaToken))
                                    } else if enrollmentType.type == "recovery-code" {
                                        PushChallengeView(viewModel: PushChallengeViewModel(mfaToken: viewModel.mfaToken, authenticatorId: ""))
                                    }
                                } label: {
                                    Text(enrollmentType.type)
                                }
                            }
                        }
                        
                        if let authenticators = viewModel.authenticators {
                            Text("Authenticators")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(authenticators, id: \.self) { authenticator in
                                NavigationLink {
                                    if authenticator.type == "oob" {
                                        PushChallengeView(viewModel: PushChallengeViewModel(mfaToken: viewModel.mfaToken, authenticatorId: authenticator.id))
                                    } else if authenticator.type == "otp" {
                                        PushChallengeView(viewModel: PushChallengeViewModel(mfaToken: viewModel.mfaToken, authenticatorId: authenticator.id))
                                    } else {
                                        PushChallengeView(viewModel: PushChallengeViewModel(mfaToken: viewModel.mfaToken, authenticatorId: authenticator.id))
                                    }
                                } label: {
                                    Text(authenticator.id)
                                }
                            }
                        }
                    }
                    
                    // Authentication Section
                    VStack(spacing: 15) {
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        // Email TextField
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disabled(viewModel.isLoading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        
                        // Password SecureField
                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.password)
                            .disabled(viewModel.isLoading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        
                        // Login Button (Direct Authentication)
                        Button {
                            Task {
                                await viewModel.login(email: viewModel.email, password: viewModel.password)
                            }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Login")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(viewModel.isLoading)
                        
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
                        
                        Button("Button 4") {
                            // Action
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button("Button 5") {
                            // Action
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.vertical)
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

