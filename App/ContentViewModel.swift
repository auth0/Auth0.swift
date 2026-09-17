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
    private let embeddedAuthClient: EmbeddedAuthClient

    init(email: String = "",
         authenticationClient: Authentication,
         embeddedAuthClient: EmbeddedAuthClient? = nil) {
        self.email = email
        self.authenticationClient = authenticationClient
        self.embeddedAuthClient = embeddedAuthClient ?? Auth0.embeddedAuthClient().logging(enabled: true)
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
            _ = try await embeddedAuthClient.challengeEmail().start()
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
            let authCode = try await embeddedAuthClient.verifyOtp(otp, type: .oob).start()
            let credentials = try await exchangeEmbeddedCode(authCode.code)
            embeddedAuthUIState = .success(credentials)
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    // Exchanges an embedded authorization code for Credentials.
    // Does NOT send redirect_uri or code_verifier — not part of the embedded flow.
    private func exchangeEmbeddedCode(_ code: String) async throws -> Credentials {
        guard let plist = Bundle.main.url(forResource: "Auth0", withExtension: "plist"),
              let values = NSDictionary(contentsOf: plist),
              let domain = values["Domain"] as? String,
              let clientId = values["ClientId"] as? String else {
            throw EmbeddedAuthError(info: ["error": "configuration_error",
                                           "error_description": "Auth0.plist missing or invalid"],
                                    statusCode: 0)
        }
        var request = URLRequest(url: URL(string: "https://\(domain)/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientId
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw EmbeddedAuthError(info: ["error": "parse_error",
                                           "error_description": "Could not parse token response"],
                                    statusCode: statusCode)
        }
        guard statusCode == 200,
              let accessToken = json["access_token"] as? String else {
            throw EmbeddedAuthError(info: json, statusCode: statusCode)
        }
        return Credentials(accessToken: accessToken,
                           tokenType: json["token_type"] as? String ?? "Bearer",
                           idToken: json["id_token"] as? String ?? "",
                           refreshToken: json["refresh_token"] as? String,
                           expiresAt: Date(timeIntervalSinceNow: json["expires_in"] as? Double ?? 3600),
                           scope: json["scope"] as? String)
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
