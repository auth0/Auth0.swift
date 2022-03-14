import UIKit
import Auth0

class ViewController: UIViewController {
    
    var onAuth: ((WebAuthResult<Credentials>) -> ())!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.onAuth = {
            switch $0 {
            case .failure(let cause):
                DispatchQueue.main.async {
                    self.alert(title: "Error", message: "\(cause)")
                }
            case .success(let credentials):
                DispatchQueue.main.async {
                    self.alert(title: "Success",
                               message: "Authorized and got a token \(credentials.accessToken)")
                }
            }
            print($0)
        }
    }
    
    @IBAction func login(_ sender: Any) {
        Auth0.webAuth()
            .logging(enabled: true)
            .start(onAuth)
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

extension UIViewController {
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))

        present(alert, animated: true)
    }
    
}
