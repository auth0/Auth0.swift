// UserPatchAttributesSpec.swift
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

private let ClientId = "CLIENT_ID"
private let Connection = "MyConnection"
private let Password = "PASSWORD RANDOM"

class UserPatchAttributesSpec: QuickSpec {

    override func spec() {
        var attributes: UserPatchAttributes!

        beforeEach {
            attributes = UserPatchAttributes()
        }

        it("allows patch of blocked flag") {
            expect(attributes.blocked(true).dictionary["blocked"] as? Bool) == true
        }

        it("allows patch of email") {
            attributes.email(SupportAtAuth0, connection: Connection, clientId: ClientId)
            expect(attributes.dictionary["email"] as? String) == SupportAtAuth0
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["client_id"] as? String) == ClientId
            expect(attributes.dictionary["verify_email"]).to(beNil())
            expect(attributes.dictionary["email_verified"]).to(beNil())
        }

        it("allows patch of email & verification status") {
            attributes.email(SupportAtAuth0, verified: true, connection: Connection, clientId: ClientId)
            expect(attributes.dictionary["email"] as? String) == SupportAtAuth0
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["client_id"] as? String) == ClientId
            expect(attributes.dictionary["verify_email"]).to(beNil())
            expect(attributes.dictionary["email_verified"] as? Bool) == true
        }

        it("allows patch of email & send verification email") {
            attributes.email(SupportAtAuth0, verify: true, connection: Connection, clientId: ClientId)
            expect(attributes.dictionary["email"] as? String) == SupportAtAuth0
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["client_id"] as? String) == ClientId
            expect(attributes.dictionary["verify_email"] as? Bool) == true
            expect(attributes.dictionary["email_verified"]).to(beNil())
        }

        it("allows patch of email verification status") {
            attributes.emailVerified(true, connection: Connection)
            expect(attributes.dictionary["email_verified"] as? Bool) == true
            expect(attributes.dictionary["connection"] as? String) == Connection
        }

        it("allows patch of phone") {
            attributes.phoneNumber(Auth0Phone, connection: Connection, clientId: ClientId)
            expect(attributes.dictionary["phone_number"] as? String) == Auth0Phone
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["client_id"] as? String) == ClientId
            expect(attributes.dictionary["verify_phone_number"]).to(beNil())
            expect(attributes.dictionary["phone_verified"]).to(beNil())
        }

        it("allows patch of phone & verification status") {
            attributes.phoneNumber(Auth0Phone, verified: true, connection: Connection, clientId: ClientId)
            expect(attributes.dictionary["phone_number"] as? String) == Auth0Phone
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["client_id"] as? String) == ClientId
            expect(attributes.dictionary["verify_phone_number"]).to(beNil())
            expect(attributes.dictionary["phone_verified"] as? Bool) == true
        }

        it("allows patch of phone & send verification message") {
            attributes.phoneNumber(Auth0Phone, verify: true, connection: Connection, clientId: ClientId)
            expect(attributes.dictionary["phone_number"] as? String) == Auth0Phone
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["client_id"] as? String) == ClientId
            expect(attributes.dictionary["verify_phone_number"] as? Bool) == true
            expect(attributes.dictionary["phone_verified"]).to(beNil())
        }

        it("allows patch of phone verification status") {
            attributes.phoneVerified(true, connection: Connection)
            expect(attributes.dictionary["phone_verified"] as? Bool) == true
            expect(attributes.dictionary["connection"] as? String) == Connection
        }

        it("allows patch of password") {
            attributes.password(Password, connection: Connection)
            expect(attributes.dictionary["password"] as? String) == Password
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["verify_password"]).to(beNil())
        }

        it("allows patch of password and send verification message") {
            attributes.password(Password, verify: true, connection: Connection)
            expect(attributes.dictionary["password"] as? String) == Password
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["verify_password"] as? Bool) == true
        }

        it("allows patch of username") {
            attributes.username(Support, connection: Connection)
            expect(attributes.dictionary["username"] as? String) == Support
            expect(attributes.dictionary["connection"] as? String) == Connection
        }

        it("should allow path of user metadata") {
            attributes.userMetadata(["key": "value"])
            expect((attributes.dictionary["user_metadata"] as? [String: String])?.keys).to(contain("key"))
            expect((attributes.dictionary["user_metadata"] as? [String: String])?.values).to(contain("value"))
        }

        it("should allow path of app metadata") {
            attributes.appMetadata(["key": "value"])
            expect((attributes.dictionary["app_metadata"] as? [String: String])?.keys).to(contain("key"))
            expect((attributes.dictionary["app_metadata"] as? [String: String])?.values).to(contain("value"))
        }

    }
}
