import SwiftUI
import Auth0
import Combine

/// ViewModel for managing phone number-based MFA enrollment.
///
/// This view model handles phone number enrollment and verification for
/// SMS-based multifactor authentication using the Auth0 Authentication API.
///
/// ## Usage
///
/// ```swift
/// @StateObject private var viewModel = PhoneViewModel(mfaToken: token)
///
/// // In your view
/// Button("Enroll") {
///     Task {
///         await viewModel.enrollPhone()
///     }
/// }
/// ```
@MainActor
final class PhoneViewModel: ObservableObject {
    
    /// State for showing OTP input fields
    @Published var showOTPInput = false
    
    /// State for OTP digits (6 individual fields)
    @Published var otpDigits: [String] = Array(repeating: "", count: 6)
    // MARK: - Published Properties

    /// The phone number input from the user
    @Published var phoneNumber: String = ""
    
    /// Loading state for async operations
    @Published var isLoading: Bool = false
    
    /// Error message for display
    @Published var errorMessage: String?
    
    /// Success message after enrollment
    @Published var successMessage: String?
    
    // MARK: - Private Properties
    private var phoneChallenge: MFAEnrollmentChallenge? 
    private let mfaClient = Auth0.mfa()
    private let mfaToken: String
    
    // MARK: - Initialization
    
    /// Creates a new PhoneViewModel instance.
    ///
    /// - Parameter mfaToken: The MFA token from the authentication error payload.
    init(mfaToken: String) {
        self.mfaToken = mfaToken
    }
    
    // MARK: - Computed Properties
    
    /// Validates the phone number format.
    ///
    /// - Returns: `true` if the phone number has at least 10 digits and starts with '+'.
    var isPhoneNumberValid: Bool {
        let cleanedNumber = phoneNumber.filter { $0.isNumber || $0 == "+" }
        return cleanedNumber.count >= 10 && cleanedNumber.hasPrefix("+")
    }
    
    // MARK: - Phone Enrollment
    
    /// Enrolls the phone number for MFA using SMS.
    ///
    /// This method initiates the phone enrollment flow by sending a verification
    /// code to the provided phone number via SMS.
    ///
    /// ## Example
    ///
    /// ```swift
    /// viewModel.phoneNumber = "+15551234567"
    /// await viewModel.enrollPhone()
    /// ```
    ///
    /// - Throws: `AuthenticationError` if enrollment fails.
    func enrollPhone() async {
        guard !mfaToken.isEmpty else {
            errorMessage = "MFA token is required"
            return
        }
        
        guard isPhoneNumberValid else {
            errorMessage = "Please enter a valid phone number with country code (e.g., +1)"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
//            // Initiate phone enrollment challenge
            phoneChallenge = try await mfaClient
                .enroll(mfaToken: mfaToken, phoneNumber: phoneNumber)
                .start()
            
            successMessage = "Verification code sent to \(phoneNumber)"
            print("✓ Phone enrollment initiated successfully")
            
        } catch let error as AuthenticationError {
            errorMessage = "Enrollment failed: \(error.localizedDescription)"
            print("✗ Phone enrollment error: \(error)")
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Verifies the OTP code sent via SMS.
    ///
    /// - Parameters:
    ///   - otp: The one-time password received via SMS.
    ///   - bindingCode: Optional binding code for additional security.
    ///
    /// - Returns: Credentials on successful verification.
    /// - Throws: `AuthenticationError` if verification fails.
    func verifyOTP(otp: String) async {
        guard !otp.isEmpty else {
            errorMessage = "OTP code is required"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        if let phoneChallenge {
            do {
                _ = try await mfaClient
                    .verify(oobCode: phoneChallenge.oobCode, bindingCode: otp, mfaToken: mfaToken)
                    .start()
                
                successMessage = "Phone enrollment completed successfully"
                print("✓ Phone MFA enrollment verified")
                
            } catch let error as AuthenticationError {
                errorMessage = "Verification failed: \(error.localizedDescription)"
            } catch {
                errorMessage = "Unexpected error: \(error.localizedDescription)"
            }
        }
    }
    
    /// Clears all state and resets the view model.
    func clear() {
        phoneNumber = ""
        errorMessage = nil
        successMessage = nil
        isLoading = false
    }
}
