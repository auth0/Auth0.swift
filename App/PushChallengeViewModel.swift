import SwiftUI
import Auth0

/// ViewModel for managing push notification MFA challenges.
@MainActor
final class PushChallengeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var lastAction: ChallengeAction?
    @Published var otpDigits: [String] = Array(repeating: "", count: 6)

    /// Checks if all OTP digits are entered.
    var isOTPComplete: Bool {
       otpDigits.allSatisfy { !$0.isEmpty }
    }
    
    /// Combines OTP digits into a single string.
    var fullOTP: String {
        otpDigits.joined()
    }
    // MARK: - Private Properties
    
    private let mfaClient = Auth0.mfa()
    private let mfaToken: String
    private let authenticatorId: String
    private var mfaChallenge: MFAChallenge?
    
    // MARK: - Initialization
    
    init(mfaToken: String, authenticatorId: String) {
        self.mfaToken = mfaToken
        self.authenticatorId = authenticatorId
    }
    
    // MARK: - Challenge Actions
    
    func approveChallenge() async {
        
        lastAction = .approve
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            let credentials = try await mfaClient.verify(oobCode: mfaChallenge?.oobCode ?? nil, bindingCode: nil, mfaToken: mfaToken)
                print("recovery code challenged successfully \(credentials.accessToken)")

            successMessage = "Authentication challenged successfully"
        } catch let error as AuthenticationError {
            errorMessage = "Approval failed: \(error.localizedDescription)"
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func verifyRecoveryCode() async {
        lastAction = .approve
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
                let credentials = try await mfaClient.verify(recoveryCode: "8UUGJES6FYJB8MYJDWSB7BFE", mfaToken: mfaToken)
                    .start()
                print("recovery code challenged successfully \(credentials.accessToken)")

            successMessage = "Authentication challenged successfully"
        } catch let error as AuthenticationError {
            errorMessage = "Approval failed: \(error.localizedDescription)"
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func rejectChallenge() async {
        lastAction = .reject
        isLoading = true
        errorMessage = nil
        successMessage = nil
//        if let mfaChallenge {
            do {
                // Reject the authentication request
                let credentials = try await mfaClient
                    .verify(otp: fullOTP, mfaToken: mfaToken)
                   // .verify(oobCode: mfaChallenge.oobCode, bindingCode: fullOTP, mfaToken: mfaToken)
                    .start()
                successMessage = "Authentication request verified"
                print("✓ Push challenge verified \(credentials.accessToken)")
            } catch let error as AuthenticationError {
                errorMessage = "Rejection failed: \(error.localizedDescription)"
            } catch {
                errorMessage = "Unexpected error: \(error.localizedDescription)"
            }
            isLoading = false
//        }
    }
    
    enum ChallengeAction {
        case approve
        case reject
    }
}
