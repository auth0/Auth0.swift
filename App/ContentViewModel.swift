import Combine
import SwiftUI
import Foundation
import Auth0
import CoreImage.CIFilterBuiltins
@MainActor
final class ContentViewModel: ObservableObject {
    let credentialsManager: CredentialsManager
    @Published var otpCode: String = ""
    @Published var qrCodeImage: Image?
    @Published var showOTPTextField = false
    var mfaToken: String = ""
    @Published var credentials: Credentials? = nil

    init(credentialsManager: CredentialsManager) {
        self.credentialsManager = credentialsManager
    }

    func store(credentials: Credentials) {
        _ = self.credentialsManager.store(credentials: credentials)
        _ = self.credentialsManager.store(apiCredentials: APICredentials(from: credentials), forAudience: "")
    }

    func fetchAPICredentials() {
        Task {
            do {
                let credentials = try await credentialsManager.apiCredentials(forAudience: "")
                print(credentials.accessToken)
            } catch {
                print(error)
            }
        }
    }

    func login(email: String, password: String) {
        Task {
            do {
                let credentials = try await Auth0.authentication()
                    .login(usernameOrEmail: email, password: password, realmOrConnection: "Username-Password-Authentication", audience: "https://test-nandan.com", scope: "openid email profile offline_access")
                    .start()
                await MainActor.run {
                    self.credentials = credentials
                }
                self.store(credentials: credentials)
            } catch {
                if let error = error as? AuthenticationError,
                   error.isMultifactorRequired,
                   let mfaToken = error.info["mfa_token"] as? String {
                    self.mfaToken = mfaToken
                    await self.fetchAuthenticators(mfaToken: mfaToken)
                }
            }
        }
    }

    func confirmEnrollment() {
        qrCodeImage = nil
        showOTPTextField = false
        Task {
            do {
                let credentials = try await Auth0.authentication()
                    .login(withOTP: otpCode, mfaToken: mfaToken)
                    .start()
                await MainActor.run {
                    self.credentials = credentials
                }
                self.store(credentials: credentials)
            } catch {
                print(error)
            }
        }
    }
    func fetchAuthenticators(mfaToken: String) async {
        do {
            let authenticators = try await Auth0.authentication()
                .listMFAAuthenticators(mfaToken: mfaToken)
                .start()
            if authenticators.filter { $0.type == "otp"  && $0.active == true }.isEmpty {
                let challenge = try await Auth0.authentication()
                    .enrollOTPMFA(mfaToken: mfaToken)
                    .start()
                await self.setAuthQRCodeImage(challenge: challenge)
            } else {
                showOTPTextField = true 
            }
        } catch {
            print(error)
        }
    }

    @MainActor func setAuthQRCodeImage(challenge: OTPMFAEnrollmentChallenge) async {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.correctionLevel = "H"
        filter.message = Data(challenge.barCodeURI.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                await MainActor.run {
                    qrCodeImage = Image(decorative: cgImage, scale: 1.0)            }
                }
        }
    }
}
