import Foundation
import JWTDecode

@testable import Auth0

// MARK: - Signature Validator Mocks

struct MockSuccessfulIDTokenSignatureValidator: JWTAsyncValidator {
    func validate(_ jwt: JWT, callback: @escaping (LocalizedError?) -> Void) {
        callback(nil)
    }
}

struct MockUnsuccessfulIDTokenSignatureValidator: JWTAsyncValidator {
    enum ValidationError: LocalizedError {
        case errorCase
        
        var errorDescription: String? { return "Error message" }
    }
        
    func validate(_ jwt: JWT, callback: @escaping (LocalizedError?) -> Void) {
        callback(ValidationError.errorCase)
    }
}

class SpyThreadingIDTokenSignatureValidator: JWTAsyncValidator {
    var didExecuteInWorkerThread: Bool = false
    
    func validate(_ jwt: JWT, callback: @escaping (LocalizedError?) -> Void) {
        didExecuteInWorkerThread = !Thread.isMainThread
        
        callback(nil)
    }
}

// MARK: - Claims Validator Mocks

struct MockSuccessfulIDTokenClaimsValidator: JWTValidator {
    func validate(_ jwt: JWT) -> LocalizedError? {
        return nil
    }
}

class SpyThreadingIDTokenClaimsValidator: JWTValidator {
    var didExecuteInWorkerThread: Bool = false
    
    func validate(_ jwt: JWT) -> LocalizedError? {
        didExecuteInWorkerThread = !Thread.isMainThread
        
        return nil
    }
}

struct MockSuccessfulIDTokenClaimValidator: JWTValidator {
    func validate(_ jwt: JWT) -> LocalizedError? {
        return nil
    }
}

class MockUnsuccessfulIDTokenClaimValidator: JWTValidator {
    enum ValidationError: LocalizedError {
        case errorCase1
        case errorCase2
        
        var errorDescription: String? { return "Error message" }
    }
    
    let errorCase: ValidationError
    
    init(errorCase: ValidationError = .errorCase1) {
        self.errorCase = errorCase
    }
    
    func validate(_ jwt: JWT) -> LocalizedError? {
        return errorCase
    }
}

class SpyUnsuccessfulIDTokenClaimValidator: MockUnsuccessfulIDTokenClaimValidator {
    var didExecuteValidation: Bool = false
    
    override func validate(_ jwt: JWT) -> LocalizedError? {
        didExecuteValidation = true
        
        return super.validate(jwt)
    }
}
