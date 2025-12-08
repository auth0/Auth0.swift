import Foundation
import Quick
import Nimble

@testable import Auth0

class SensitiveDataRedactorSpec: QuickSpec {
    
    override class func spec() {
        
        describe("SensitiveDataRedactor") {
            
            context("redact()") {
                
                it("should redact access_token") {
                    let json = """
                    {
                        "access_token": "secret_access_token_value",
                        "token_type": "Bearer",
                        "expires_in": 86400
                    }
                    """
                    let data = json.data(using: .utf8)!
                    
                    let result = SensitiveDataRedactor.redact(data)
                    
                    expect(result).toNot(beNil())
                    expect(result).to(contain("<REDACTED>"))
                    expect(result).toNot(contain("secret_access_token_value"))
                    expect(result).to(contain("token_type"))
                    expect(result).to(contain("expires_in"))
                }
                
                it("should redact id_token") {
                    let json = """
                    {
                        "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature",
                        "token_type": "Bearer"
                    }
                    """
                    let data = json.data(using: .utf8)!
                    
                    let result = SensitiveDataRedactor.redact(data)
                    
                    expect(result).toNot(beNil())
                    expect(result).to(contain("<REDACTED>"))
                    expect(result).toNot(contain("eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9"))
                }
                
                it("should redact refresh_token") {
                    let json = """
                    {
                        "access_token": "access_value",
                        "refresh_token": "refresh_value"
                    }
                    """
                    let data = json.data(using: .utf8)!
                    
                    let result = SensitiveDataRedactor.redact(data)
                    
                    expect(result).toNot(beNil())
                    expect(result).to(contain("<REDACTED>"))
                    expect(result).toNot(contain("access_value"))
                    expect(result).toNot(contain("refresh_value"))
                }
                
                it("should redact multiple sensitive fields") {
                    let json = """
                    {
                        "access_token": "at_123",
                        "id_token": "it_456",
                        "refresh_token": "rt_789",
                        "scope": "openid profile email"
                    }
                    """
                    let data = json.data(using: .utf8)!
                    
                    let result = SensitiveDataRedactor.redact(data)
                    
                    expect(result).toNot(beNil())
                    expect(result).to(contain("<REDACTED>"))
                    expect(result).toNot(contain("at_123"))
                    expect(result).toNot(contain("it_456"))
                    expect(result).toNot(contain("rt_789"))
                    expect(result).to(contain("scope"))
                    expect(result).to(contain("openid profile email"))
                }
                
                it("should preserve non-sensitive fields") {
                    let json = """
                    {
                        "user_id": "auth0|123456",
                        "email": "user@example.com",
                        "access_token": "secret"
                    }
                    """
                    let data = json.data(using: .utf8)!
                    
                    let result = SensitiveDataRedactor.redact(data)
                    
                    expect(result).toNot(beNil())
                    expect(result).to(contain("user_id"))
                    expect(result).to(contain("auth0|123456"))
                    expect(result).to(contain("email"))
                    expect(result).to(contain("user@example.com"))
                    expect(result).toNot(contain("secret"))
                }
                
                it("should return non-JSON String for non-JSON data") {
                    let plainText = "This is not JSON"
                    let data = plainText.data(using: .utf8)!
                    
                    let result = SensitiveDataRedactor.redact(data)
                    
                    expect(result).to(contain(plainText))
                }
                
                it("should handle empty JSON") {
                    let json = "{}"
                    let data = json.data(using: .utf8)!
                    
                    let result = SensitiveDataRedactor.redact(data)
                    
                    expect(result).toNot(beNil())
                    let expectedJson = try! JSONSerialization.data(withJSONObject: [:], options: [.prettyPrinted])
                    let expected = String(data: expectedJson, encoding: .utf8)!
                    expect(result).to(equal(expected))
                }
                
                it("should handle JSON with no sensitive fields") {
                    let json = """
                    {
                        "username": "john",
                        "age": 30
                    }
                    """
                    let data = json.data(using: .utf8)!
                    
                    let result = SensitiveDataRedactor.redact(data)
                    
                    expect(result).toNot(beNil())
                    expect(result).to(contain("username"))
                    expect(result).to(contain("john"))
                    expect(result).to(contain("age"))
                    expect(result).toNot(contain("<REDACTED>"))
                }
            }
        }
    }
}
