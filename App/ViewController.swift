import UIKit
import Auth0

class ViewController: UIViewController {

    var onAuth: ((AuthenticationResult<Credentials>) -> ())!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.onAuth = {
            switch $0 {
            case .failure(let error):
                if error.isMultifactorRequired {
                    guard let mfaToken = error.info["mfa_token"] as? String else {
                        return print("No MFA token")
                    }
                    Auth0.authentication()
                        .logging(enabled: true)
                        .multifactorAuthenticators(mfaToken: mfaToken)
                        .start() { result in
                            switch result {
                            case .success(let authenticators):
                                Auth0.authentication()
                                    .logging(enabled: true)
                                    .multifactorChallenge(mfaToken: mfaToken, authenticatorId: authenticators.first!.id)
                                    .start {
                                        print($0)
                                    }
                            case .failure(let error): print(error)
                            }
                        }
                } else {
                    print(error)
                }
            case .success(_): print("Login succeeded")
            }
        }
    }

    @IBAction func login(_ sender: Any) {
        Auth0
            .authentication()
            .logging(enabled: true)
            .login(usernameOrEmail: "USERNAME_OR_EMAIL",
                   password: "PASSWORD",
                   realmOrConnection: "Username-Password-Authentication")
            .start(onAuth)
    }

    @IBAction func logout(_ sender: Any) {
        Auth0
            .webAuth()
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
