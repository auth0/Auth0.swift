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

private let AccessToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
private let Bearer = "bearer"
private let IdToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
private let RefreshToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")

class CredentialsSpec: QuickSpec {
    override func spec() {

        describe("init from json") {

            it("should return nil when missing access_token") {
                let credentials = Credentials(json: ["token_type": Bearer])
                expect(credentials).to(beNil())
            }

            it("should return nil when missing toke_type") {
                let credentials = Credentials(json: ["access_token": AccessToken])
                expect(credentials).to(beNil())
            }

            it("should have all tokens and token_type") {
                let credentials = Credentials(json: ["access_token": AccessToken, "token_type": Bearer, "id_token": IdToken, "refresh_token": RefreshToken])
                expect(credentials).toNot(beNil())
                expect(credentials?.accessToken) == AccessToken
                expect(credentials?.tokenType) == Bearer
                expect(credentials?.idToken) == IdToken
                expect(credentials?.refreshToken) == RefreshToken
            }

            it("should have only access_token and token_type") {
                let credentials = Credentials(json: ["access_token": AccessToken, "token_type": Bearer])
                expect(credentials).toNot(beNil())
                expect(credentials?.accessToken) == AccessToken
                expect(credentials?.tokenType) == Bearer
                expect(credentials?.idToken).to(beNil())
            }

            it("should have id_token") {
                let credentials = Credentials(json: ["access_token": AccessToken, "token_type": Bearer, "id_token": IdToken])
                expect(credentials?.idToken) == IdToken
            }

            it("should have refresh_token") {
                let credentials = Credentials(json: ["access_token": AccessToken, "token_type": Bearer, "refresh_token": RefreshToken])
                expect(credentials?.refreshToken) == RefreshToken
            }

        }
    }
}
