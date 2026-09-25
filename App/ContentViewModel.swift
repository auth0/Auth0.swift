import SwiftUI
import Auth0

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var otp: String = ""
    @Published var isLoading: Bool = false
    @Published var embeddedAuthUIState: EmbeddedAuthUIState = .initial
    @Published var otpAttemptError: String?

    private let authenticationClient: Authentication
    private let embeddedAuthClient: EmbeddedAuth

    init(email: String = "",
         authenticationClient: Authentication,
         embeddedAuthClient: EmbeddedAuth? = nil) {
        self.email = email
        self.authenticationClient = authenticationClient
        self.embeddedAuthClient = embeddedAuthClient ?? Auth0.embeddedAuth().logging(enabled: true)
    }

    // MARK: Embedded auth

    func startEmbeddedFlow() async {
        isLoading = true
        embeddedAuthUIState = .initial
        do {
            _ = try await embeddedAuthClient.authorize(connection: "Username-Password-Authentication").start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func submitEmail(_ email: String) async {
        isLoading = true
        do {
            _ = try await embeddedAuthClient.identifyEmail(email).start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func triggerChallenge() async {
        isLoading = true
        do {
            _ = try await embeddedAuthClient.challengeEmail(index: 0).start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func submitOtp(_ otp: String) async {
        isLoading = true
        do {
            let credentials = try await embeddedAuthClient.verifyOtp(otp, type: .oob).start()
            embeddedAuthUIState = .success(credentials)
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    private func handle(embeddedAuthError error: EmbeddedAuthError) {
        guard error.isInsufficientAuthorization else {
            embeddedAuthUIState = .failed("[\(error.code)] \(error.info)")
            return
        }
        let next = error.nextActions.first
        let description = error.info["error_description"] as? String
        switch next {
        case .identifyEmail:
            embeddedAuthUIState = .identifyEmail
        case .challengeEmail:
            embeddedAuthUIState = .challengeEmail
        case .verifyOTP(let channel, let identifier):
            otp = ""
            if description == "invalid_identifier_or_code" || description == "invalid_code" {
                otpAttemptError = "Wrong code — try again"
            }
            embeddedAuthUIState = .verifyOTP(channel: channel, identifier: identifier)
        default:
            embeddedAuthUIState = .failed("Unhandled next action: \(String(describing: next))\nFull error: \(error.info)")
        }
    }
}

// MARK: - Embedded Auth UI State

enum EmbeddedAuthUIState {
    case initial
    case identifyEmail
    case challengeEmail
    case verifyOTP(channel: String?, identifier: String?)
    case success(Credentials)
    case failed(String)
}
