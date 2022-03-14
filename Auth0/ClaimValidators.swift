#if WEB_AUTH_PLATFORM
import Foundation
import JWTDecode

protocol IDTokenClaimsValidatorContext {
    var issuer: String { get }
    var audience: String { get }
    var leeway: Int { get }
    var nonce: String? { get }
    var maxAge: Int? { get }
}

struct IDTokenClaimsValidator: JWTValidator {
    private let validators: [JWTValidator]

    init(validators: [JWTValidator]) {
        self.validators = validators
    }

    func validate(_ jwt: JWT) -> Auth0Error? {
        return validators.first { $0.validate(jwt) != nil }?.validate(jwt)
    }
}

struct IDTokenIssValidator: JWTValidator {
    enum ValidationError: Auth0Error {
        case missingIss
        case mismatchedIss(actual: String, expected: String)

        var debugDescription: String {
            switch self {
            case .missingIss: return "Issuer (iss) claim must be a string present in the ID token"
            case .mismatchedIss(let actual, let expected):
                return "Issuer (iss) claim mismatch in the ID token, expected (\(expected)), found (\(actual))"
            }
        }
    }

    private let expectedIss: String

    init(issuer: String) {
        self.expectedIss = issuer
    }

    func validate(_ jwt: JWT) -> Auth0Error? {
        guard let actualIss = jwt.issuer else { return ValidationError.missingIss }
        guard actualIss == expectedIss else {
            return ValidationError.mismatchedIss(actual: actualIss, expected: expectedIss)
        }
        return nil
    }
}

struct IDTokenSubValidator: JWTValidator {
    enum ValidationError: Auth0Error {
        case missingSub

        var debugDescription: String {
            switch self {
            case .missingSub: return "Subject (sub) claim must be a string present in the ID token"
            }
        }
    }

    func validate(_ jwt: JWT) -> Auth0Error? {
        guard let sub = jwt.subject, !sub.isEmpty else { return ValidationError.missingSub }
        return nil
    }
}

struct IDTokenAudValidator: JWTValidator {
    enum ValidationError: Auth0Error {
        case missingAud
        case mismatchedAudString(actual: String, expected: String)
        case mismatchedAudArray(actual: [String], expected: String)

        var debugDescription: String {
            switch self {
            case .missingAud:
                return "Audience (aud) claim must be a string or array of strings present in the ID token"
            case .mismatchedAudString(let actual, let expected):
                return "Audience (aud) claim mismatch in the ID token; expected (\(expected)) but found (\(actual))"
            case .mismatchedAudArray(let actual, let expected):
                return "Audience (aud) claim mismatch in the ID token; expected (\(expected)) but was not one of (\(actual.joined(separator: ", ")))"
            }
        }
    }

    private let expectedAud: String

    init(audience: String) {
        self.expectedAud = audience
    }

    func validate(_ jwt: JWT) -> Auth0Error? {
        guard let actualAud = jwt.audience, !actualAud.isEmpty else { return ValidationError.missingAud }
        guard actualAud.contains(expectedAud) else {
            return actualAud.count == 1 ?
                ValidationError.mismatchedAudString(actual: actualAud[0], expected: expectedAud) :
                ValidationError.mismatchedAudArray(actual: actualAud, expected: expectedAud)
        }
        return nil
    }
}

struct IDTokenExpValidator: JWTValidator {
    enum ValidationError: Auth0Error {
        case missingExp
        case pastExp(baseTime: Double, expirationTime: Double)

        var debugDescription: String {
            switch self {
            case .missingExp: return "Expiration time (exp) claim must be a number present in the ID token"
            case .pastExp(let baseTime, let expirationTime):
                return "Expiration time (exp) claim error in the ID token; current time (\(baseTime)) is after expiration time (\(expirationTime))"
            }
        }
    }

    private let baseTime: Date
    private let leeway: Int

    init(baseTime: Date = Date(), leeway: Int) {
        self.baseTime = baseTime
        self.leeway = leeway
    }

    func validate(_ jwt: JWT) -> Auth0Error? {
        guard let exp = jwt.expiresAt else { return ValidationError.missingExp }
        let baseTimeEpoch = baseTime.timeIntervalSince1970
        let expEpoch = exp.timeIntervalSince1970 + Double(leeway)
        guard expEpoch > baseTimeEpoch else {
            return ValidationError.pastExp(baseTime: baseTimeEpoch, expirationTime: expEpoch)
        }
        return nil
    }
}

struct IDTokenIatValidator: JWTValidator {
    enum ValidationError: Auth0Error {
        case missingIat

        var debugDescription: String {
            switch self {
            case .missingIat: return "Issued At (iat) claim must be a number present in the ID token"
            }
        }
    }

