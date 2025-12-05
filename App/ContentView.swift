import SwiftUI
import AuthenticationServices
import Auth0
import Combine
struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 10) {
            
            Button {
                viewModel
                    .signupWithPasskey()

            } label: {
                Text("Sign up with passkey")
                    .foregroundStyle(Color.blue)
            }

            Button {
                Auth0
                    .webAuth(clientId: "GGUVoHL5nseaacSzqB810HWYGHZI34m8", domain: "passkeystestdomain.acmetest.org")
                    .provider(WebAuthentication.webViewProvider())
                    .logging(enabled: true)
                    .start {
                        switch $0 {
                        case .failure(let error):
                            alertTitle = "Login Failed"
                            alertMessage = error.localizedDescription
                            showAlert = true
                        case .success(let credentials):
                            alertTitle = "Login Successful"
                            alertMessage = "Access token: \(credentials.accessToken)"
                            showAlert = true
                        }
                        print($0)
                    }
            } label: {
                Text("Login")
            }.padding(.horizontal)

            Button {
                Auth0
                    .webAuth(clientId: "GGUVoHL5nseaacSzqB810HWYGHZI34m8", domain: "passkeystestdomain.acmetest.org")
                    .provider(WebAuthentication.webViewProvider())
                    .logging(enabled: true)
                    .clearSession(federated: false) { result in
                        switch result {
                        case .success:
                    break
                        case .failure:
                            break
                        }
                    }
            } label: {
                Text("Logout")
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

}
