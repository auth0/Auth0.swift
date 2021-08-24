//
//  UserInfo+Equatable.swift
//  Auth0
//
//  Created by Kimi on 24/8/21.
//  Copyright © 2021 Auth0. All rights reserved.
//

import Foundation
import Quick
import Nimble
import JWTDecode

@testable import Auth0

class UserInfoEquatableSpec: QuickSpec {
    override func spec() {

        describe("compare UserInfo instances") {
            it("should be equal if they have only the same sub") {
                let userInfo1 = UserInfo(json: ["sub": Sub])!
                let userInfo2 = UserInfo(json: ["sub": Sub])!

                expect(userInfo1.sub) == Sub
                expect(userInfo2.sub) == Sub

                expect(userInfo1 == userInfo2).to(beTrue())
            }
            
            it("should not be equal if they have different subs") {
                let anotherSub = "Another Sub"
                let userInfo1 = UserInfo(json: ["sub": Sub])!
                let userInfo2 = UserInfo(json: ["sub": anotherSub])!

                expect(userInfo1.sub) == Sub
                expect(userInfo2.sub) == anotherSub

                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should be equal if they have the same name") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "name": GivenName])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "name": GivenName])!

                expect(userInfo1.name) == GivenName
                expect(userInfo2.name) == GivenName
                
                expect(userInfo1 == userInfo2).to(beTrue())
            }
            
            it("should not be equal if they have the different name") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "name": Sub])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "name": GivenName])!

                expect(userInfo1.name) == Sub
                expect(userInfo2.name) == GivenName
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different given name") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "given_name": Sub])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "given_name": GivenName])!

                expect(userInfo1.givenName) == Sub
                expect(userInfo2.givenName) == GivenName
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different middle name") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "middle_name": Sub])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "middle_name": MiddleName])!

                expect(userInfo1.middleName) == Sub
                expect(userInfo2.middleName) == MiddleName
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different family name") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "family_name": Sub])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "family_name": FamilyName])!

                expect(userInfo1.familyName) == Sub
                expect(userInfo2.familyName) == FamilyName
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should be equal if they have the same family name") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "family_name": FamilyName])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "family_name": FamilyName])!

                expect(userInfo1.familyName) == FamilyName
                expect(userInfo2.familyName) == FamilyName
                
                expect(userInfo1 == userInfo2).to(beTrue())
            }
            
            it("should not be equal if they have different nick name") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "nickname": Sub])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "nickname": Nickname])!

                expect(userInfo1.nickname) == Sub
                expect(userInfo2.nickname) == Nickname
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different preferred name") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "preferred_username": Sub])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "preferred_username": PreferredUsername])!

                expect(userInfo1.preferredUsername) == Sub
                expect(userInfo2.preferredUsername) == PreferredUsername
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different profile urls") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "profile": WebsiteURL.absoluteString])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "profile": ProfileURL.absoluteString])!

                expect(userInfo1.profile) == WebsiteURL
                expect(userInfo2.profile) == ProfileURL
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different website urls") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "website": WebsiteURL.absoluteString])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "website": ProfileURL.absoluteString])!

                expect(userInfo1.website) == WebsiteURL
                expect(userInfo2.website) == ProfileURL
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different picture urls") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "picture": WebsiteURL.absoluteString])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "picture": PictureURL.absoluteString])!

                expect(userInfo1.picture) == WebsiteURL
                expect(userInfo2.picture) == PictureURL
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different emails") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "email": Sub])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "email": SupportAtAuth0])!

                expect(userInfo1.email) == Sub
                expect(userInfo2.email) == SupportAtAuth0
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different email verification status") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "email": SupportAtAuth0, "email_verified": true])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "email": SupportAtAuth0, "email_verified": false])!

                expect(userInfo1.email) == SupportAtAuth0
                expect(userInfo2.email) == SupportAtAuth0
                
                expect(userInfo1.emailVerified) == true
                expect(userInfo2.emailVerified) == false
                                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different gender") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "gender": Gender])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "gender": Sub])!

                expect(userInfo1.gender) == Gender
                expect(userInfo2.gender) == Sub
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            
            it("should not be equal if they have different birthdate") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "birthdate": UpdatedAt])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "birthdate": "2021-08-11T17:18:00.000Z"])!

                expect(userInfo1.birthdate) == UpdatedAt
                expect(userInfo2.birthdate) == "2021-08-11T17:18:00.000Z"
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have Zone Info") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "zoneinfo": ZoneEST])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "zoneinfo": "Europe/Stockholm"])!

                expect(userInfo1.zoneinfo) == TimeZone(identifier: ZoneEST)
                expect(userInfo2.zoneinfo) == TimeZone(identifier: "Europe/Stockholm")
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different locale") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "locale": LocaleUS])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "locale": "ES-es"])!

                expect(userInfo1.locale) == Locale.init(identifier: LocaleUS)
                expect(userInfo2.locale) == Locale.init(identifier: "ES-es")
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }

            it("should not be equal if they have different phone number") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "phone_number": Auth0Phone])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "phone_number": Sub])!

                expect(userInfo1.phoneNumber) == Auth0Phone
                expect(userInfo2.phoneNumber) == Sub
                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different phone number verification status") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "phone_number": Auth0Phone, "phone_number_verified": true])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "phone_number": Auth0Phone, "phone_number_verified": false])!

                expect(userInfo1.phoneNumber) == Auth0Phone
                expect(userInfo2.phoneNumber) == Auth0Phone
                
                expect(userInfo1.phoneNumberVerified) == true
                expect(userInfo2.phoneNumberVerified) == false
                                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different updated date") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "updated_at": UpdatedAt])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "updated_at": "2021-08-11T17:18:00.000Z"])!

                expect(userInfo1.updatedAt) == date(from: UpdatedAt)
                expect(userInfo2.updatedAt) == date(from: "2021-08-11T17:18:00.000Z")
                                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have different address") {
                let userInfo1 = UserInfo(json: ["sub": Sub, "address": Auth0Address])!
                let userInfo2 = UserInfo(json: ["sub": Sub, "address": ["country": "AR"]])!

                expect(userInfo1.address) == Auth0Address
                expect(userInfo2.address) == ["country": "AR"]
                                
                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should be equal after encoding and decoding them") {
                let userInfo1 = UserInfo(json: ["sub": Sub])
                let dataUserInfo1 = try JSONEncoder().encode(userInfo1)
                let decodedUserInfo1 = try! JSONDecoder().decode(UserInfo.self, from: dataUserInfo1)

                let userInfo2 = UserInfo(json: ["sub": Sub])
                let dataUserInfo2 = try JSONEncoder().encode(userInfo2)
                let decodedUserInfo2 = try! JSONDecoder().decode(UserInfo.self, from: dataUserInfo2)

                expect(decodedUserInfo1.sub) == Sub
                expect(decodedUserInfo2.sub) == Sub

                expect(decodedUserInfo1 == decodedUserInfo2).to(beTrue())
            }

            it("should be equal if they have the same claims") {
                let userInfo1 = UserInfo(sub: Sub,
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
                                        customClaims: ["key1": true, "key2": 10, "key3": "value3"])

                let userInfo2 = UserInfo(sub: Sub,
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
                                         customClaims: ["key1": true, "key2": 10, "key3": "value3"])

                expect(userInfo1 == userInfo2).to(beTrue())
            }

            it("should not be equal if they have the different custom claims") {
                let userInfo1 = UserInfo(sub: Sub,
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
                                        customClaims: ["key1": true, "key2": 10, "key3": "value3"])

                let userInfo2 = UserInfo(sub: Sub,
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
                                         customClaims: ["key1": false, "key2": 0, "key3": "value3"])

                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal if they have the different custom claims count") {
                let userInfo1 = UserInfo(sub: Sub,
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
                                        customClaims: ["key1": true, "key2": 10])

                let userInfo2 = UserInfo(sub: Sub,
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
                                         customClaims: ["key1": false, "key2": 0, "key3": "value3"])

                expect(userInfo1 == userInfo2).to(beFalse())
            }

            it("should not be equal if they have the same Subject but different claims") {
                let userInfo1 = UserInfo(sub: Sub,
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
                                        customClaims: ["key1": true, "key2": 10, "key3": "value3"])

                let userInfo2 = UserInfo(json: ["sub": Sub])!

                expect(userInfo1 == userInfo2).to(beFalse())
            }

            it("should be equal even if right reference is Optional") {
                let userInfo1 = UserInfo(json: ["sub": Sub])!
                let userInfo2 = UserInfo(json: ["sub": Sub])

                expect(userInfo1 == userInfo2).to(beTrue())
            }
            
            it("should be equal even if left reference is Optional") {
                let userInfo1 = UserInfo(json: ["sub": Sub])
                let userInfo2 = UserInfo(json: ["sub": Sub])!

                expect(userInfo1 == userInfo2).to(beTrue())
            }
            
            it("should not be equal even if right reference is nil") {
                let userInfo1 = UserInfo(json: ["sub": Sub])!
                let userInfo2: UserInfo? = nil

                expect(userInfo1 == userInfo2).to(beFalse())
            }
            
            it("should not be equal even if left reference is nil") {
                let userInfo1: UserInfo? = nil
                let userInfo2 = UserInfo(json: ["sub": Sub])!

                expect(userInfo1 == userInfo2).to(beFalse())
            }
        }
    }
}
