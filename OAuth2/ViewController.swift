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

    var client: Client? = nil
    var onAuth: (Result<Credentials, Authentication.Error> -> ())!

    @IBOutlet weak var oauth2: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.client = Client()
        self.oauth2.enabled = client != nil
        self.onAuth = { [weak self] in
            switch $0 {
            case .Failure(let cause):
                let alert = UIAlertController(title: "Auth Failed!", message: "\(cause)", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                self?.presentViewController(alert, animated: true, completion: nil)
            case .Success(let credentials):
                let alert = UIAlertController(title: "Auth Success!", message: "Authorized and got access_token \(credentials.accessToken)", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                self?.presentViewController(alert, animated: true, completion: nil)
            }
            print($0)
        }
    }

    @IBAction func startOAuth2(sender: AnyObject) {
        guard let client = self.client else { return }
        Auth0
            .oauth2(clientId: client.clientId, domain: client.domain)
            .start(onAuth)
    }

    @IBAction func startGoogleOAuth2(sender: AnyObject) {
        guard let client = self.client else { return }
        Auth0
            .oauth2(clientId: client.clientId, domain: client.domain)
            .connection("google-oauth2")
            .start(onAuth)
    }
}

struct Client {
    let clientId: String
    let domain: String

    init?() {
        guard
            let path = NSBundle.mainBundle().pathForResource("Auth0", ofType: "plist"),
            let clientCredentials = NSDictionary(contentsOfFile: path) as? [String: String],
            let clientId = clientCredentials["ClientId"],
            let domain = clientCredentials["Domain"]
        else { return nil }

        self.clientId = clientId
        self.domain = domain
    }
}
