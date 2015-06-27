//
//  API.swift
//  SwiftSample
//
//  Created by Hernan Zalazar on 6/23/15.
//  Copyright (c) 2015 Auth0. All rights reserved.
//

import Foundation
import Alamofire

public class API: NSObject {

    public static let sharedInstance = API()

    public let domainUrl:NSURL
    let manager: Alamofire.Manager

    public override convenience init() {
        let info = NSBundle.mainBundle().infoDictionary
        let domain:String = info?["Auth0Domain"] as! String
        self.init(domain: domain)
    }

    public init(domain: String) {
        self.domainUrl = (domain.hasPrefix("http") ? NSURL(string: domain) : NSURL(string: "https://".stringByAppendingString(domain)))!
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.manager = Alamofire.Manager(configuration: configuration)
    }

    public func users(token: String) -> Users {
        return Users(api: self, token: token)
    }
    
}
