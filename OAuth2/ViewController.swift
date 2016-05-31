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

    @IBOutlet weak var oauth2: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.client = Client()
        self.oauth2.enabled = client != nil
    }

    @IBAction func startOAuth2(sender: AnyObject) {
        guard let client = self.client else { return }
        let session = Auth0
            .oauth2(clientId: client.clientId, domain: client.domain)
            .start { print($0) }
        OAuth2.sharedInstance.currentSession = session
    }

}

class OAuth2 {
    var currentSession: OAuth2Session? = nil

    static let sharedInstance = OAuth2()

    func resume(url: NSURL, options: [String: AnyObject] = [:]) -> Bool {
        let handled = self.currentSession?.resume(url, options: options) ?? false
        if handled {
            self.currentSession = nil
        }
        return handled
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
