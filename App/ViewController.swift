import UIKit
import Auth0

// MARK: - Swift 6 Sendability Test: CredentialsManager in Actor
actor AuthService {
    let credentialsManager: CredentialsManager
    
    init() {
        self.credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    }
    
    func fetchCredentials() async throws -> Credentials {
        // This method can be called across concurrency contexts eg. Actor
        return try await credentialsManager.credentials(withScope: "openid profile email",
                                                        minTTL: 60,
                                                        parameters: [:],
                                                        headers: [:])
    }
}

class ViewController: UIViewController {
    
    // Swift 6 test: CredentialsManager can be used within actors
    private let authService = AuthService()

    @IBAction func login(_ sender: Any) {
        Auth0
            .webAuth()
            .logging(enabled: true)
            .start { [weak self] result in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.alert(title: "Error", message: "\(error)")
                    }
                case .success(let credentials):
                    DispatchQueue.main.async {
                        self?.alert(title: "Success",
                                   message: "Authorized and got a token \(credentials.accessToken)")
                    }
  //                   Test: Fetch credentials from actor with custom scope
                    Task {
                        await self?.testFetchCredentials()
                    }
                }
                print(result)
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
    
    // Additional test method to fetch credentials from actor
    func testFetchCredentials() async {
        do {
            let credentials = try await authService.fetchCredentials()
            print("Successfully fetched credentials within actor: \(credentials.accessToken)")
        } catch {
            print("Failed to fetch credentials: \(error)")
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
