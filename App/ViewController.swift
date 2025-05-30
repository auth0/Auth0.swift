import UIKit
import AuthenticationServices
import Auth0

// -----------------------------------
let clientId = "CLIENT_ID_HERE"
let domain = "CUSTOM_DOMAIN_HERE"
// -----------------------------------

let authenticationClient = Auth0.authentication(clientId: clientId, domain: domain).logging(enabled: true)
let myAccountAudience = "https://\(domain)/me/"
let myAccountScope = "create:me:authentication_methods"
var myAccountClient: MyAccount? = nil
var enrollmentChallenge: PasskeyEnrollmentChallenge?

class ViewController: UIViewController {

    @IBAction func login(_ sender: Any) {
        // Intial login (1)
        Auth0
            .webAuth(clientId: clientId, domain: domain)
            .logging(enabled: true)
            .scope("profile email offline_access")
            .useEphemeralSession()
            .start { result in
                switch result {
                case .failure(let error): print(error)
                case .success(let credentials): // Logged in
                    guard let refreshToken = credentials.refreshToken else {
                        print("No refresh token")
                        return
                    }

                    // Now, using MRRT to get an access token for the My Account API (2)
                    authenticationClient
                        .renew(withRefreshToken: refreshToken, audience: myAccountAudience, scope: myAccountScope)
                        .start { result in
                            switch result {
                            case .failure(let error): print(error)
                            case .success(let apiCredentials):
                                let token = apiCredentials.accessToken

                                // Now, requesting enrollment challenge (3)
                                myAccountClient = Auth0.myAccount(token: token, domain: domain).logging(enabled: true)
                                myAccountClient!
                                    .authenticationMethods
                                    .passkeyEnrollmentChallenge()
                                    .start { result in
                                        switch result {
                                        case .failure(let error): print(error)
                                        case .success(let challenge): print(challenge)
                                            enrollmentChallenge = challenge

                                            let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
                                                relyingPartyIdentifier: challenge.relyingPartyId
                                            )

                                            let request = provider.createCredentialRegistrationRequest(
                                                challenge: challenge.challengeData,
                                                name: challenge.userName,
                                                userID: challenge.userId
                                            )

                                            let controller = ASAuthorizationController(authorizationRequests: [request])
                                            controller.delegate = self
                                            controller.presentationContextProvider = self
                                            controller.performRequests()
                                        }
                                    }
                            }

                        }
                }

            }
    }

    @IBAction func logout(_ sender: Any) {
        Auth0
            .webAuth(clientId: clientId, domain: domain)
            .logging(enabled: true)
            .clearSession(federated: false) { result in
                switch result {
                case .success: print("Logged out")
                case .failure(let error): print(error)
                }
            }
    }

}

extension ViewController: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }

}

extension ViewController: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let newPasskey as ASAuthorizationPlatformPublicKeyCredentialRegistration:
            print("Passkey created: \(newPasskey)")

            // Now, verifying the enrollment (4)
            myAccountClient!
                .authenticationMethods
                .enroll(passkey: newPasskey, challenge: enrollmentChallenge!)
                .start { result in
                    switch result {
                    case .success(let authenticationMethod):
                        print("✅ Passkey enrolled successfully: \(authenticationMethod)")
                    case .failure(let error): dump(error)
                    }
                }
        default:
            print("Unrecognized credential: \(authorization.credential)")
        }
    }

   func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        print("❌ Passkey enrollment failed: \(error.localizedDescription)")

        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                print("User canceled the operation")
            case .notInteractive:
                print("Request requires user interaction")
            default:
                print("Other authorization error: \(authError.code)")
            }
        }
    }

}
