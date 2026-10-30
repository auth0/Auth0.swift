import SwiftUI
import Auth0

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel(authenticationClient: Auth0.authentication())
    #if WEB_AUTH_PLATFORM && !os(macOS)
    @Environment(\.window) private var window
    #endif

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Embedded Auth")
                    .font(.title2.bold())
                    .padding(.bottom, 4)

                switch viewModel.embeddedAuthUIState {

                case .initial:
                    Button {
                        Task { await viewModel.startEmbeddedFlow() }
                    } label: {
                        Text("Start Embedded Auth")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading)

                    #if WEB_AUTH_PLATFORM
                    Button {
                        Task {
                            #if os(macOS)
                            await viewModel.webLogin(presentationWindow: getCurrentWindow())
                            #else
                            await viewModel.webLogin(presentationWindow: window)
                            #endif
                        }
                    } label: {
                        Text("Login with Browser")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(viewModel.isLoading)
                    #endif

                case .identifyEmail:
                    TextField("Email", text: $viewModel.email)
                        #if !os(macOS)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        #endif
                        .disableAutocorrection(true)
                        #if !os(tvOS)
                        .textFieldStyle(.roundedBorder)
                        #endif
                    Button {
                        Task { await viewModel.submitEmail(viewModel.email) }
                    } label: {
                        Text("Submit Email")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading || viewModel.email.isEmpty)
                    if viewModel.canToggleIdentifier {
                        Button {
                            viewModel.toggleIdentifier()
                        } label: {
                            Text("Use phone instead")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(viewModel.isLoading)
                    }

                case .identifyPhone:
                    TextField("Phone number", text: $viewModel.phone)
                        #if !os(macOS)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        #endif
                        .disableAutocorrection(true)
                        #if !os(tvOS)
                        .textFieldStyle(.roundedBorder)
                        #endif
                    Button {
                        Task { await viewModel.submitPhone(viewModel.phone) }
                    } label: {
                        Text("Submit Phone")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading || viewModel.phone.isEmpty)
                    if viewModel.canToggleIdentifier {
                        Button {
                            viewModel.toggleIdentifier()
                        } label: {
                            Text("Use email instead")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(viewModel.isLoading)
                    }

                case .identifyUsername:
                    TextField("Username", text: $viewModel.username)
                        #if !os(macOS)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        #endif
                        .disableAutocorrection(true)
                        #if !os(tvOS)
                        .textFieldStyle(.roundedBorder)
                        #endif
                    Button {
                        Task { await viewModel.submitUsername(viewModel.username) }
                    } label: {
                        Text("Submit Username")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading || viewModel.username.isEmpty)

                case .challengeEmail(let index, let identifier):
                    Text(identifier.isEmpty ? "We'll send you a one-time code." : "We'll send a one-time code to \(identifier).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button {
                        Task { await viewModel.triggerChallenge(index: index) }
                    } label: {
                        Text("Send OTP")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading)
                    alternativeActionButtons

                case .challengePhone(let index, let identifier, let deliveryMethods):
                    Text("We'll send a code to \(identifier).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    // The server may omit the supported methods; fall back to SMS.
                    ForEach(deliveryMethods.isEmpty ? [.text] : deliveryMethods, id: \.self) { method in
                        Button {
                            Task { await viewModel.triggerPhoneChallenge(index: index, deliveryMethod: method) }
                        } label: {
                            Text(method == .voice ? "Voice" : "SMS")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(viewModel.isLoading)
                    }
                    alternativeActionButtons

                case .challengePush(let index, let name):
                    Button {
                        Task { await viewModel.triggerPushChallenge(index: index) }
                    } label: {
                        Text("Send push to \(name)")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading)
                    alternativeActionButtons

                case .pollingPush:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                    Text("Waiting for approval on your device…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button {
                        viewModel.reset()
                    } label: {
                        Text("Cancel")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                case .verifyOTP(let channel, let identifier):
                    if let identifier {
                        Text("Enter the code sent to \(identifier)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    TextField("One-time code", text: $viewModel.otp)
                        #if !os(macOS)
                        .textContentType(.oneTimeCode)
                        .keyboardType(.numberPad)
                        #endif
                        #if !os(tvOS)
                        .textFieldStyle(.roundedBorder)
                        #endif
                    if let attemptError = viewModel.attemptError {
                        Text(attemptError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Button {
                        viewModel.attemptError = nil
                        Task { await viewModel.submitOtp(viewModel.otp, channel: channel) }
                    } label: {
                        Text("Verify")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading || viewModel.otp.isEmpty)
                    alternativeActionButtons

                case .verifyPassword:
                    Text("Enter your password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    SecureField("Password", text: $viewModel.password)
                        #if !os(tvOS)
                        .textFieldStyle(.roundedBorder)
                        #endif
                    if let attemptError = viewModel.attemptError {
                        Text(attemptError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Button {
                        viewModel.attemptError = nil
                        Task { await viewModel.submitPassword(viewModel.password) }
                    } label: {
                        Text("Verify")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading || viewModel.password.isEmpty)
                    alternativeActionButtons

                case .verifyRecoveryCode:
                    Text("Enter your recovery code")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("Recovery code", text: $viewModel.recoveryCode)
                        #if !os(macOS)
                        .autocapitalization(.none)
                        #endif
                        .disableAutocorrection(true)
                        #if !os(tvOS)
                        .textFieldStyle(.roundedBorder)
                        #endif
                    if let attemptError = viewModel.attemptError {
                        Text(attemptError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Button {
                        viewModel.attemptError = nil
                        Task { await viewModel.submitRecoveryCode(viewModel.recoveryCode) }
                    } label: {
                        Text("Verify")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading || viewModel.recoveryCode.isEmpty)
                    alternativeActionButtons

                case .confirmRecoveryCode(let newCode):
                    Text("New recovery code")
                        .font(.headline)
                    Text("Save this code somewhere safe. It replaces your previous recovery code.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(verbatim: newCode)
                        .font(.body.monospaced())
                        #if !os(tvOS)
                        .textSelection(.enabled)
                        #endif
                    Button {
                        Task { await viewModel.confirmRecoveryCode() }
                    } label: {
                        Text("I've saved it")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading)

                case .success(let credentials):
                    Text("✓ Authenticated")
                        .font(.headline)
                        .foregroundColor(.green)
                    Group {
                        LabeledValue(label: "Token type", value: credentials.tokenType)
                        LabeledValue(label: "Scope", value: credentials.scope ?? "—")
                        LabeledValue(label: "Expires", value: credentials.expiresAt.formatted())
                    }
                    Button {
                        viewModel.reset()
                    } label: {
                        Text("Reset")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                case .failed(let message):
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                    Button {
                        viewModel.reset()
                    } label: {
                        Text("Try Again")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .onDisappear { viewModel.cancelPolling() }
    }

    /// Buttons for switching to another method offered by the latest response.
    @ViewBuilder
    private var alternativeActionButtons: some View {
        ForEach(Array(viewModel.alternativeActions.enumerated()), id: \.offset) { _, action in
            Button {
                viewModel.selectAction(action)
            } label: {
                Text(title(for: action))
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(viewModel.isLoading)
        }
    }

    private func title(for action: NextAction) -> String {
        switch action {
        case .challengeEmail:
            return "Use email code"
        case .challengePhone(_, let identifier, _):
            return "Use phone \(identifier)"
        case .challengePush(_, let name):
            return "Use push notification on \(name)"
        case .verifyOTP(let channel, _):
            return channel == .totp ? "Use authenticator app code" : "Enter a code"
        case .verifyRecoveryCode:
            return "Use recovery code"
        default:
            return "Use another method"
        }
    }
}

// MARK: - Subviews

private struct LabeledValue: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption.monospaced())
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .foregroundColor(.blue)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

#if os(macOS)
private func getCurrentWindow() -> NSWindow? {
    NSApplication.shared.keyWindow
        ?? NSApplication.shared.mainWindow
        ?? NSApplication.shared.windows.first
}
#else
private struct WindowKey: EnvironmentKey {
    static let defaultValue: UIWindow? = nil
}

extension EnvironmentValues {
    var window: UIWindow? {
        get { self[WindowKey.self] }
        set { self[WindowKey.self] = newValue }
    }
}

struct WindowReaderModifier: ViewModifier {
    @State private var window: UIWindow?
    func body(content: Content) -> some View {
        content
            .environment(\.window, window)
            .background(WindowAccessor(window: $window))
    }
}

struct WindowAccessor: UIViewRepresentable {
    @Binding var window: UIWindow?
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async { self.window = uiView.window }
    }
}

extension View {
    func withWindowReader() -> some View {
        self.modifier(WindowReaderModifier())
    }
}
#endif
