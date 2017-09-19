//
//  ViewController.swift
//  OAuth2
//
//  Created by Hernan Zalazar on 5/25/16.
//  Copyright © 2016 Auth0. All rights reserved.
//

import UIKit
import Auth0

class ViewController: UIViewController {

    var onAuth: ((Result<Credentials>) -> ())!

    @IBOutlet weak var oauth2: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.onAuth = { [weak self] in
            switch $0 {
            case .failure(let cause):
                let alert = UIAlertController(title: "Auth Failed!", message: "\(cause)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            case .success(let credentials):
                let token = credentials.accessToken ?? credentials.idToken
                let alert = UIAlertController(title: "Auth Success!", message: "Authorized and got a token \(String(describing: token))", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            print($0)
        }
    }

    @IBAction func startOAuth2(_ sender: Any) {
        var auth0 = Auth0.webAuth()
        auth0
            .logging(enabled: true)
            .start(onAuth)

        var auth = Auth0.authentication()
        _ = auth.logging(enabled: true)
        auth.changePassword(email: "martinwalsh@gmail.com", oldPassword: "Password2", newPassword: "Password3", connection: "Username-Password-Authentication").start { print($0) }

    }

    @IBAction func startGoogleOAuth2(_ sender: Any) {
        var auth0 = Auth0.webAuth()
        auth0
            .logging(enabled: true)
            .connection("google-oauth2")
            .start(onAuth)
    }

    @IBAction func startTokenGoogleOAuth2(_ sender: Any) {
        var auth0 = Auth0.webAuth()
        auth0
            .logging(enabled: true)
            .connection("google-oauth2")
            .responseType([.token])
            .start(onAuth)
    }

    @IBAction func startIDTokenGoogleOAuth2(_ sender: Any) {
        var auth0 = Auth0.webAuth()
        auth0
            .logging(enabled: true)
            .connection("google-oauth2")
            .responseType([.idToken])
            .nonce("abc1234")
            .start(onAuth)
    }

    @IBAction func startTokenIDTokenGoogleOAuth2(_ sender: Any) {
        var auth0 = Auth0.webAuth()
        auth0
            .logging(enabled: true)
            .connection("google-oauth2")
            .responseType([.token, .idToken])
            .nonce("abc1234")
            .start(onAuth)
    }

    @IBAction func startCodeIDTokenGoogleOAuth2(_ sender: Any) {
        var auth0 = Auth0.webAuth()
        auth0
            .logging(enabled: true)
            .connection("google-oauth2")
            .scope("read:entity")
            .responseType([.code , .idToken])
            .nonce("abc1234")
            .start(onAuth)
    }
}
