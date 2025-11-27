import SwiftUI
import Auth0
import Combine
struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 10) {
            Button {
                Auth0
                    .webAuth()
                    .logging(enabled: true)
                    .start {
                        switch $0 {
                        case .failure:
                            break
                        case .success:
                            break
                        }
                        print($0)
                    }
            } label: {
                Text("Login")
            }.padding(.horizontal)
            
            Button {
                Auth0
                    .webAuth()
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
    }

}
