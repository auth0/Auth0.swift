import SwiftUI
import Auth0

// MARK: - View Model

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

    // MARK: - Discovery

    func discoverOptions() async {
        isLoading = true
        do {
            let result = try await embeddedAuthClient.discover().start()
            embeddedAuthUIState = .discovered(result.options)
        } catch let error as EmbeddedAuthError {
            embeddedAuthUIState = .failed("[\(error.code)] \(error.debugDescription)")
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Embedded auth

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

    func triggerChallenge(index: Int) async {
        isLoading = true
        do {
            _ = try await embeddedAuthClient.challengeEmail(index: index).start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func submitOtp(_ otp: String, channel: OtpChannel) async {
        isLoading = true
        let otpType: OtpType = channel == .totp ? .totp : .oob
        do {
            let credentials = try await embeddedAuthClient.verifyOtp(otp, type: otpType).start()
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
            embeddedAuthUIState = .failed("[\(error.code)] \(error.debugDescription)")
            return
        }
        for action in error.nextActions {
            switch action {
            case .identifyEmail:
                embeddedAuthUIState = .identifyEmail
                return
            case .challengeEmail(let index, let identifier):
                embeddedAuthUIState = .challengeEmail(index: index, identifier: identifier)
                return
            case .verifyOTP(let channel, let identifier):
                otp = ""
                otpAttemptError = error.isInvalidCode ? "Wrong code — try again" : nil
                embeddedAuthUIState = .verifyOTP(channel: channel, identifier: identifier)
                return
            default:
                break
            }
        }
        embeddedAuthUIState = .failed("[\(error.code)] \(error.debugDescription)")
    }
}

// MARK: - Embedded Auth UI State

enum EmbeddedAuthUIState {
    case initial
    case discovered([LoginOption])
    case identifyEmail
    case challengeEmail(index: Int, identifier: String)
    case verifyOTP(channel: OtpChannel, identifier: String?)
    case success(Credentials)
    case failed(String)
}
