// UserProfileSpec.swift
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
import Auth0

private let UserId = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
private let SupportAtAuth0 = "support@auth0.com"
private let Support = "support"
private let Nickname = "sup"
private let PictureURL = NSURL(string: "https://auth0.com")!
private let CreatedAt = "2016-04-27T17:59:00Z"

private func dateFromISODate(string: String) -> NSDate {
    let dateFormatter = NSDateFormatter()
    dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
    return dateFormatter.dateFromString(string)!
}

private func basicProfile(id: String = UserId, name: String = Support, nickname: String = Nickname, picture: String = PictureURL.absoluteString, createdAt: String = CreatedAt) -> [String: AnyObject] {
    return ["user_id": id, "name": name, "nickname": nickname, "picture": picture, "created_at": createdAt]
}

class ProfileSharedExamplesConfiguration: QuickConfiguration {
    override class func configure(configuration: Configuration) {
        sharedExamples("invalid profile") { (context: SharedExampleContext) in
            let key = context()["key"] as! String
            it("should return nil when missing \(key)") {
                var dict = basicProfile()
                dict[key] = nil
                let profile = UserProfile(dictionary: dict)
                expect(profile).to(beNil())
            }
        }
    }
}

class UserProfileSpec: QuickSpec {
    override func spec() {
        describe("init from dictionary") {

            it("should build with required values") {
                let profile = UserProfile(dictionary: basicProfile())
                expect(profile).toNot(beNil())
                expect(profile?.id) == UserId
                expect(profile?.name) == Support
                expect(profile?.nickname) == Nickname
                expect(profile?.pictureURL) == PictureURL
                expect(profile?.createdAt) == dateFromISODate(CreatedAt)
            }

            it("should build with email") {
                var info = basicProfile()
                info["email"] = SupportAtAuth0
                let profile = UserProfile(dictionary: info)
                expect(profile?.email) == SupportAtAuth0
            }

            it("should build with optional values") {
                var info = basicProfile()
                let optional: [String: AnyObject] = [
                    "email": SupportAtAuth0,
                    "email_verified": true,
                    "given_name": "John",
                    "family_name": "Doe"
                ]
                optional.forEach { key, value in info[key] = value }
                let profile = UserProfile(dictionary: info)
                expect(profile?.email) == SupportAtAuth0
                expect(profile?.emailVerified) == true
                expect(profile?.givenName) == "John"
                expect(profile?.familyName) == "Doe"
            }

            it("should build with extra values") {
                var info = basicProfile()
                let optional: [String: AnyObject] = [
                    "my_custom_key": "custom_value"
                ]
                optional.forEach { key, value in info[key] = value }
                let profile = UserProfile(dictionary: info)
                expect(profile?["my_custom_key"] as? String) == "custom_value"
            }


            ["user_id", "name", "nickname", "picture", "created_at"].forEach { key in itBehavesLike("invalid profile") { ["key": key] } }
        }
    }
}
