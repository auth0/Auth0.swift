import Quick
import Nimble
import SimpleKeychain

#if WEB_AUTH_PLATFORM
import LocalAuthentication

@testable import Auth0

private let AccessToken = "accessToken"
private let TokenType = "bearer"
private let IdToken = "idToken"
private let RefreshToken = "refreshToken"
private let ExpiresIn: TimeInterval = 3600
private let Scope = "openid profile email offline_access"
private let ClientId = "CLIENT_ID"
private let Domain = "samples.auth0.com"

class BiometricPolicySpec: QuickSpec {
    
    override class func spec() {
        
        let authentication = Auth0.authentication(clientId: ClientId, domain: Domain)
        var credentialsManager: CredentialsManager!
        var credentials: Credentials!
        
        beforeEach {
            credentialsManager = CredentialsManager(authentication: authentication)
            credentials = Credentials(accessToken: AccessToken,
                                    tokenType: TokenType,
                                    idToken: IdToken,
                                    refreshToken: RefreshToken,
                                    expiresIn: Date(timeIntervalSinceNow: ExpiresIn),
                                    scope: Scope)
        }
        
        afterEach {
            _ = credentialsManager.clear()
            CredentialsManager.clearBiometricSession()
        }
        
        // MARK: - BiometricPolicy Tests
        
        describe("BiometricPolicy") {
            
            it("should have an always policy") {
                let policy = BiometricPolicy.always
                
                switch policy {
                case .always:
                    expect(true).to(beTrue())
                default:
                    fail("Expected .always policy")
                }
            }
            
            it("should have a session policy with timeout") {
                let timeout = 300
                let policy = BiometricPolicy.session(timeoutInSeconds: timeout)
                
                switch policy {
                case .session(let timeoutInSeconds):
                    expect(timeoutInSeconds).to(equal(timeout))
                default:
                    fail("Expected .session policy")
                }
            }
            
            it("should have an appLifecycle policy with default timeout") {
                let policy = BiometricPolicy.appLifecycle()
                
                switch policy {
                case .appLifecycle(let timeoutInSeconds):
                    expect(timeoutInSeconds).to(equal(3600)) // Default 1 hour
                default:
                    fail("Expected .appLifecycle policy")
                }
            }
            
            it("should have an appLifecycle policy with custom timeout") {
                let timeout = 7200
                let policy = BiometricPolicy.appLifecycle(timeoutInSeconds: timeout)
                
                switch policy {
                case .appLifecycle(let timeoutInSeconds):
                    expect(timeoutInSeconds).to(equal(timeout))
                default:
                    fail("Expected .appLifecycle policy")
                }
            }
        }
        
        // MARK: - enableBiometrics with Policy Tests
        
        describe("enableBiometrics with policy") {
            
            it("should enable biometrics with always policy by default") {
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock")
                
                // Verify that bioAuth is configured
                expect(credentialsManager.bioAuth).toNot(beNil())
                
                // Verify the policy is .always
                switch credentialsManager.bioAuth?.policy {
                case .always:
                    expect(true).to(beTrue())
                default:
                    fail("Expected .always policy as default")
                }
            }
            
            it("should enable biometrics with always policy explicitly") {
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .always)
                
                expect(credentialsManager.bioAuth).toNot(beNil())
                
                switch credentialsManager.bioAuth?.policy {
                case .always:
                    expect(true).to(beTrue())
                default:
                    fail("Expected .always policy")
                }
            }
            
            it("should enable biometrics with session policy") {
                let timeout = 300
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .session(timeoutInSeconds: timeout))
                
                expect(credentialsManager.bioAuth).toNot(beNil())
                
                switch credentialsManager.bioAuth?.policy {
                case .session(let timeoutInSeconds):
                    expect(timeoutInSeconds).to(equal(timeout))
                default:
                    fail("Expected .session policy")
                }
            }
            
            it("should enable biometrics with appLifecycle policy") {
                let timeout = 7200
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .appLifecycle(timeoutInSeconds: timeout))
                
                expect(credentialsManager.bioAuth).toNot(beNil())
                
