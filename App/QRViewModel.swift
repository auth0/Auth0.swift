import SwiftUI
import Auth0
import Combine

/// ViewModel for managing QR code data for MFA enrollment.
///
/// This view model handles fetching QR code data from Auth0 for MFA enrollment,
/// specifically for TOTP (Time-based One-Time Password) enrollment.
///
/// ## Usage
///
/// ```swift
/// @StateObject private var viewModel = QRViewModel()
///
/// // In your view
/// Button("Enroll MFA") {
///     Task {
///         await viewModel.fetchQRData(mfaToken: token)
///     }
/// }
/// ```
@MainActor
final class QRViewModel: ObservableObject {
    /// State for showing OTP input fields
    @Published var showOTPInput = false
    
    /// State for OTP digits (6 individual fields)
    @Published var otpDigits: [String] = Array(repeating: "", count: 6)
    var isOTPComplete: Bool {
        otpDigits.allSatisfy { !$0.isEmpty }
    }

    /// Combines OTP digits into a single string.
    private var fullOTP: String {
        otpDigits.joined()
    }
    // MARK: - Published Properties
    
    /// The QR code URI string (e.g., otpauth://totp/...)
    @Published var qrCodeValue: String?
    
    /// The secret key for manual entry (if QR scanning fails)
    @Published var secretKey: String?
    
    /// The recovery code provided after enrollment
    @Published var recoveryCode: String?
    
    /// Loading state for async operations
    @Published var isLoading: Bool = false
    
    /// Error message for display
    @Published var errorMessage: String?
    private var pushEnrollmentChallenge: PushMFAEnrollmentChallenge?
    private var otpEnrollmentChallenge: OTPMFAEnrollmentChallenge?
    
    // MARK: - Private Properties
    
    private let mfaClient = Auth0.mfa()
    private let mfaToken: String
    private let type: String
    
    init(mfaToken: String,
         type: String) {
        self.mfaToken = mfaToken
        self.type = type
    }
    
    // MARK: - MFA Enrollment
    
    /// Fetches QR code data for TOTP MFA enrollment.
    ///
    /// This method initiates MFA enrollment and retrieves the QR code URI
    /// that can be scanned by authenticator apps like Google Authenticator or Authy.
    ///
    /// - Parameter mfaToken: The MFA token received from the authentication error payload.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // After catching AuthenticationError with isMultifactorRequired
    /// if let mfaToken = error.mfaRequiredErrorPayload?.mfaToken {
    ///     await viewModel.fetchQRData(mfaToken: mfaToken)
    /// }
    /// ```
    func fetchQRData() async {
        guard !mfaToken.isEmpty else {
            errorMessage = "MFA token is required"
            return
        }
        
        isLoading = true
        errorMessage = nil
        qrCodeValue = nil
        secretKey = nil
        recoveryCode = nil
        
        do {
            if type == "otp" {
                // Start MFA enrollment for TOTP
                self.otpEnrollmentChallenge = try await mfaClient
                    .enroll(mfaToken: mfaToken)
                    .start()

                // Extract QR code data
                qrCodeValue = otpEnrollmentChallenge?.barcodeUri
            } else if type == "push-notification" {
                // Start MFA enrollment for TOTP
                self.pushEnrollmentChallenge = try await mfaClient
                    .enroll(mfaToken: mfaToken)
                    .start()

                // Extract QR code data
                qrCodeValue = pushEnrollmentChallenge?.barcodeUri
            }
            
            print("QR Code URI: \(qrCodeValue ?? "N/A")")
            print("Secret Key: \(secretKey ?? "N/A")")
            
        } catch let error as AuthenticationError {
            errorMessage = "MFA enrollment failed: \(error.localizedDescription)"
            print("MFA enrollment error: \(error)")
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    //
    //    /// Verifies the TOTP code entered by the user to complete enrollment.
    //    ///
    //    /// - Parameters:
    //    ///   - mfaToken: The MFA token from the enrollment flow.
    //    ///   - otp: The one-time password entered by the user.
    //    ///   - bindingCode: Optional binding code for additional security.
    //    ///
    //    /// - Returns: Credentials on successful verification.
    //    func verifyOTP(mfaToken: String, otp: String, bindingCode: String? = nil) async throws -> Credentials {
    //        isLoading = true
    //        errorMessage = nil
    //
    //        defer { isLoading = false }
    //
    //        do {
    //            let credentials = try await authentication
    //                .login(
    //                    withOTP: otp,
    //                    mfaToken: mfaToken,
    //                    bindingCode: bindingCode
    //                )
    //                .start()
    //
    //            print("MFA enrollment completed successfully")
    //            return credentials
    //
    //        } catch let error as AuthenticationError {
    //            errorMessage = "OTP verification failed: \(error.localizedDescription)"
    //            throw error
    //        } catch {
    //            errorMessage = "Unexpected error: \(error.localizedDescription)"
    //            throw error
    //        }
    //    }
    
    /// Clears all QR data and resets the state.
    func clear() {
        qrCodeValue = nil
        secretKey = nil
        recoveryCode = nil
        errorMessage = nil
        isLoading = false
    }
    
    
    func enrollWithOTP() async {
            guard isOTPComplete else { return }

            do {
                if type == "push-notification", let pushEnrollmentChallenge {
                    let credentials = try await mfaClient.verify(oobCode: pushEnrollmentChallenge.oobCode,
                                                                     bindingCode: nil,
                                                                     mfaToken: mfaToken)
                        .start()

                    print("✓ MFA Enrollment Successful")
                    print("Access Token: \(credentials.accessToken)")
                } else {
                    let credentials = try await mfaClient.verify(otp: fullOTP,
                                                                     mfaToken: mfaToken)
                        .start()
                    
                    print("✓ MFA Enrollment Successful")
                    print("Access Token: \(credentials.accessToken)")
                    
                    // Clear OTP fields
                    otpDigits = Array(repeating: "", count: 6)
                }
                
            } catch {
                print("✗ MFA Enrollment Failed: \(error)")
                // Error message is already set in viewModel
            }
        }
}
