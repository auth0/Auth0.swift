import Foundation
import JWTDecode

@testable import Auth0

// MARK: - Signature Validator Mocks

struct MockSuccessfulIDTokenSignatureValidator: JWTAsyncValidator {
    func validate(_ jwt: JWT, callback: @escaping (Auth0Error?) -> Void) {
        callback(nil)
    }
}

struct MockUnsuccessfulIDTokenSignatureValidator: JWTAsyncValidator {
    enum ValidationError: Auth0Error {
        case errorCase
        
        var debugDescription: String { return "Error message" }
    }
        
    func validate(_ jwt: JWT, callback: @escaping (Auth0Error?) -> Void) {
        callback(ValidationError.errorCase)
    }
}

class SpyThreadingIDTokenSignatureValidator: JWTAsyncValidator {
    var didExecuteInWorkerThread: Bool = false
    
    func validate(_ jwt: JWT, callback: @escaping (Auth0Error?) -> Void) {
        didExecuteInWorkerThread = !Thread.isMainThread
        
        callback(nil)
    }
}

// MARK: - Claims Validator Mocks

struct MockSuccessfulIDTokenClaimsValidator: JWTValidator {
    func validate(_ jwt: JWT) -> Auth0Error? {
        return nil
    }
}

class SpyThreadingIDTokenClaimsValidator: JWTValidator {
    var didExecuteInWorkerThread: Bool = false
    
    func validate(_ jwt: JWT) -> Auth0Error? {
        didExecuteInWorkerThread = !Thread.isMainThread
        
        return nil
    }
}

struct MockSuccessfulIDTokenClaimValidator: JWTValidator {
    func validate(_ jwt: JWT) -> Auth0Error? {
        return nil
    }
}

class MockUnsuccessfulIDTokenClaimValidator: JWTValidator {
    enum ValidationError: Auth0Error {
        case errorCase1
        case errorCase2
        
        var debugDescription: String { return "Error message" }
    }
    
    let errorCase: ValidationError
    
    init(errorCase: ValidationError = .errorCase1) {
        self.errorCase = errorCase
    }
    
    func validate(_ jwt: JWT) -> Auth0Error? {
        return errorCase
    }
}

class SpyUnsuccessfulIDTokenClaimValidator: MockUnsuccessfulIDTokenClaimValidator {
    var didExecuteValidation: Bool = false
    
    override func validate(_ jwt: JWT) -> Auth0Error? {
        didExecuteValidation = true
        
        return super.validate(jwt)
    }
}