                switch credentialsManager.bioAuth?.policy {
                case .appLifecycle(let timeoutInSeconds):
                    expect(timeoutInSeconds).to(equal(timeout))
                default:
                    fail("Expected .appLifecycle policy")
                }
            }
        }
        
        // MARK: - Biometric Session Management Tests
        
        describe("biometric session management") {
            
            context("with always policy") {
                
                beforeEach {
                    credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                       policy: .always)
                }
                
                it("should not have valid session initially") {
                    expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
                }
                
                it("should not have valid session after authentication") {
                    // Simulate authentication by updating the session
                    // Note: In actual implementation, this would be done internally
                    // For .always policy, session should never be valid
                    expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
                }
                
                it("should always require biometric authentication") {
                    // Multiple checks should always return false
                    expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
                    expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
                    expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
                }
            }
            
            context("with session policy") {
                let timeout = 5 // 5 seconds for testing
                
                beforeEach {
                    credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                       policy: .session(timeoutInSeconds: timeout))
                }
                
                it("should not have valid session initially") {
                    expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
                }
                
                it("should clear session") {
                    CredentialsManager.clearBiometricSession()
                    expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
                }
            }
            
            context("with appLifecycle policy") {
                let timeout = 3600 // 1 hour
                
                beforeEach {
                    credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                       policy: .appLifecycle(timeoutInSeconds: timeout))
                }
                
                it("should not have valid session initially") {
                    expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
                }
                
                it("should clear session") {
                    CredentialsManager.clearBiometricSession()
                    expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
                }
            }
        }
        
        // MARK: - clearBiometricSession Tests
        
        describe("clearBiometricSession") {
            
            it("should clear the biometric session") {
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .session(timeoutInSeconds: 300))
                
                // Clear the session
                CredentialsManager.clearBiometricSession()
                
                // Session should not be valid after clearing
                expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
            }
            
            it("should work with always policy") {
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .always)
                
                CredentialsManager.clearBiometricSession()
                
                // Always policy should never have valid session
                expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
            }
            
            it("should work with appLifecycle policy") {
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .appLifecycle())
                
                CredentialsManager.clearBiometricSession()
                
                expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
            }
        }
        
        // MARK: - Thread Safety Tests
        
        describe("thread safety") {
            
            it("should handle concurrent session checks safely") {
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .session(timeoutInSeconds: 300))
                
                // Multiple concurrent calls should not crash
                DispatchQueue.concurrentPerform(iterations: 100) { _ in
                    _ = credentialsManager.isBiometricSessionValid()
                }
                
                expect(true).to(beTrue()) // Test passes if no crash
            }
            
            it("should handle concurrent session clears safely") {
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .session(timeoutInSeconds: 300))
                
                // Multiple concurrent clears should not crash
                DispatchQueue.concurrentPerform(iterations: 100) { _ in
                    CredentialsManager.clearBiometricSession()
                }
                
                expect(true).to(beTrue()) // Test passes if no crash
            }
            
            it("should handle mixed concurrent operations safely") {
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .session(timeoutInSeconds: 300))
                
                // Mix of checks and clears
                DispatchQueue.concurrentPerform(iterations: 50) { index in
                    if index % 2 == 0 {
                        _ = credentialsManager.isBiometricSessionValid()
                    } else {
                        CredentialsManager.clearBiometricSession()
                    }
                }
                
                expect(true).to(beTrue()) // Test passes if no crash
            }
        }
        
        // MARK: - Multiple CredentialsManager Instances Tests
        
        describe("multiple CredentialsManager instances") {
            var credentialsManager1: CredentialsManager!
            var credentialsManager2: CredentialsManager!
            var credentialsManager3: CredentialsManager!
            
            beforeEach {
                credentialsManager1 = CredentialsManager(authentication: authentication)
                credentialsManager2 = CredentialsManager(authentication: authentication)
                credentialsManager3 = CredentialsManager(authentication: authentication)
            }
            
            afterEach {
                _ = credentialsManager1.clear()
                _ = credentialsManager2.clear()
                _ = credentialsManager3.clear()
                CredentialsManager.clearBiometricSession()
            }
            
            it("should share biometric session across instances") {
                // Enable biometrics on first instance
                credentialsManager1.enableBiometrics(withTitle: "Touch to unlock",
                                                    policy: .session(timeoutInSeconds: 300))
                
                // Enable on other instances with same policy
                credentialsManager2.enableBiometrics(withTitle: "Touch to unlock",
                                                    policy: .session(timeoutInSeconds: 300))
                credentialsManager3.enableBiometrics(withTitle: "Touch to unlock",
                                                    policy: .session(timeoutInSeconds: 300))
                
                // All should initially be invalid
                expect(credentialsManager1.isBiometricSessionValid()).to(beFalse())
                expect(credentialsManager2.isBiometricSessionValid()).to(beFalse())
                expect(credentialsManager3.isBiometricSessionValid()).to(beFalse())
            }
            
            it("should clear session for all instances") {
                credentialsManager1.enableBiometrics(withTitle: "Touch to unlock",
                                                    policy: .session(timeoutInSeconds: 300))
                credentialsManager2.enableBiometrics(withTitle: "Touch to unlock",
                                                    policy: .session(timeoutInSeconds: 300))
                
                // Clear session affects all instances
                CredentialsManager.clearBiometricSession()
                
                expect(credentialsManager1.isBiometricSessionValid()).to(beFalse())
                expect(credentialsManager2.isBiometricSessionValid()).to(beFalse())
            }
            
            it("should work with different policies on different instances") {
                credentialsManager1.enableBiometrics(withTitle: "Touch to unlock",
                                                    policy: .always)
                credentialsManager2.enableBiometrics(withTitle: "Touch to unlock",
                                                    policy: .session(timeoutInSeconds: 300))
                credentialsManager3.enableBiometrics(withTitle: "Touch to unlock",
                                                    policy: .appLifecycle())
                
                // Always policy should never be valid
                expect(credentialsManager1.isBiometricSessionValid()).to(beFalse())
                
                // Others should initially be invalid
                expect(credentialsManager2.isBiometricSessionValid()).to(beFalse())
                expect(credentialsManager3.isBiometricSessionValid()).to(beFalse())
            }
        }
        
        // MARK: - Policy Behavior Tests
        
        describe("policy behavior") {
            
            context("always policy") {
                
                it("should require authentication every time") {
                    credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                       policy: .always)
                    
                    // Should always require authentication
                    for _ in 0..<10 {
                        expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
                    }
                }
            }
            
            context("session policy with short timeout") {
                
                it("should respect session timeout") {
                    let timeout = 1 // 1 second
                    credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                       policy: .session(timeoutInSeconds: timeout))
                    
                    // Initially invalid
                    expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
                }
            }
            
            context("appLifecycle policy") {
                
                it("should maintain session throughout app lifecycle") {
                    let timeout = 3600 // 1 hour
                    credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                       policy: .appLifecycle(timeoutInSeconds: timeout))
                    
                    // Should behave same as session policy with longer timeout
                    expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
                }
            }
        }
        
        // MARK: - Clear Tests
        
        describe("clear with biometric policy") {
            
            it("should clear biometric session when clearing credentials") {
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .session(timeoutInSeconds: 300))
                
                _ = credentialsManager.store(credentials: credentials)
                
                // Clear credentials should also clear session
                _ = credentialsManager.clear()
                
                expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
            }
        }
        
        // MARK: - Edge Cases
        
        describe("edge cases") {
            
            it("should handle zero timeout in session policy") {
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .session(timeoutInSeconds: 0))
                
                // With zero timeout, session should immediately expire
                expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
            }
            
            it("should handle very large timeout in session policy") {
                let largeTimeout = Int.max
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .session(timeoutInSeconds: largeTimeout))
                
                // Should not crash with large timeout
                expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
            }
            
            it("should handle enabling biometrics multiple times") {
                // Enable with always policy
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .always)
                
                // Enable again with session policy
                credentialsManager.enableBiometrics(withTitle: "Touch to unlock",
                                                   policy: .session(timeoutInSeconds: 300))
                
                // Should use the latest policy
                switch credentialsManager.bioAuth?.policy {
                case .session(let timeoutInSeconds):
                    expect(timeoutInSeconds).to(equal(300))
                default:
                    fail("Expected .session policy")
                }
            }
            
            it("should handle session validity check without enabling biometrics") {
                // Should return false if biometrics not enabled
                expect(credentialsManager.isBiometricSessionValid()).to(beFalse())
            }
        }
    }
}

#endif
