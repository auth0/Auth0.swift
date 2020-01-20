// ClaimsValidators.swift
//
// Copyright (c) 2020 Auth0 (http://auth0.com)
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

import Foundation
import JWTDecode

protocol IDTokenClaimsValidatorContext {
    var issuer: String { get }
    var audience: String { get }
    var leeway: Int { get }
    var nonce: String? { get }
    var maxAge: Int? { get }
}

struct IDTokenClaimsValidator: JWTValidating {
    private let validators: [JWTValidating]

    init(validators: [JWTValidating]) {
        self.validators = validators
    }

    func validate(_ jwt: JWT) -> LocalizedError? {
        return validators.first { $0.validate(jwt) != nil }?.validate(jwt)
    }
}

struct IDTokenIssValidator: JWTValidating {
    enum ValidationError: LocalizedError {
        case missingIss
        case mismatchedIss(actual: String, expected: String)

        var errorDescription: String? {
            switch self {
            case .missingIss: return "Issuer (iss) claim must be a string present in the ID token"
            case .mismatchedIss(let actual, let expected):
                return "Issuer (iss) claim mismatch in the ID token, expected (\(expected)), found (\(actual))"
            }
        }
    }

    private let issuer: String

    init(issuer: String) {
        self.issuer = issuer
    }

    func validate(_ jwt: JWT) -> LocalizedError? {
        guard let iss = jwt.issuer else { return ValidationError.missingIss }
        guard iss == issuer else {
            return ValidationError.mismatchedIss(actual: iss, expected: issuer)
        }
        return nil
    }
}

struct IDTokenSubValidator: JWTValidating {
    enum ValidationError: LocalizedError {
        case missingSub

        var errorDescription: String? {
            switch self {
            case .missingSub: return "Subject (sub) claim must be a string present in the ID token"
            }
        }
    }

    func validate(_ jwt: JWT) -> LocalizedError? {
        guard let sub = jwt.subject, !sub.isEmpty else { return ValidationError.missingSub }
        return nil
    }
}

struct IDTokenAudValidator: JWTValidating {
    enum ValidationError: LocalizedError {
        case missingAud
        case mismatchedAudString(actual: String, expected: String)
        case mismatchedAudArray(actual: [String], expected: String)

        var errorDescription: String? {
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

    private let audience: String

    init(audience: String) {
        self.audience = audience
    }

    func validate(_ jwt: JWT) -> LocalizedError? {
        guard let aud = jwt.audience, !aud.isEmpty else { return ValidationError.missingAud }
        guard aud.contains(audience) else {
            return aud.count == 1 ?
                ValidationError.mismatchedAudString(actual: aud[0], expected: audience) :
                ValidationError.mismatchedAudArray(actual: aud, expected: audience)
        }
        return nil
    }
}

struct IDTokenExpValidator: JWTValidating {
    enum ValidationError: LocalizedError {
        case missingExp
        case pastExp(baseTime: Double, expirationTime: Double)

        var errorDescription: String? {
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

    func validate(_ jwt: JWT) -> LocalizedError? {
        guard let exp = jwt.expiresAt else { return ValidationError.missingExp }
        let baseTimeEpoch = baseTime.timeIntervalSince1970
        let expEpoch = exp.timeIntervalSince1970 + Double(leeway)
        guard expEpoch > baseTimeEpoch else {
            return ValidationError.pastExp(baseTime: baseTimeEpoch, expirationTime: expEpoch)
        }
        return nil
    }
}

struct IDTokenIatValidator: JWTValidating {
    enum ValidationError: LocalizedError {
        case missingIat

        var errorDescription: String? {
            switch self {
            case .missingIat: return "Issued At (iat) claim must be a number present in the ID token"
            }
        }
    }

    func validate(_ jwt: JWT) -> LocalizedError? {
        guard jwt.issuedAt != nil else { return ValidationError.missingIat }
        return nil
    }
}

struct IDTokenNonceValidator: JWTValidating {
    enum ValidationError: LocalizedError {
        case missingNonce
        case mismatchedNonce(actual: String, expected: String)

        var errorDescription: String? {
            switch self {
            case .missingNonce: return "Nonce (nonce) claim must be a string present in the ID token"
            case .mismatchedNonce(let actual, let expected):
                return "Nonce (nonce) claim value mismatch in the ID token; expected (\(expected)), found (\(actual))"
            }
        }
    }

    private let nonce: String

    init(nonce: String) {
        self.nonce = nonce
    }

    func validate(_ jwt: JWT) -> LocalizedError? {
        guard let nonceClaim = jwt.claim(name: "nonce").string else { return ValidationError.missingNonce }
        guard nonceClaim == nonce else {
            return ValidationError.mismatchedNonce(actual: nonceClaim, expected: nonce)
        }
        return nil
    }
}

struct IDTokenAzpValidator: JWTValidating {
    enum ValidationError: LocalizedError {
        case missingAzp
        case mismatchedAzp(actual: String, expected: String)

        var errorDescription: String? {
            switch self {
            case .missingAzp:
                return "Authorized Party (azp) claim must be a string present in the ID token when Audience (aud) claim has multiple values"
            case .mismatchedAzp(let actual, let expected):
                return "Authorized Party (azp) claim mismatch in the ID token; expected (\(expected)), found (\(actual))"
            }
        }
    }

    let audience: String

    init(audience: String) {
        self.audience = audience
    }

    func validate(_ jwt: JWT) -> LocalizedError? {
        guard let azp = jwt.claim(name: "azp").string else { return ValidationError.missingAzp }
        guard azp == audience else {
            return ValidationError.mismatchedAzp(actual: azp, expected: audience)
        }
        return nil
    }
}

struct IDTokenAuthTimeValidator: JWTValidating {
    enum ValidationError: LocalizedError {
        case missingAuthTime
        case pastLastAuth(baseTime: Double, lastAuthTime: Double)

        var errorDescription: String? {
            switch self {
            case .missingAuthTime:
                return "Authentication Time (auth_time) claim must be a number present in the ID token when Max Age (max_age) is specified"
            case .pastLastAuth(let baseTime, let lastAuthTime):
                return "Authentication Time (auth_time) claim in the ID token indicates that too much time has passed since the last end-user authentication. Current time (\(baseTime)) is after last auth time (\(lastAuthTime))"
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

    func validate(_ jwt: JWT) -> LocalizedError? {
        guard let authTime = jwt.claim(name: "auth_time").date else { return ValidationError.missingAuthTime }
        let currentTimeEpoch = baseTime.timeIntervalSince1970
        let authTimeEpoch = authTime.timeIntervalSince1970 + Double(maxAge) + Double(leeway)
        guard authTimeEpoch < currentTimeEpoch else {
            return ValidationError.pastLastAuth(baseTime: currentTimeEpoch, lastAuthTime: authTimeEpoch)
        }
        return nil
    }
}