    func validate(_ jwt: JWT) -> Auth0Error? {
        guard jwt.issuedAt != nil else { return ValidationError.missingIat }
        return nil
    }
}

struct IDTokenNonceValidator: JWTValidator {
    enum ValidationError: Auth0Error {
        case missingNonce
        case mismatchedNonce(actual: String, expected: String)

        var debugDescription: String {
            switch self {
            case .missingNonce: return "Nonce (nonce) claim must be a string present in the ID token"
            case .mismatchedNonce(let actual, let expected):
                return "Nonce (nonce) claim value mismatch in the ID token; expected (\(expected)), found (\(actual))"
            }
        }
    }

    private let expectedNonce: String

    init(nonce: String) {
        self.expectedNonce = nonce
    }

    func validate(_ jwt: JWT) -> Auth0Error? {
        guard let actualNonce = jwt.claim(name: "nonce").string else { return ValidationError.missingNonce }
        guard actualNonce == expectedNonce else {
            return ValidationError.mismatchedNonce(actual: actualNonce, expected: expectedNonce)
        }
        return nil
    }
}

struct IDTokenAzpValidator: JWTValidator {
    enum ValidationError: Auth0Error {
        case missingAzp
        case mismatchedAzp(actual: String, expected: String)

        var debugDescription: String {
            switch self {
            case .missingAzp:
                return "Authorized Party (azp) claim must be a string present in the ID token when Audience (aud) claim has multiple values"
            case .mismatchedAzp(let actual, let expected):
                return "Authorized Party (azp) claim mismatch in the ID token; expected (\(expected)), found (\(actual))"
            }
        }
    }

    let expectedAzp: String

    init(authorizedParty: String) {
        self.expectedAzp = authorizedParty
    }

    func validate(_ jwt: JWT) -> Auth0Error? {
        guard let actualAzp = jwt.claim(name: "azp").string else { return ValidationError.missingAzp }
        guard actualAzp == expectedAzp else {
            return ValidationError.mismatchedAzp(actual: actualAzp, expected: expectedAzp)
        }
        return nil
    }
}

struct IDTokenAuthTimeValidator: JWTValidator {
    enum ValidationError: Auth0Error {
        case missingAuthTime
        case pastLastAuth(baseTime: Double, lastAuthTime: Double)

        var debugDescription: String {
            switch self {
            case .missingAuthTime:
                return "Authentication Time (auth_time) claim must be a number present in the ID token when Max Age (max_age) is specified"
            case .pastLastAuth(let baseTime, let lastAuthTime):
                return "Authentication Time (auth_time) claim in the ID token indicates that too much time has passed since the last user authentication. Current time (\(baseTime)) is after last auth time (\(lastAuthTime))"
            }
        }
    }

    private let baseTime: Date
    private let leeway: Int
    private let maxAge: Int

    init(baseTime: Date = Date(), leeway: Int, maxAge: Int) {
        self.baseTime = baseTime
        self.leeway = leeway
        self.maxAge = maxAge
    }

    func validate(_ jwt: JWT) -> Auth0Error? {
        guard let authTime = jwt.claim(name: "auth_time").date else { return ValidationError.missingAuthTime }
        let currentTimeEpoch = baseTime.timeIntervalSince1970
        let adjustedMaxAge = Double(maxAge) + Double(leeway)
        let authTimeEpoch = authTime.timeIntervalSince1970 + adjustedMaxAge
        guard currentTimeEpoch <= authTimeEpoch else {
            return ValidationError.pastLastAuth(baseTime: currentTimeEpoch, lastAuthTime: authTimeEpoch)
        }
        return nil
    }
}

struct IDTokenOrgIdValidator: JWTValidator {
    enum ValidationError: Auth0Error {
        case missingOrgId
        case mismatchedOrgId(actual: String, expected: String)

        var debugDescription: String {
            switch self {
            case .missingOrgId: return "Organization Id (org_id) claim must be a string present in the ID token"
            case .mismatchedOrgId(let actual, let expected):
                return "Organization Id (org_id) claim value mismatch in the ID token; expected (\(expected)), found (\(actual))"
            }
        }
    }

    private let expectedOrganization: String

    init(organization: String) {
        self.expectedOrganization = organization
    }

    func validate(_ jwt: JWT) -> Auth0Error? {
        guard let actualOrganization = jwt.claim(name: "org_id").string else { return ValidationError.missingOrgId }
        guard actualOrganization == expectedOrganization else {
            return ValidationError.mismatchedOrgId(actual: actualOrganization, expected: expectedOrganization)
        }
        return nil
    }
}
#endif
