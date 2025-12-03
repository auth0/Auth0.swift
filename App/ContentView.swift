import SwiftUI
import Auth0
import Combine
struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State var email: String = ""
    @State var password: String = ""
    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        if viewModel.showOTPTextField {
            TextField(text: $viewModel.otpCode) {
                Text("Enter otp")
            }.keyboardType(.numberPad)
            .padding()
            .cornerRadius(4)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.blue, lineWidth: 1)
            }
            
            Button {
                viewModel.confirmEnrollment()
            } label: {
                Text("Continue")
            }
            .frame(height: 48)
            .background(Color.black)
        } else if let qrCodeImage = viewModel.qrCodeImage {
            VStack {
                Spacer()
                qrCodeImage
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding()
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black, lineWidth: 0.5)
                    }
                
                TextField(text: $viewModel.otpCode) {
                    Text("Enter otp")
                }.keyboardType(.numberPad)
                    .padding()
                    .cornerRadius(4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.blue, lineWidth: 1)
                    }
                
                Button {
                    viewModel.confirmEnrollment()
                } label: {
                    Text("Continue")
                }
                .frame(height: 48)
                .background(Color.black)
                Spacer()
            }
        } else {
            VStack(spacing: 10) {
                TextField("email", text: $email)
                    .keyboardType(.emailAddress)
                    .padding()
                    .cornerRadius(4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.blue, lineWidth: 1)
                    }
                
                SecureField("password", text: $password)
                    .padding()
                    .cornerRadius(4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.blue, lineWidth: 1)
                    }
                Button {
                    viewModel.login(email: email, password: password)
                } label: {
                    Text("Login")
                        .foregroundStyle(Color.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .background(Color.black)

                Button {
                    _ = viewModel.credentialsManager.clear()
                    _ = viewModel.credentialsManager.clear(forAudience: "")
                } label: {
                    Text("Logout")
                        .foregroundStyle(Color.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .background(Color.black)
                
                Button {
                    viewModel.fetchAPICredentials()
                } label: {
                    Text("Get credentials")
                        .foregroundStyle(Color.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .background(Color.black)
                Spacer()
                
                if let credentials = viewModel.credentials {
                    Text("\(credentials.accessToken)")
                        .foregroundStyle(Color.white)
                        .background(Color.black)
                        .frame(maxWidth: .infinity)
                }
            }.padding()
        }
    }

}
