#if WEB_AUTH_PLATFORM
import Foundation
@preconcurrency import JWTDecode

protocol JWTValidator {
    func validate(_ jwt: JWT) -> Auth0Error?
}

protocol JWTAsyncValidator {
    func validate(_ jwt: JWT, callback: @escaping (Auth0Error?) -> Void)
}

struct IDTokenValidator: JWTAsyncValidator {
    private let signatureValidator: JWTAsyncValidator
    private let claimsValidator: JWTValidator
    private let context: IDTokenValidatorContext

    init(signatureValidator: JWTAsyncValidator,
         claimsValidator: JWTValidator,
         context: IDTokenValidatorContext) {
        self.signatureValidator = signatureValidator
        self.claimsValidator = claimsValidator
        self.context = context
    }

    func validate(_ jwt: JWT, callback: @escaping (Auth0Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.signatureValidator.validate(jwt) { error in
                if let error = error { return callback(error) }
                let result = self.claimsValidator.validate(jwt)
                DispatchQueue.main.async {
                    callback(result)
                }
            }
        }
    }
}

enum IDTokenDecodingError: Auth0Error {
    case cannotDecode

    var debugDescription: String {
        switch self {
        case .cannotDecode: return "ID token could not be decoded"
        }
    }
}

/// Returns `true` if the given error is one of the known ID token validation error types.
/// Use this instead of `cause is any Auth0Error` since many types (e.g. `AuthenticationError`,
/// `CredentialsManagerError`) also conform to `Auth0Error` and would produce false positives.
func isIDTokenValidationError(_ error: Error) -> Bool {
    return error is IDTokenDecodingError
        || error is IDTokenIssValidator.ValidationError
        || error is IDTokenSubValidator.ValidationError
        || error is IDTokenAudValidator.ValidationError
        || error is IDTokenExpValidator.ValidationError
        || error is IDTokenIatValidator.ValidationError
        || error is IDTokenNonceValidator.ValidationError
        || error is IDTokenAzpValidator.ValidationError
        || error is IDTokenAuthTimeValidator.ValidationError
        || error is IDTokenOrgIDValidator.ValidationError
        || error is IDTokenOrgNameValidator.ValidationError
        || error is IDTokenSignatureValidator.ValidationError
}

func validate(idToken: String,
              with context: IDTokenValidatorContext,
              signatureValidator: JWTAsyncValidator? = nil, // for testing
              claimsValidator: JWTValidator? = nil,
              callback: @escaping (Auth0Error?) -> Void) {
    guard let jwt = try? decode(jwt: idToken) else { return callback(IDTokenDecodingError.cannotDecode) }
    var claimValidators: [JWTValidator] = [IDTokenIssValidator(issuer: context.issuer),
                                           IDTokenSubValidator(),
                                           IDTokenAudValidator(audience: context.audience),
                                           IDTokenExpValidator(leeway: context.leeway),
                                           IDTokenIatValidator()]
    if let nonce = context.nonce {
        claimValidators.append(IDTokenNonceValidator(nonce: nonce))
    }
    if let audience = jwt.audience, audience.count > 1 {
        claimValidators.append(IDTokenAzpValidator(authorizedParty: context.audience))
    }
    if let maxAge = context.maxAge {
        claimValidators.append(IDTokenAuthTimeValidator(leeway: context.leeway, maxAge: maxAge))
    }
    if let organization = context.organization {
        if organization.starts(with: "org_") {
            claimValidators.append(IDTokenOrgIDValidator(orgID: organization))
        } else {
            claimValidators.append(IDTokenOrgNameValidator(orgName: organization))
        }
    }
    let validator = IDTokenValidator(signatureValidator: signatureValidator ?? IDTokenSignatureValidator(context: context),
                                     claimsValidator: claimsValidator ?? IDTokenClaimsValidator(validators: claimValidators),
                                     context: context)
    validator.validate(jwt, callback: callback)
}
#endif
