import SwiftUI
import CoreImage.CIFilterBuiltins

/// A view that renders a QR code and handles OTP enrollment for MFA.
///
/// This view generates a QR code image from the provided string value and provides
/// an interface for entering and verifying the TOTP code to complete MFA enrollment.
///
/// ## Usage
///
/// ```swift
/// QRView(viewModel: qrViewModel)
///     .frame(width: 300, height: 400)
/// ```
struct QRView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: QRViewModel
    
    /// The error correction level for the QR code.
    var correctionLevel: ErrorCorrectionLevel = .medium

    
    /// Focus state for OTP fields
    @FocusState private var focusedField: Int?
    
    /// The context for generating QR codes.
    private let context = CIContext()
    
    /// The QR code generator filter.
    private let filter = CIFilter.qrCodeGenerator()
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // QR Code Section
                if viewModel.isLoading {
                    ProgressView("Loading QR Code...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if let value = viewModel.qrCodeValue {
                    VStack(spacing: 15) {
                        Text("Scan QR Code")
                            .font(.headline)
                        
                        // QR Code Image
                        if let qrImage = generateQRCode(value: value) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 250, height: 250)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 250, height: 250)
                                .cornerRadius(10)
                                .overlay(
                                    Text("Unable to generate QR code")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                )
                        }
                        
                        // Secret Key (Manual Entry)
                        if let secretKey = viewModel.secretKey {
                            VStack(spacing: 5) {
                                Text("Or enter this key manually:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(secretKey)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(5)
                            }
                        }
                        
                        // Show OTP Button
                        if !viewModel.showOTPInput {
                            Button {
                                withAnimation {
                                    viewModel.showOTPInput = true
                                    focusedField = 0
                                }
                            } label: {
                                Label("Enter Verification Code", systemImage: "key.fill")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.top, 10)
                        }
                    }
                }
                
                // OTP Input Section
                if viewModel.showOTPInput {
                    VStack(spacing: 15) {
                        Divider()
                            .padding(.vertical, 5)
                        
                        Text("Enter 6-digit code from your authenticator app")
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
                        
                        // Enroll Button
                        Button {
                            Task {
                                await viewModel.enrollWithOTP()
                            }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Label("Verify & Enroll", systemImage: "checkmark.shield.fill")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(viewModel.isLoading || !viewModel.isOTPComplete)
                        
                        // Recovery Code Display
                        if let recoveryCode = viewModel.recoveryCode {
                            VStack(spacing: 10) {
                                Divider()
                                    .padding(.vertical, 5)
                                
                                Text("⚠️ Save Your Recovery Code")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                Text(recoveryCode)
                                    .font(.system(.title3, design: .monospaced))
                                    .fontWeight(.bold)
                                    .padding()
                                    .background(Color(.systemYellow).opacity(0.2))
                                    .cornerRadius(10)
                                
                                Text("Store this code in a safe place. You'll need it if you lose access to your authenticator.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 10)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                await viewModel.fetchQRData()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Generates a QR code image from the string value.
    ///
    /// - Parameter value: The string to encode in the QR code.
    /// - Returns: A `UIImage` containing the QR code, or `nil` if generation fails.
    private func generateQRCode(value: String) -> UIImage? {
        guard let data = value.data(using: .utf8) else {
            return nil
        }
        
        filter.message = data
        filter.correctionLevel = correctionLevel.rawValue
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        // Scale up the QR code for better quality
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
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

    // MARK: - Error Correction Level
    
    /// QR code error correction levels.
    enum ErrorCorrectionLevel: String {
        case low = "L"
        case medium = "M"
        case quartile = "Q"
        case high = "H"
    }
}

// MARK: - OTP TextField Component

/// A single OTP digit text field with auto-focus management.
struct OTPTextField: View {
    @Binding var text: String
    @FocusState.Binding var focusedField: Int?
    let index: Int
    let onTextChange: () -> Void
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 24, weight: .semibold))
            .frame(width: 45, height: 55)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(focusedField == index ? Color.blue : Color.clear, lineWidth: 2)
            )
            .focused($focusedField, equals: index)
            .onChange(of: text) { _ in
                onTextChange()
            }
            .onTapGesture {
                focusedField = index
            }
    }
}

// MARK: - Preview

#Preview {
    QRView(viewModel: QRViewModel(mfaToken: "test-token", type: "otp"))
}
