// ProfileSpec.swift
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

class ProfileSharedExamplesConfiguration: QuickConfiguration {
    override class func configure(_ configuration: Configuration) {
        sharedExamples("invalid profile") { (context: SharedExampleContext) in
            let key = context()["key"] as! String
            it("should return nil when missing \(key)") {
                var dict = basicProfile()
                dict[key] = nil
                let profile = Profile(json: dict)
                expect(profile).to(beNil())
            }
        }
    }
}

class UserProfileSpec: QuickSpec {
    override func spec() {
        describe("init from dictionary") {

            it("should build with required values") {
                let profile = Profile(json: basicProfile())
                expect(profile).toNot(beNil())
                expect(profile?.id) == UserId
                expect(profile?.name) == Support
                expect(profile?.nickname) == Nickname
                expect(profile?.pictureURL) == PictureURL
                expect(profile?.createdAt?.timeIntervalSince1970) == CreatedAtTimestamp
                expect(profile?.identities).to(beEmpty())
            }

            it("should build with email") {
                var info = basicProfile()
                info["email"] = SupportAtAuth0
                let profile = Profile(json: info)
                expect(profile?.email) == SupportAtAuth0
            }

            it("should build with optional values") {
                var info = basicProfile()
                let optional: [String: Any] = [
                    "email": SupportAtAuth0,
                    "email_verified": true,
                    "given_name": "John",
                    "family_name": "Doe"
                ]
                optional.forEach { key, value in info[key] = value }
                let profile = Profile(json: info)
                expect(profile?.email) == SupportAtAuth0
                expect(profile?.emailVerified) == true
                expect(profile?.givenName) == "John"
                expect(profile?.familyName) == "Doe"
            }

            it("should build with extra values") {
                var info = basicProfile()
                let optional: [String: Any] = [
                    "my_custom_key": "custom_value"
                ]
                optional.forEach { key, value in info[key] = value }
                let profile = Profile(json: info)
                expect(profile?["my_custom_key"] as? String) == "custom_value"
            }

            it("should build with identities") {
                var info = basicProfile()
                info["identities"] = [
                    [
                        "user_id": "1234567890",
                        "connection": "facebook",
                        "provider": "facebook"
                    ]
                ]
                let profile = Profile(json: info)
                expect(profile?.identities.first).toNot(beNil())
            }

            it("should build with simple userinfo") {
                var info: [String: Any] = [:]
                info["sub"] = "auth0|123456789"
                let profile = Profile(json: info)
                expect(profile?.additionalAttributes["sub"] as? String) == "auth0|123456789"
            }

            it("should build with basic userinfo") {
                var info: [String: Any] = [:]
                info["sub"] = "auth0|123456789"
                info["updated_at"] = "2017-02-01T15:19:28.395Z"
                let profile = Profile(json: info)
                expect(profile?.additionalAttributes["sub"] as? String) == "auth0|123456789"
                expect(profile?.additionalAttributes["updated_at"] as? String) == "2017-02-01T15:19:28.395Z"
            }

        }

        describe("time conversion") {

            it("should convert ISO8601") {
                var json = basicProfile()
                json["created_at"] = CreatedAt
                let profile = Profile(json: json)
                expect(profile?.createdAt?.timeIntervalSince1970) == CreatedAtTimestamp
            }

        }

        describe("metadata") {

            it("should have user_metadata") {
                var info = basicProfile()
                let metadata: [String: Any] = [
                    "first_name": "John",
                    "last_name": "Doe"
                ]
                info["user_metadata"] = metadata

                let profile = Profile(json: info)
                expect(profile?.userMetadata["first_name"] as? String) == "John"
                expect(profile?.userMetadata["last_name"] as? String) == "Doe"
            }

            it("should at least return empty user_metadata") {
                let info = basicProfile()
                let profile = Profile(json: info)
                expect(profile?.userMetadata.isEmpty) == true
            }

            it("should have app_metadata") {
                var info = basicProfile()
                let metadata: [String: Any] = [
                    "subscription": "paid",
                    "logins": 10,
                    "verified": true
                ]
                info["app_metadata"] = metadata

                let profile = Profile(json: info)
                expect(profile?.appMetadata["subscription"] as? String) == "paid"
                expect(profile?.appMetadata["logins"] as? Int) == 10
                expect(profile?.appMetadata["verified"] as? Bool) == true
            }

            it("should at least return empty app_metadata") {
                let info = basicProfile()
                let profile = Profile(json: info)
                expect(profile?.appMetadata.isEmpty) == true
            }
        }

        describe("generic types") {

            var profile: Profile!
            let integer = 1986
            let dictionary = ["key": "value"]
            let list = [1, 2, 3, 4]

            beforeEach {
                var info = basicProfile()
                let optional: [String: Any] = [
                    "integer": integer,
                    "boolean": true,
                    "dictionary": dictionary,
                    "list": list
                ]
                optional.forEach { key, value in info[key] = value }
                profile = Profile(json: info)
            }

            it("should return integer") {
                expect(profile.value("integer")) == integer
            }

            it("should return boolean") {
                expect(profile.value("boolean")) == true
            }

            it("should return dictionary") {
                expect(profile.value("dictionary")) == dictionary
            }

            it("should return list") {
                expect(profile.value("list")) == list
            }

        }
    }
}
