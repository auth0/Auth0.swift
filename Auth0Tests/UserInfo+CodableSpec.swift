// UserInfoCodableSpec.swift
//
// Copyright (c) 2021 Auth0 (http://auth0.com)
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

import Foundation
import Quick
import Nimble
import JWTDecode

@testable import Auth0

private let BasicProfileJWT = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhdXRoMHwxMjM0NTY3ODkiLCJuYW1lIjoic3VwcG9ydCIsIm5pY2tuYW1lIjoic3VwIiwicGljdHVyZSI6Imh0dHBzOi8vYXV0aDAuY29tL3BpY3R1cmUiLCJ1cGRhdGVkX2F0IjoiMTQ0MDAwNDY4MSJ9.TppFbhhG2or0Ygtig_7wvMWj5pj1nibZQKlhp6YA0NnEmAU5oj9KxkL9BGCAjIUQcImO3Suiur27qNRDvTY7yG61kUfVFYmcdCcYZ3tuS2glA2Ofwjv-gkgkORFaggqwT4jaZ19MViHtW71AjH-l8Q9HbbCfD3pCI-M-95oSs7sPssXw3vOMbC_iMm-0TPzwSs32rc2Rmpni3T-rjthb7ZjYxpm2RUPvlpUMev0nb_E3QbLG-ct8jWwvDAjZbTgCYBkw0pmp57T4VBQ8acTQGvOi1lryrJ6kK9O9a_h9Yxf1t4HhBhfMW6p7fXNLVMYo5su3NFqW1KMVgUW7jNzKwA"

