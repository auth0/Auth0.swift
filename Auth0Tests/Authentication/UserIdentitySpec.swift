// UserIdentitySpec.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Quick
import Nimble

@testable import Auth0

let required: [String: AnyObject] = [
    "user_id": UserId,
    "connection": "MyConnection",
    "provider": "auth0"
]

class UserIdentitySharedExamplesConfiguration: QuickConfiguration {
    override class func configure(configuration: Configuration) {
        sharedExamples("invalid identity") { (context: SharedExampleContext) in
            let key = context()["key"] as! String
            it("should return nil when missing \(key)") {
                var dict = required
                dict[key] = nil
                let identity = UserIdentity(json: dict)
                expect(identity).to(beNil())
            }
        }
    }
}
class UserIdentitySpec: QuickSpec {

    override func spec() {

        describe("init from json") {

            let token = NSUUID().UUIDString
            let secret = NSUUID().UUIDString

            it("should build with required values") {
                let identity = UserIdentity(json: required)
                expect(identity?.identifier) == UserId
                expect(identity?.connection) == "MyConnection"
                expect(identity?.provider) == "auth0"
                expect(identity?.social) == false
                expect(identity?.profileData).to(beEmpty())
            }

            it("should have social flag") {
                var json = required
                json["isSocial"] = true
                let identity = UserIdentity(json: json)
                expect(identity?.social) == true
            }

            it("should have profile data") {
                var json = required
                json["profileData"] = ["key": "value"]
                let identity = UserIdentity(json: json)
                expect(identity?.profileData["key"] as? String) == "value"
            }

            it("should have access token & secret") {
                var json = required
                json["access_token"] = token
                json["access_token_secret"] = secret
                let identity = UserIdentity(json: json)
                expect(identity?.accessToken) == token
                expect(identity?.accessTokenSecret) == secret
            }

            it("shoud have expire information") {
                let date = NSDate()
                let interval = date.timeIntervalSince1970
                var json = required
                json["expires_in"] = interval
                let identity = UserIdentity(json: json)
                expect(identity?.expiresIn?.timeIntervalSince1970) == interval
            }

            it("should return nil with empty json") {
                let identity = UserIdentity(json: [:])
                expect(identity).to(beNil())
            }

            ["user_id", "connection", "provider"].forEach { key in itBehavesLike("invalid identity") { return ["key": key] } }
        }
    }

}

