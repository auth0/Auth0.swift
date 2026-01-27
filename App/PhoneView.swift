import SwiftUI
import Auth0

/// A view for enrolling phone number-based MFA.
///
/// This view provides an interface for users to enter their phone number,
/// initiate SMS-based multifactor authentication enrollment, and verify
/// the OTP code to complete enrollment.
///
/// ## Usage
///
/// ```swift
/// PhoneView(viewModel: phoneViewModel)
/// ```
struct PhoneView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: PhoneViewModel
    
    /// Focus state for OTP fields
    @FocusState private var focusedField: Int?
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "phone.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Phone Verification")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your phone number to receive verification codes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
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
                }
                
                // Phone Number Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.secondary)
                        
                        TextField("+1 (555) 123-4567", text: $viewModel.phoneNumber)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .disabled(viewModel.isLoading || viewModel.showOTPInput)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Text("Include country code (e.g., +1 for US)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Enroll Button
                Button {
                    Task {
                        await enrollPhone()
                    }
                } label: {
                    if viewModel.isLoading && !viewModel.showOTPInput {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Label("Send Verification Code", systemImage: "paperplane.fill")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.isLoading || !viewModel.isPhoneNumberValid || viewModel.showOTPInput)
                .padding(.top, 10)
                
                // OTP Input Section
                if viewModel.showOTPInput {
                    VStack(spacing: 15) {
                        Divider()
                            .padding(.vertical, 5)
                        
                        Text("Enter 6-digit code sent to \(viewModel.phoneNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
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
                        
                        // Verify Enrollment Button
                        Button {
                            Task {
                                await verifyEnrollment()
                            }
                        } label: {
                            if viewModel.isLoading && viewModel.showOTPInput {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Label("Verify & Complete Enrollment", systemImage: "checkmark.shield.fill")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(viewModel.isLoading || !isOTPComplete)
                        .padding(.top, 10)
                        
                        // Resend Code Button
                        Button {
                            Task {
                                viewModel.otpDigits = Array(repeating: "", count: 6)
                                await enrollPhone()
                            }
                        } label: {
                            Text("Resend Code")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Info Section
                if !viewModel.showOTPInput {
                    VStack(alignment: .leading, spacing: 10) {
                        Divider()
                            .padding(.vertical, 5)
                        
                        Text("How it works")
                            .font(.headline)
                        
                        InfoRow(icon: "1.circle.fill", text: "Enter your phone number")
                        InfoRow(icon: "2.circle.fill", text: "Receive a verification code via SMS")
                        InfoRow(icon: "3.circle.fill", text: "Enter the code to complete enrollment")
                    }
                    .padding(.top, 10)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Enrolls the phone number for MFA
    private func enrollPhone() async {
        await viewModel.enrollPhone()
        
        // Show OTP input if enrollment was successful
        if viewModel.successMessage != nil {
            withAnimation {
                viewModel.showOTPInput = true
                focusedField = 0
            }
        }
    }
    
    /// Verifies the OTP and completes enrollment
    private func verifyEnrollment() async {
        do {
            let credentials = try await viewModel.verifyOTP(otp: fullOTP)
            
            print("✓ Phone MFA Enrollment Complete")
            
            // Clear OTP fields on success
            viewModel.otpDigits = Array(repeating: "", count: 6)
            
        } catch {
            print("✗ Verification Failed: \(error)")
            // Error message is already set in viewModel
        }
    }
    
    /// Handles OTP digit input and auto-focus management
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
    
    /// Checks if all OTP digits are entered
    private var isOTPComplete: Bool {
        viewModel.otpDigits.allSatisfy { !$0.isEmpty }
    }
    
    /// Combines OTP digits into a single string
    private var fullOTP: String {
        viewModel.otpDigits.joined()
    }
}

// MARK: - Info Row Component

/// A row displaying an icon and text for informational purposes
struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