class UserInfoCodableSpec: QuickSpec {
    override func spec() {

        describe("encode and decode UserInfo") {
            it("should only contain sub") {
                let userInfo = UserInfo(json: ["sub": Sub])

                let data = try JSONEncoder().encode(userInfo)
                let decodedUserInfo = try? JSONDecoder().decode(UserInfo.self, from: data)

                expect(decodedUserInfo?.sub) == Sub
                expect(decodedUserInfo?.name).to(beNil())
                expect(decodedUserInfo?.givenName).to(beNil())
                expect(decodedUserInfo?.familyName).to(beNil())
                expect(decodedUserInfo?.middleName).to(beNil())
                expect(decodedUserInfo?.nickname).to(beNil())
                expect(decodedUserInfo?.preferredUsername).to(beNil())
                expect(decodedUserInfo?.profile).to(beNil())
                expect(decodedUserInfo?.picture).to(beNil())
                expect(decodedUserInfo?.website).to(beNil())
                expect(decodedUserInfo?.email).to(beNil())
                expect(decodedUserInfo?.emailVerified).to(beNil())
                expect(decodedUserInfo?.gender).to(beNil())
                expect(decodedUserInfo?.birthdate).to(beNil())
                expect(decodedUserInfo?.zoneinfo).to(beNil())
                expect(decodedUserInfo?.locale).to(beNil())
                expect(decodedUserInfo?.phoneNumber).to(beNil())
                expect(decodedUserInfo?.phoneNumberVerified).to(beNil())
                expect(decodedUserInfo?.address).to(beNil())
                expect(decodedUserInfo?.updatedAt).to(beNil())
                expect(decodedUserInfo?.customClaims).notTo(beNil())
                expect(decodedUserInfo?.customClaims).to(beEmpty())
            }

            it("should build with extended oidc profile") {
                var info = basicProfileOIDC()
                let optional: [String: Any] = [
                    "website": WebsiteURL.absoluteString,
                    "profile": ProfileURL.absoluteString,
                    "email_verified": true,
                    "phone_number_verified": false
                ]
                optional.forEach { key, value in info[key] = value }

                let userInfo = UserInfo(json: info)
                let data = try JSONEncoder().encode(userInfo)
                let decodedUserInfo = try? JSONDecoder().decode(UserInfo.self, from: data)

                expect(decodedUserInfo?.sub) == Sub
                expect(decodedUserInfo?.name) == Support
                expect(decodedUserInfo?.nickname) == Nickname
                expect(decodedUserInfo?.picture) == PictureURL
                expect(decodedUserInfo?.website) == WebsiteURL
                expect(decodedUserInfo?.profile) == ProfileURL
                expect(decodedUserInfo?.emailVerified) == true
                expect(decodedUserInfo?.phoneNumberVerified) == false
                expect(decodedUserInfo?.updatedAt?.timeIntervalSince1970) == UpdatedAtTimestamp
                expect(decodedUserInfo?.customClaims).to(beEmpty())
            }

            it("should build with basic oidc profile with locale and zoneinfo") {
                var info = basicProfileOIDC()
                let optional: [String: Any] = [
                    "locale": LocaleUS,
                    "zoneinfo": ZoneEST
                ]
                optional.forEach { key, value in info[key] = value }

                let userInfo = UserInfo(json: info)
                let data = try JSONEncoder().encode(userInfo)
                let decodedUserInfo = try? JSONDecoder().decode(UserInfo.self, from: data)

                expect(decodedUserInfo?.locale?.identifier) == Locale(identifier: LocaleUS).identifier
                expect(decodedUserInfo?.zoneinfo?.identifier) == TimeZone(identifier: ZoneEST)!.identifier
            }

            it("should build from jwt body") {
                let jwt = try! decode(jwt: BasicProfileJWT)

                let userInfo = UserInfo(json: jwt.body)
                let data = try JSONEncoder().encode(userInfo)
                let decodedUserInfo = try? JSONDecoder().decode(UserInfo.self, from: data)

                expect(decodedUserInfo?.sub) == Sub
                expect(decodedUserInfo?.name) == Support
                expect(decodedUserInfo?.nickname) == Nickname
                expect(decodedUserInfo?.picture) == PictureURL
                expect(decodedUserInfo?.updatedAt?.timeIntervalSince1970) == UpdatedAtTimestamp
                expect(decodedUserInfo?.customClaims).to(beEmpty())
            }

            it("should build from a object with all properties set except customClaims") {
                let userInfo = UserInfo(sub: Sub,
                                        name: Support,
                                        givenName: GivenName,
                                        familyName: FamilyName,
                                        middleName: MiddleName,
                                        nickname: Nickname,
                                        preferredUsername: PreferredUsername,
                                        profile: ProfileURL,
                                        picture: PictureURL,
                                        website: WebsiteURL,
                                        email: SupportAtAuth0,
                                        emailVerified: true,
                                        gender: Gender,
                                        birthdate: CreatedAt,
                                        zoneinfo: TimeZone(identifier: ZoneEST) ,
                                        locale: Locale(identifier: LocaleUS),
                                        phoneNumber: Auth0Phone,
                                        phoneNumberVerified: true,
                                        address: Auth0Address,
                                        updatedAt: date(from: UpdatedAt),
                                        customClaims: nil)

                let data = try JSONEncoder().encode(userInfo)
                let decodedUserInfo = try? JSONDecoder().decode(UserInfo.self, from: data)

                expect(decodedUserInfo?.sub) == Sub

                expect(decodedUserInfo?.name) == Support
                expect(decodedUserInfo?.givenName) == GivenName
                expect(decodedUserInfo?.familyName) == FamilyName
                expect(decodedUserInfo?.middleName) == MiddleName
                expect(decodedUserInfo?.nickname) == Nickname

                expect(decodedUserInfo?.profile) == ProfileURL
                expect(decodedUserInfo?.picture) == PictureURL
                expect(decodedUserInfo?.website) == WebsiteURL

                expect(decodedUserInfo?.email) == SupportAtAuth0
                expect(decodedUserInfo?.emailVerified).to(be(true))

                expect(decodedUserInfo?.gender) == Gender

                expect(decodedUserInfo?.birthdate) == CreatedAt

                expect(decodedUserInfo?.locale?.identifier) == Locale(identifier: LocaleUS).identifier
                expect(decodedUserInfo?.zoneinfo?.identifier) == TimeZone(identifier: ZoneEST)!.identifier

                expect(decodedUserInfo?.phoneNumber) == Auth0Phone
                expect(decodedUserInfo?.phoneNumberVerified).to(be(true))

                expect(decodedUserInfo?.address) == Auth0Address

                expect(decodedUserInfo?.updatedAt?.timeIntervalSince1970) == UpdatedAtTimestamp
                expect(decodedUserInfo?.customClaims).to(beEmpty())
            }

            it("should build from a object with customClaims of different types") {
                var info = basicProfileOIDC()
                let double = Double(1.2345)
                let customClaims: [String: Any] = [
                    "customClaimString": Support,
                    "customClaimURL": ProfileURL,
                    "customClaimBool": true,
                    "customClaimDouble": double,
                    "customClaimInt": 1
                ]
                customClaims.forEach { key, value in info[key] = value }

                let userInfo = UserInfo(json: info)
                let data = try JSONEncoder().encode(userInfo)
                let decodedUserInfo = try? JSONDecoder().decode(UserInfo.self, from: data)

                expect(decodedUserInfo?.customClaims?.count).to(be(customClaims.count))
                expect(decodedUserInfo?.customClaims?["customClaimString"] as? String) == Support
                if let urlString = decodedUserInfo?.customClaims?["customClaimURL"] as? String,
                   let url = URL(string: urlString) {
                    expect(url) == ProfileURL
                } else {
                    fail("Could not decode customClaimURL of type URL")
                }
                expect(decodedUserInfo?.customClaims?["customClaimBool"] as? Bool) == true
                expect(decodedUserInfo?.customClaims?["customClaimDouble"] as? Double) == double
                expect(decodedUserInfo?.customClaims?["customClaimInt"] as? Int) == 1
            }
        }

        describe("custom claims") {

            it("should build with without custom claims") {
                let userInfo = UserInfo(json: ["sub": Sub])

                let data = try JSONEncoder().encode(userInfo)
                let decodedUserInfo = try? JSONDecoder().decode(UserInfo.self, from: data)

                expect(decodedUserInfo?.customClaims).notTo(be(nil))
                expect(decodedUserInfo?.customClaims!.count) == 0
            }
            
            it("should build with basic profile and two custom claims") {
                var info = basicProfileOIDC()
                let optional: [String: Any] = [
                    "user_list": "user1",
                    "user_active": true
                ]
                optional.forEach { key, value in info[key] = value }

                let userInfo = UserInfo(json: info)
                let data = try JSONEncoder().encode(userInfo)
                let decodedUserInfo = try? JSONDecoder().decode(UserInfo.self, from: data)

                expect(decodedUserInfo?.customClaims?.count) == 2
                expect(decodedUserInfo?.customClaims?["sub"]).to(beNil())
            }
        }
    }
}
