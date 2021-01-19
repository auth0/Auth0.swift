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

import Foundation
import Quick
import Nimble

@testable import Auth0

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let Bearer = "bearer"
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let expiresIn: TimeInterval = 3600
private let Scope = "openid"

class CredentialsSpec: QuickSpec {
    override func spec() {

        describe("init from json") {

            it("should have all tokens and token_type") {
                let credentials = Credentials(json: ["access_token": AccessToken, "token_type": Bearer, "id_token": IdToken, "refresh_token": RefreshToken, "expires_in" : expiresIn, "scope": Scope])
                expect(credentials).toNot(beNil())
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.idToken) == IdToken
                expect(credentials.refreshToken) == RefreshToken
                expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
                expect(credentials.scope) == Scope
            }

            it("should have only access_token and token_type") {
                let credentials = Credentials(json: ["access_token": AccessToken, "token_type": Bearer])
                expect(credentials).toNot(beNil())
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.idToken).to(beNil())
                expect(credentials.expiresIn).to(beNil())
                expect(credentials.scope).to(beNil())
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

                it("should have valid expiresIn from string") {
                    let credentials = Credentials(json: ["expires_in": "3600"])
                    expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
                }

                it("should have valid expiresIn from int") {
                    let credentials = Credentials(json: ["expires_in": 3600])
                    expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
                }

                it("should have valid expiresIn from double") {
                    let credentials = Credentials(json: ["expires_in": 3600.0])
                    expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
                }
                
                it("should have valid expiresIn from Int64") {
                    let credentials = Credentials(json: ["expires_in": Int64(3600)])
                    expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
                }

                it("should have valid expiresIn from float") {
                    let credentials = Credentials(json: ["expires_in": Float(3600.0)])
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

        describe("secure coding") {

            it("should unarchive as credentials type") {
                let credentialsOrig = Credentials(json: ["access_token": AccessToken, "token_type": Bearer, "id_token": IdToken, "refresh_token": RefreshToken, "expires_in" : expiresIn, "scope" : Scope])
                let saveData = NSKeyedArchiver.archivedData(withRootObject: credentialsOrig)
                let credentials = NSKeyedUnarchiver.unarchiveObject(with: saveData)
                expect(credentials as? Credentials).toNot(beNil())
            }

            it("should have all properties") {
                let credentialsOrig = Credentials(json: ["access_token": AccessToken, "token_type": Bearer, "id_token": IdToken, "refresh_token": RefreshToken, "expires_in" : expiresIn, "scope" : Scope])
                let saveData = NSKeyedArchiver.archivedData(withRootObject: credentialsOrig)
                let credentials = NSKeyedUnarchiver.unarchiveObject(with: saveData) as! Credentials
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType) == Bearer
                expect(credentials.idToken) == IdToken
                expect(credentials.scope) == Scope
                expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
            }

            it("should have access_token only") {
                let credentialsOrig = Credentials(json: ["access_token": AccessToken])
                let saveData = NSKeyedArchiver.archivedData(withRootObject: credentialsOrig)
                let credentials = NSKeyedUnarchiver.unarchiveObject(with: saveData) as! Credentials
                expect(credentials.accessToken) == AccessToken
                expect(credentials.tokenType).to(beNil())
                expect(credentials.idToken).to(beNil())
                expect(credentials.expiresIn).to(beNil())
                expect(credentials.scope).to(beNil())
            }

            it("should have refresh_token and expires_in only") {
                let credentialsOrig = Credentials(json: ["refresh_token": RefreshToken, "expires_in" : expiresIn])
                let saveData = NSKeyedArchiver.archivedData(withRootObject: credentialsOrig)
                let credentials = NSKeyedUnarchiver.unarchiveObject(with: saveData) as! Credentials
                expect(credentials.accessToken).to(beNil())
                expect(credentials.refreshToken) == RefreshToken
                expect(credentials.tokenType).to(beNil())
                expect(credentials.idToken).to(beNil())
                expect(credentials.expiresIn).to(beCloseTo(Date(timeIntervalSinceNow: expiresIn), within: 5))
                expect(credentials.scope).to(beNil())
            }

        }
    }
}
