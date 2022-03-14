import Cocoa
import Auth0

class ViewController: NSViewController {

    @IBAction func login(_ sender: Any) {
        Auth0.webAuth()
            .logging(enabled: true)
            .start { result in
                switch result {
                case .success(let credentials): print(credentials)
                case .failure(let error): print(error)
                }
            }
    }
    
    @IBAction func logout(_ sender: Any) {
        Auth0.webAuth()
            .logging(enabled: true)
            .clearSession(federated: false) { result in
                switch result {
                case .success: print("Logged out")
                case .failure(let error): print(error)
                }
            }
    }

}
