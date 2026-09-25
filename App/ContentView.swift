import SwiftUI
import Auth0

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel(authenticationClient: Auth0.authentication())

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

                case .identifyEmail:
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        #if !os(macOS)
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

                case .challengeEmail:
                    Text("We'll send a one-time code to your email.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button {
                        Task { await viewModel.triggerChallenge() }
                    } label: {
                        Text("Send OTP")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading)

                case .verifyOTP(_, let identifier):
                    if let identifier {
                        Text("Enter the code sent to \(identifier)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    TextField("One-time code", text: $viewModel.otp)
                        .textContentType(.oneTimeCode)
                        #if !os(macOS)
                        .keyboardType(.numberPad)
                        #endif
                        #if !os(tvOS)
                        .textFieldStyle(.roundedBorder)
                        #endif
                    if let otpError = viewModel.otpAttemptError {
                        Text(otpError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Button {
                        viewModel.otpAttemptError = nil
                        Task { await viewModel.submitOtp(viewModel.otp) }
                    } label: {
                        Text("Verify")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading || viewModel.otp.isEmpty)

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
                        viewModel.embeddedAuthUIState = .initial
                        viewModel.otp = ""
                        viewModel.email = ""
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
                        viewModel.embeddedAuthUIState = .initial
                        viewModel.otp = ""
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
    }
}

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
