import Quick
import Nimble
import LocalAuthentication

@testable import Auth0

class BioAuthenticationSpec: QuickSpec {

    override func spec() {
        var evaluationPolicy: LAPolicy!
        var mockContext: MockLAContext!
        var bioAuthentication: BioAuthentication!

        beforeEach {
            evaluationPolicy = .deviceOwnerAuthenticationWithBiometrics
            mockContext = MockLAContext()
            bioAuthentication = BioAuthentication(authContext: mockContext, evaluationPolicy: evaluationPolicy, title: "Touch Auth")
        }

        describe("touch availablility") {

            it("touch should be enabled") {
                expect(bioAuthentication.available).to(beTrue())
            }

            it("touch should be disabled") {
                mockContext.enabled = false
                expect(bioAuthentication.available).to(beFalse())
            }
            
            it("touch should check passed evaluate policy") {
                _ = bioAuthentication.available
                expect(mockContext.canEvaluatePolicyReceivedPolicy).to(equal(evaluationPolicy))
            }

        }

        describe("getters") {

            it("should set cancel title") {
                mockContext.localizedCancelTitle = "cancel title"
                expect(bioAuthentication.cancelTitle) == "cancel title"
            }

            it("should set fallback title") {
                mockContext.localizedFallbackTitle = "fallback title"
                expect(bioAuthentication.fallbackTitle) == "fallback title"
            }

        }

        describe("setters") {

            it("should set cancel title") {
                bioAuthentication.cancelTitle = "cancel title"
                expect(mockContext.localizedCancelTitle) == "cancel title"
            }

            it("should set fallback title") {
                bioAuthentication.fallbackTitle = "fallback title"
                expect(mockContext.localizedFallbackTitle) == "fallback title"
            }
        }

        describe("touch authentication") {

            var error: Error?

            beforeEach {
                error = nil
            }

            it("should authenticate") {
                bioAuthentication.validateBiometric { error = $0 }
                expect(error).toEventually(beNil())
            }

            it("should return error on touch authentication") {
                let touchError = LAError(.appCancel)
                mockContext.replyError = touchError
                bioAuthentication.validateBiometric { error = $0 }
                expect(error).toEventually(matchError(touchError))
            }

            it("should return authenticationFailed error if no policy success") {
                let touchError = LAError(.authenticationFailed)
                mockContext.replySuccess = false
                bioAuthentication.validateBiometric { error = $0 }
                expect(error).toEventually(matchError(touchError))
            }
            
            it("should evaluate passed policy") {
                bioAuthentication.validateBiometric { _ in }
                expect(mockContext.evaluatePolicyReceivedPolicy).to(equal(evaluationPolicy))
            }
        }
    }
}

class MockLAContext: LAContext {
    
    var canEvaluatePolicyReceivedPolicy: LAPolicy?
    var evaluatePolicyReceivedPolicy: LAPolicy?
    var enabled = true
    var replySuccess = true
    var replyError: Error? = nil

    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        canEvaluatePolicyReceivedPolicy = policy
        return self.enabled
    }

    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
        evaluatePolicyReceivedPolicy = policy
        reply(replySuccess, replyError)
    }
}

