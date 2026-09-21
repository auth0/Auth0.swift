import SwiftUI
import Combine
import Auth0

#if !os(macOS)
   import UIKit
#else
   import AppKit
#endif


struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel(authenticationClient: Auth0.authentication())

    #if os(macOS)
    @State private var currentWindow: Auth0WindowRepresentable?
    #else
    @Environment(\.window) private var window
    #endif

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: Email

                TextField(text: $viewModel.email) {
                    Text("email")
                }
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                #endif

                // MARK: Signup with Passkey

                #if PASSKEYS_PLATFORM
                if #available(iOS 16.6, *) {
                    Button {
                        Task {
                            await viewModel.signupWithPasskey(window: window)
                        }
                    } label: {
                        Label("Signup with Passkey", systemImage: "person.badge.key")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading || viewModel.email.isEmpty)
                }
                #endif

                // Inline OTP entry — shown while collecting the 6-digit
                // identifier-verification code during passkey signup.
                if viewModel.showOTPSheet {
                    OTPEntryView(viewModel: viewModel)
                }

                // MARK: Clear Credentials

                Button {
                    viewModel.clearCredentials()
                } label: {
                    Label("Clear Credentials", systemImage: "trash")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(viewModel.isLoading)

                if viewModel.isAuthenticated {
                    Text("✓ Authenticated")
                        .foregroundColor(.green)
                        .font(.caption)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .task {
            await viewModel.checkAuthentication()
        }
        #if os(macOS)
        .onAppear {
            currentWindow = getCurrentWindow()
        }
        #endif
    }
}

// MARK: - Inline OTP Entry

struct OTPEntryView: View {
    @ObservedObject var viewModel: ContentViewModel

    private var isPasskeyVerification: Bool {
        if case .passkeyVerification = viewModel.otpContext { return true }
        return false
    }

    private var channelLabel: String {
        if case .passkeyVerification(let channel) = viewModel.otpContext {
            return channel == "phone" ? "phone" : "email"
        }
        return "email"
    }

    private var title: String {
        if isPasskeyVerification {
            return viewModel.isRetryingPasskeyVerification ? "Retry \(channelLabel) verification" : "Verify \(channelLabel)"
        }
        return "Verify Email"
    }

    private var subtitle: String {
        isPasskeyVerification
            ? "Enter the 6-digit code sent to your \(channelLabel) to continue passkey registration."
            : "Enter the 6-digit code sent to\n\(viewModel.email)"
    }

    private func submitAction() {
        Task {
            if isPasskeyVerification {
                await viewModel.submitPasskeyVerificationOTP()
            } else {
                await viewModel.loginWithOTP()
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            OTPInputView(digits: $viewModel.otpDigits, onComplete: submitAction)

            Button {
                submitAction()
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Verify")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isLoading || viewModel.otpDigits.joined().count < 6)

            HStack {
                if !isPasskeyVerification {
                    Button("Resend code") {
                        Task { await viewModel.requestOTPChallenge() }
                    }
                    .font(.subheadline)
                    .disabled(viewModel.isLoading)
                }
                Spacer()
                Button("Cancel") {
                    viewModel.showOTPSheet = false
                }
                .font(.subheadline)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - OTP Input

struct OTPInputView: View {
    @Binding var digits: [String]
    @FocusState private var focusedIndex: Int?
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { index in
                TextField("", text: $digits[index])
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 44, height: 54)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(focusedIndex == index ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .font(.title2.bold())
                    .focused($focusedIndex, equals: index)
                    .onChange(of: digits[index]) { newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count > 1 {
                            digits[index] = String(filtered.last!)
                        } else {
                            digits[index] = filtered
                        }
                        if digits[index].count == 1 {
                            if index < 5 {
                                focusedIndex = index + 1
                            } else {
                                focusedIndex = nil
                                onComplete()
                            }
                        }
                    }
            }
        }
        .onAppear { focusedIndex = 0 }
    }
}

// MARK: - Button Styles

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
    if let keyWindow = NSApplication.shared.keyWindow {
        return keyWindow
    }

    if let mainWindow = NSApplication.shared.mainWindow {
        return mainWindow
    }

    return NSApplication.shared.windows.first
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
            .background(
                WindowAccessor(window: $window)
            )
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
        DispatchQueue.main.async {
            self.window = uiView.window
        }
    }
}

extension View {
    func withWindowReader() -> some View {
        self.modifier(WindowReaderModifier())
    }
}

#endif
