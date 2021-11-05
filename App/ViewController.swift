import UIKit
import Auth0
import AuthenticationServices

class ViewController: UIViewController {
    
    var onAuth: ((Result<Credentials>) -> ())!
    
    @IBOutlet weak var oauth2: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.onAuth = { [weak self] in
            switch $0 {
            case .failure(let cause):
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Auth Failed!", message: "\(cause)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            case .success(let credentials):
                DispatchQueue.main.async {
                    let token = credentials.accessToken
                    let alert = UIAlertController(title: "Auth Success!", message: "Authorized and got a token \(String(describing: token))", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
            print($0)
        }
    }
    
    @IBAction func startOAuth2(_ sender: Any) {
            Auth0.webAuth()
            .logging(enabled: true)
            .start(onAuth)
    }
    
    @IBAction func startGoogleOAuth2(_ sender: Any) {
        Auth0.webAuth()
            .logging(enabled: true)
            .connection("google-oauth2")
            .start(onAuth)
    }
    
    @IBAction func startTokenGoogleOAuth2(_ sender: Any) {
        Auth0.webAuth()
            .logging(enabled: true)
            .connection("google-oauth2")
            .start(onAuth)
    }
    
    @IBAction func startIDTokenGoogleOAuth2(_ sender: Any) {
        Auth0.webAuth()
            .logging(enabled: true)
            .connection("google-oauth2")
            .nonce("abc1234")
            .start(onAuth)
    }
    
    @IBAction func startTokenIDTokenGoogleOAuth2(_ sender: Any) {
        Auth0.webAuth()
            .logging(enabled: true)
            .connection("google-oauth2")
            .nonce("abc1234")
            .start(onAuth)
    }
    
    @IBAction func startCodeIDTokenGoogleOAuth2(_ sender: Any) {
        Auth0.webAuth()
            .logging(enabled: true)
            .connection("google-oauth2")
            .scope("read:entity")
            .nonce("abc1234")
            .start(onAuth)
    }
}
