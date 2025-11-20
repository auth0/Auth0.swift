import SwiftUI
import Auth0

struct ContentView: View {
    var body: some View {
        VStack {
            Button {
                Auth0
                    .webAuth()
                    .logging(enabled: true)
                    .start {
                        switch $0 {
                        case .failure(let error):
                            break
                        case .success(let credentials):
                            break
                        }
                        print($0)
                    }
            } label: {
                Text("Login")
            }
            
            
            Button {
                Auth0
                    .webAuth()
                    .logging(enabled: true)
                    .clearSession(federated: false) { result in
                        switch result {
                        case .success:
                            break
                        case .failure(let error):
                            break
                        }
                    }
            } label: {
                Text("Logout")
            }

        }
    }
}
