import UIKit
import Auth0

class ViewController: UIViewController {

    @IBAction func login(_ sender: Any) {
        Auth0
            .webAuth()
            .scope("openid offline_access")
            .logging(enabled: true)
            .start {
                switch $0 {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.alert(title: "Error", message: "\(error)")
                    }
                case .success(let credentials):
                    DispatchQueue.main.async {
                        self.alert(title: "Success",
                                   message: "Authorized and got a token \(credentials.accessToken)")
                        
                        // Store credentials and run concurrent tests
                        let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
                        _ = credentialsManager.store(credentials: credentials)
                        
                        // Multiple CredentialsManager instances
                        self.testConcurrentCredentialsManagerCalls()

                    }
                }
                print($0)
            }
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
    
    func testConcurrentCredentialsManagerCalls() {
        print("\n=== Testing concurrent CredentialsManager.credentials() across multiple instances ===")
        print("Creating 5 different CredentialsManager instances and calling credentials() concurrently...")
        
        let requestCount = 5
        let group = DispatchGroup()
        
        for i in 1...requestCount {
            group.enter()
            DispatchQueue.global().async {
                // Create a NEW instance of CredentialsManager for each thread
                let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
                
                let startTime = Date()
                print("CredentialsManager \(i): Starting credentials() call at \(startTime)")
                
                credentialsManager.credentials { result in
                    let endTime = Date()
                    let duration = endTime.timeIntervalSince(startTime)
                    
                    switch result {
                    case .success(_):
                        print("CredentialsManager \(i): SUCCESS - Duration: \(String(format: "%.2f", duration))s")
                    case .failure(let error):
                        print("CredentialsManager \(i): FAILED - Duration: \(String(format: "%.2f", duration))s - Error: \(error)")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            print("=== All CredentialsManager instances completed ===\n")
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
