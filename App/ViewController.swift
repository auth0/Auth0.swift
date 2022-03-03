import UIKit
import Auth0
import SafariServices

class SafariUserAgent: NSObject, WebAuthUserAgent {

    var controller: SFSafariViewController
    weak var presenter: UIViewController?

    init(controller: SFSafariViewController, presenter: UIViewController?) {
        self.controller = controller
        self.presenter = presenter
        super.init()
        self.controller.delegate = self
    }

    func start() {
        self.presenter?.present(controller, animated: true)
    }

    func wrap<T>(callback: @escaping (WebAuthResult<T>) -> Void) -> (WebAuthResult<T>) -> Void {
        let finish: (WebAuthResult<T>) -> Void = { [weak controller] (result: WebAuthResult<T>) -> Void in
            if case .failure(let cause) = result, case .userCancelled = cause {
                DispatchQueue.main.async {
                    callback(result)
                }
            } else {
                DispatchQueue.main.async {
                    guard let presenting = controller?.presentingViewController else {
                        return callback(Result.failure(WebAuthError.unknown))
                    }
                    presenting.dismiss(animated: true) {
                        callback(result)
                    }
                }
            }
        }
        return finish
    }

}

extension SafariUserAgent: SFSafariViewControllerDelegate {

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        Auth0.cancel()
    }

}

struct SafariProvider {

    private init() {}

    static func with(_ presenter: UIViewController?) -> WebAuthProvider {
        let provider: WebAuthProvider = { url, callback in
            
            let safari = SFSafariViewController(url: url)
            safari.dismissButtonStyle = .cancel

            return SafariUserAgent(controller: safari, presenter: presenter)
        }
        return provider
    }

    var description: String {
        return String(describing: SFSafariViewController.self)
    }

}

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
        Auth0
            .webAuth()
            .provider(SafariProvider.with(self))
            .logging(enabled: true)
            .start(onAuth)
    }
    
    @IBAction func logout(_ sender: Any) {
        Auth0
            .webAuth()
            .provider(SafariProvider.with(self))
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
