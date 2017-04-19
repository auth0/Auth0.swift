// CredentialsSpec.swift
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

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let Bearer = "bearer"
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let expiresIn: TimeInterval = 3600

class CredentialsSpec: QuickSpec {
    override func spec() {

        describe("init from json") {

            it("should have all tokens and token_type") {
                let credentials = Credentials(json: ["access_token": AccessToken, "token_type": Bearer, "id_token": IdToken, "refresh_token": RefreshToken, "expires_in" : expiresIn])
                expect(credentials).toNot(beNil())
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.idToken) == IdToken
                expect(credentials.refreshToken) == RefreshToken
                expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
            }

            it("should have only access_token and token_type") {
                let credentials = Credentials(json: ["access_token": AccessToken, "token_type": Bearer])
                expect(credentials).toNot(beNil())
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.idToken).to(beNil())
                expect(credentials.expiresIn).to(beNil())
            }

            it("should have id_token") {
                let credentials = Credentials(json: ["access_token": AccessToken, "token_type": Bearer, "id_token": IdToken])
                expect(credentials.idToken) == IdToken
            }

            it("should have refresh_token") {
                let credentials = Credentials(json: ["access_token": AccessToken, "token_type": Bearer, "refresh_token": RefreshToken])
                expect(credentials.refreshToken) == RefreshToken
            }

            context("expires_in responses") {

                it("should have valid exiresIn from string") {
                    let credentials = Credentials(json: ["expires_in": "3600"])
                    expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
                }

                it("should have valid exiresIn from int") {
                    let credentials = Credentials(json: ["expires_in": 3600])
                    expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
                }

                it("should have valid exiresIn from double") {
                    let credentials = Credentials(json: ["expires_in": 3600.0])
                    expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
                }

                it("should be nil") {
                    let credentials = Credentials(json: ["expires_in": "invalid"])
                    expect(credentials.expiresIn).to(beNil())
                }

                it("should be nil") {
                    let credentials = Credentials(json: ["expires_in": ""])
                    expect(credentials.expiresIn).to(beNil())
                }

            }

        }

        describe("serialization") {

            it("should return base64 string") {
                let credentials = Credentials(json: ["access_token": AccessToken, "token_type": Bearer, "id_token": IdToken, "refresh_token": RefreshToken, "expires_in" : expiresIn])
                let data = credentials.serialize()
                expect(data.characters.count) > 0
            }

            it("shoukld not decode credentials") {
                let aCredentials = Credentials(withSerialized: "garbage")
                expect(aCredentials).to(beNil())
            }


            it("should decode credentials objects") {
                let credentials = Credentials(json: ["access_token": AccessToken, "token_type": Bearer, "id_token": IdToken, "refresh_token": RefreshToken, "expires_in" : expiresIn])
                let data = credentials.serialize()
                let aCredentials = Credentials(withSerialized: data)
                expect(aCredentials).toNot(beNil())
                expect(aCredentials?.accessToken) == AccessToken
                expect(aCredentials?.tokenType).to(beNil())
                expect(aCredentials?.idToken) == IdToken
                expect(aCredentials?.refreshToken) == RefreshToken
                expect(aCredentials?.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
            }

            it("should decode credentials with refreshToken only") {
                let credentials = Credentials(json: ["refresh_token": RefreshToken])
                let data = credentials.serialize()
                let aCredentials = Credentials(withSerialized: data)
                expect(aCredentials?.refreshToken) == RefreshToken
                expect(aCredentials?.accessToken).to(beNil())
                expect(aCredentials?.tokenType).to(beNil())
                expect(aCredentials?.idToken).to(beNil())
                expect(aCredentials?.expiresIn).to(beNil())
            }

            it("should decode credentials with accessToken and expiresIn") {
                let credentials = Credentials(json: ["access_token": AccessToken, "expires_in" : expiresIn])
                let data = credentials.serialize()
                let aCredentials = Credentials(withSerialized: data)
                expect(aCredentials?.accessToken) == AccessToken
                expect(aCredentials?.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
                expect(aCredentials?.refreshToken).to(beNil())
                expect(aCredentials?.tokenType).to(beNil())
                expect(aCredentials?.idToken).to(beNil())
            }

            it("should decode credentials with idToken only") {
                let credentials = Credentials(json: ["id_token": IdToken])
                let data = credentials.serialize()
                let aCredentials = Credentials(withSerialized: data)
                expect(aCredentials?.idToken) == IdToken
                expect(aCredentials?.accessToken).to(beNil())
                expect(aCredentials?.tokenType).to(beNil())
                expect(aCredentials?.refreshToken).to(beNil())
                expect(aCredentials?.expiresIn).to(beNil())
            }

        }
    }
}
