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
            let _ = attributes.email(SupportAtAuth0, connection: Connection, clientId: ClientId)
            expect(attributes.dictionary["email"] as? String) == SupportAtAuth0
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["client_id"] as? String) == ClientId
            expect(attributes.dictionary["verify_email"]).to(beNil())
            expect(attributes.dictionary["email_verified"]).to(beNil())
        }

        it("allows patch of email & verification status") {
            let _ = attributes.email(SupportAtAuth0, verified: true, connection: Connection, clientId: ClientId)
            expect(attributes.dictionary["email"] as? String) == SupportAtAuth0
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["client_id"] as? String) == ClientId
            expect(attributes.dictionary["verify_email"]).to(beNil())
            expect(attributes.dictionary["email_verified"] as? Bool) == true
        }

        it("allows patch of email & send verification email") {
            let _ = attributes.email(SupportAtAuth0, verify: true, connection: Connection, clientId: ClientId)
            expect(attributes.dictionary["email"] as? String) == SupportAtAuth0
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["client_id"] as? String) == ClientId
            expect(attributes.dictionary["verify_email"] as? Bool) == true
            expect(attributes.dictionary["email_verified"]).to(beNil())
        }

        it("allows patch of email verification status") {
            let _ = attributes.emailVerified(true, connection: Connection)
            expect(attributes.dictionary["email_verified"] as? Bool) == true
            expect(attributes.dictionary["connection"] as? String) == Connection
        }

        it("allows patch of phone") {
            let _ = attributes.phoneNumber(Auth0Phone, connection: Connection, clientId: ClientId)
            expect(attributes.dictionary["phone_number"] as? String) == Auth0Phone
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["client_id"] as? String) == ClientId
            expect(attributes.dictionary["verify_phone_number"]).to(beNil())
            expect(attributes.dictionary["phone_verified"]).to(beNil())
        }

        it("allows patch of phone & verification status") {
            let _ = attributes.phoneNumber(Auth0Phone, verified: true, connection: Connection, clientId: ClientId)
            expect(attributes.dictionary["phone_number"] as? String) == Auth0Phone
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["client_id"] as? String) == ClientId
            expect(attributes.dictionary["verify_phone_number"]).to(beNil())
            expect(attributes.dictionary["phone_verified"] as? Bool) == true
        }

        it("allows patch of phone & send verification message") {
            let _ = attributes.phoneNumber(Auth0Phone, verify: true, connection: Connection, clientId: ClientId)
            expect(attributes.dictionary["phone_number"] as? String) == Auth0Phone
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["client_id"] as? String) == ClientId
            expect(attributes.dictionary["verify_phone_number"] as? Bool) == true
            expect(attributes.dictionary["phone_verified"]).to(beNil())
        }

        it("allows patch of phone verification status") {
            let _ = attributes.phoneVerified(true, connection: Connection)
            expect(attributes.dictionary["phone_verified"] as? Bool) == true
            expect(attributes.dictionary["connection"] as? String) == Connection
        }

        it("allows patch of password") {
            let _ = attributes.password(Password, connection: Connection)
            expect(attributes.dictionary["password"] as? String) == Password
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["verify_password"]).to(beNil())
        }

        it("allows patch of password and send verification message") {
            let _ = attributes.password(Password, verify: true, connection: Connection)
            expect(attributes.dictionary["password"] as? String) == Password
            expect(attributes.dictionary["connection"] as? String) == Connection
            expect(attributes.dictionary["verify_password"] as? Bool) == true
        }

        it("allows patch of username") {
            let _ = attributes.username(Support, connection: Connection)
            expect(attributes.dictionary["username"] as? String) == Support
            expect(attributes.dictionary["connection"] as? String) == Connection
        }

        it("should allow path of user metadata") {
            let _ = attributes.userMetadata(["key": "value"])
            expect((attributes.dictionary["user_metadata"] as? [String: String])?.keys.first).to(contain("key"))
            expect((attributes.dictionary["user_metadata"] as? [String: String])?.values.first).to(contain("value"))
        }

        it("should allow path of app metadata") {
            let _ = attributes.appMetadata(["key": "value"])
            expect((attributes.dictionary["app_metadata"] as? [String: String])?.keys.first).to(contain("key"))
            expect((attributes.dictionary["app_metadata"] as? [String: String])?.values.first).to(contain("value"))
        }

    }
}
