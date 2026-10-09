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
                #if !os(tvOS)
                .textFieldStyle(.roundedBorder)
                #endif
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                #endif

                // MARK: Phone Number

                TextField(text: $viewModel.phoneNumber) {
                    Text("phone number (e.g. +14155552671)")
                }
                #if !os(tvOS)
                .textFieldStyle(.roundedBorder)
                #endif
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.phonePad)
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
                    .disabled(viewModel.isLoading || (viewModel.email.isEmpty && viewModel.phoneNumber.isEmpty))

                    Button {
                        Task {
                            await viewModel.loginWithPasskey(window: window)
                        }
                    } label: {
                        Label("Login with Passkey", systemImage: "key")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(viewModel.isLoading)
                }
                #endif

                // MARK: Send Email Code (passwordless)

                Button {
                    Task { await viewModel.requestOTPChallenge() }
                } label: {
                    Label("Send email code", systemImage: "envelope")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(viewModel.isLoading || viewModel.email.isEmpty)

                // Inline OTP entry — shown during passkey identifier verification
                // or when logging in via passwordless email code.
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
            return channel == .phone ? "phone" : "email"
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

    @State private var isSubmitting = false

    private func submitAction() {
        guard !isSubmitting else { return }
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            if isPasskeyVerification {
                #if PASSKEYS_PLATFORM
                await viewModel.submitPasskeyVerificationOTP()
                #endif
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
                Button("Resend code") {
                    Task {
                        if isPasskeyVerification {
                            #if PASSKEYS_PLATFORM
                            await viewModel.resendPasskeyVerificationOTP()
                            #endif
                        } else {
                            await viewModel.requestOTPChallenge()
                        }
                    }
                }
                .font(.subheadline)
                .disabled(viewModel.isLoading)
                Spacer()
                Button("Cancel") {
                    viewModel.showOTPSheet = false
                }
                .font(.subheadline)
            }
        }
        .padding(16)
        #if os(iOS)
        .background(Color(UIColor.secondarySystemBackground))
        #elseif os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color.secondary.opacity(0.1))
        #endif
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
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    #endif
                    .multilineTextAlignment(.center)
                    .frame(width: 44, height: 54)
                    #if os(iOS)
                    .background(Color(UIColor.systemGray6))
                    #elseif os(macOS)
                    .background(Color(NSColor.controlBackgroundColor))
                    #else
                    .background(Color.secondary.opacity(0.15))
                    #endif
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
                            // Distribute pasted code across fields starting at this index
                            let chars = Array(filtered.prefix(6 - index))
                            for (offset, char) in chars.enumerated() {
                                digits[index + offset] = String(char)
                            }
                            let nextIndex = min(index + chars.count, 5)
                            focusedIndex = digits[nextIndex].isEmpty ? nextIndex : nil
                            if digits.allSatisfy({ $0.count == 1 }) { onComplete() }
                            return
                        }
                        if filtered != newValue {
                            digits[index] = filtered
                            return
                        }
                        if filtered.isEmpty {
                            if index > 0 { focusedIndex = index - 1 }
                        } else {
                            if index < 5 {
                                focusedIndex = index + 1
                            } else {
                                focusedIndex = nil
                            }
                            if digits.allSatisfy({ $0.count == 1 }) { onComplete() }
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
