import Combine
import Foundation
import Auth0
import AuthenticationServices

final class ContentViewModel: NSObject, ObservableObject {
    let credentialsManager: CredentialsManager
    fileprivate var signupChallenge:PasskeySignupChallenge!
    init(credentialsManager: CredentialsManager) {
        self.credentialsManager = credentialsManager
    }
    
    func signupWithPasskey() {
        if #available(iOS 16.6, *) {
            Auth0.authentication(clientId: "GGUVoHL5nseaacSzqB810HWYGHZI34m8", domain: "passkeystestdomain.acmetest.org")
                .passkeySignupChallenge(email: "nandanprabhu97@gmail.com", phoneNumber: nil, username: nil, name: nil, connection: nil, organization: nil)
                .start { result in
                    switch result {
                    case .success(let signupChallenge):
                        //                            self.signupChallenge = signupChallenge
                        let challenge: Data = signupChallenge.challengeData // Obtain this from the server.
                        let userID: Data = signupChallenge.userId // Obtain this from the server.
                        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: signupChallenge.relyingPartyId)
                        let platformKeyRequest = platformProvider.createCredentialRegistrationRequest(challenge: challenge, name: signupChallenge.userName, userID: userID)
                        let authController = ASAuthorizationController(authorizationRequests: [platformKeyRequest])
                        self.signupChallenge = signupChallenge
                        authController.delegate = self
                        authController.performRequests()
                    case .failure(let error):
                        break
                    }
                }
        } else {
            // Fallback on earlier versions
        }
    }
}


@available(iOS 16.6, *)
extension ContentViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        print(error)
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? SignupPasskey {
            Auth0.authentication(clientId: "GGUVoHL5nseaacSzqB810HWYGHZI34m8", domain: "passkeystestdomain.acmetest.org").login(passkey: credential, challenge: self.signupChallenge, connection: nil, audience: nil, scope: "", organization: nil)
                .start { result in
                    switch result {
                    case .success(let credentials):
                        break
                    case .failure(let error):
                        break
                        //                        CredentialsManager(authentication: any Authentication).store(credentials: credentials)
                    }
                }
        } else if let credential = authorization.credential as? LoginPasskey {
//            Auth0.authentication(clientId: "xEGgKgL2l8PERx65O4EIQyFjLPi4HA3h", domain: "passkeystestdomain.acmetest.org")
//                .login(passkey: credential, challenge: self.loginChallenge, connection: nil, audience: nil, scope: "", organization: "org_gyMM3ig29cYHWY9G").start { result in
//                    switch result {
//                    case .success(let credentials):
//                        break
//                    case .failure(let error):
//                        break
//                    }
//                }
        }
    }
}
