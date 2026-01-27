import SwiftUI
import Auth0

/// A view for handling push notification-based MFA challenges.
///
/// This view provides an interface for users to approve or reject
/// push notification authentication requests, with OTP verification support.
///
/// ## Usage
///
/// ```swift
/// PushChallengeView(viewModel: pushChallengeViewModel)
/// ```
struct PushChallengeView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: PushChallengeViewModel
    
    /// Focus state for OTP fields
    @FocusState private var focusedField: Int?
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Push Notification Challenge")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Approve or reject this authentication request")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Success Message
                if let successMessage = viewModel.successMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(successMessage)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 15) {
                    // Approve Button
                    Button {
                        Task {
                            await viewModel.approveChallenge()
                        }
                    } label: {
                        if viewModel.isLoading && viewModel.lastAction == .approve {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Label("Approve", systemImage: "checkmark.circle.fill")
                        }
                    }
                    .buttonStyle(ApproveButtonStyle())
                    .disabled(viewModel.isLoading)
                    
                    // OTP Input Section
                    VStack(spacing: 15) {
                        Divider()
                            .padding(.vertical, 5)
                        
                        Text("Enter 6-digit verification code")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // OTP TextField Grid
                        HStack(spacing: 10) {
                            ForEach(0..<6, id: \.self) { index in
                                OTPTextField(
                                    text: $viewModel.otpDigits[index],
                                    focusedField: $focusedField,
                                    index: index,
                                    onTextChange: { handleOTPChange(at: index) }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.vertical, 5)
                    }
                    
                    // Reject Button with OTP
                    Button {
                        Task {
                            await viewModel.rejectChallenge()
                        }
                    } label: {
                        if viewModel.isLoading && viewModel.lastAction == .reject {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Label("Reject with Code", systemImage: "xmark.circle.fill")
                        }
                    }
                    .buttonStyle(RejectButtonStyle())
                    .disabled(viewModel.isLoading || !viewModel.isOTPComplete)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Handles OTP digit input and auto-focus management.
    ///
    /// - Parameter index: The index of the changed text field.
    private func handleOTPChange(at index: Int) {
        // Move to next field if current is filled
        if !viewModel.otpDigits[index].isEmpty && index < 5 {
            focusedField = index + 1
        }
        
        // Limit to single digit
        if viewModel.otpDigits[index].count > 1 {
            viewModel.otpDigits[index] = String(viewModel.otpDigits[index].prefix(1))
        }
    }
}

// MARK: - OTP TextField Component

/// A single OTP digit text field with auto-focus management.
// MARK: - Button Styles

/// Button style for approval actions
struct ApproveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

/// Button style for rejection actions
struct RejectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

