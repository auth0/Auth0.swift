import Foundation
import OHHTTPStubs

@testable import Auth0

let UserId = "auth0|\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
let SupportAtAuth0 = "support@auth0.com"
let Support = "support"
let Auth0Phone = "+10123456789"
let Nickname = "sup"
let PictureURL = URL(string: "https://auth0.com/picture")!
let WebsiteURL = URL(string: "https://auth0.com/website")!
let ProfileURL = URL(string: "https://auth0.com/profile")!
let UpdatedAt = "2015-08-19T17:18:01.000Z"
let UpdatedAtUnix = "1440004681"
let UpdatedAtTimestamp = 1440004681.000
let CreatedAt = "2015-08-19T17:18:00.000Z"
let CreatedAtUnix = "1440004680"
let CreatedAtTimestamp = 1440004680.000
let Sub = "auth0|123456789"
let Kid = "key123"
let LocaleUS = "en-US"
let ZoneEST = "US/Eastern"
let OTP = "123456"
let OOB = "654321"
let BindingCode = "214365"
let RecoveryCode = "162534"
let MFAToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
let AuthenticatorId = UUID().uuidString.replacingOccurrences(of: "-", with: "")
let ChallengeTypes = ["oob", "otp"]
let APISuccessStatusCode = Int32(200)
let APIResponseHeaders = ["Content-Type": "application/json"]

func catchAllResponse() -> HTTPStubsResponse {
    return HTTPStubsResponse(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
}

func apiSuccessResponse(json: [AnyHashable: Any] = [:]) -> HTTPStubsResponse {
    return HTTPStubsResponse(jsonObject: json, statusCode: APISuccessStatusCode, headers: APIResponseHeaders)
}

func apiSuccessResponse(jsonArray: [Any]) -> HTTPStubsResponse {
    return HTTPStubsResponse(jsonObject: jsonArray, statusCode: APISuccessStatusCode, headers: APIResponseHeaders)
}

func apiSuccessResponse(string: String) -> HTTPStubsResponse {
    return HTTPStubsResponse(data: string.data(using: .utf8)!, statusCode: APISuccessStatusCode, headers: APIResponseHeaders)
}

func apiFailureResponse(json: [AnyHashable: Any] = [:], statusCode: Int = 400) -> HTTPStubsResponse {
    return HTTPStubsResponse(jsonObject: json, statusCode: Int32(statusCode), headers: APIResponseHeaders)
}

func apiFailureResponse(string: String, statusCode: Int) -> HTTPStubsResponse {
    return HTTPStubsResponse(data: string.data(using: .utf8)!, statusCode: Int32(statusCode), headers: APIResponseHeaders)
}

func authResponse(accessToken: String, idToken: String? = nil, refreshToken: String? = nil, expiresIn: Double? = nil) -> HTTPStubsResponse {
    var json = [
        "access_token": accessToken,
        "token_type": "bearer",
    ]

    if let idToken = idToken {
        json["id_token"] = idToken
    }

    if let refreshToken = refreshToken {
        json["refresh_token"] = refreshToken
    }

    if let expires = expiresIn {
        json["expires_in"] = String(expires)
    }
    return apiSuccessResponse(json: json)
}

func authFailure(code: String, description: String, name: String? = nil) -> HTTPStubsResponse {
    return apiFailureResponse(json: ["code": code, "description": description, "statusCode": 400, "name": name ?? code])
}

func authFailure(error: String, description: String) -> HTTPStubsResponse {
    return apiFailureResponse(json: ["error": error, "error_description": description])
}

func createdUser(email: String, username: String? = nil, verified: Bool = true) -> HTTPStubsResponse {
    var json: [String: Any] = [
        "email": email,
        "email_verified": verified ? "true" : "false",
        ]

    if let username = username {
        json["username"] = username
    }
    return apiSuccessResponse(json: json)
}

func resetPasswordResponse() -> HTTPStubsResponse {
    return apiSuccessResponse(string: "We've just sent you an email to reset your password.")
}

func revokeTokenResponse() -> HTTPStubsResponse {
    return apiSuccessResponse(string: "")
}

func passwordless(_ email: String, verified: Bool) -> HTTPStubsResponse {
    return apiSuccessResponse(json: ["email": email, "verified": "\(verified)"])
}

func managementErrorResponse(error: String, description: String, code: String, statusCode: Int = 400) -> HTTPStubsResponse {
    return apiFailureResponse(json: ["code": code, "description": description, "statusCode": statusCode, "error": error], statusCode: statusCode)
}

func jwksResponse(kid: String? = Kid) -> HTTPStubsResponse {
    var jwks: [String: Any] = ["keys": [["alg": "RS256",
                                         "kty": "RSA",
                                         "use": "sig",
                                         "n": "uGbXWiK3dQTyCbX5xdE4yCuYp0AF2d15Qq1JSXT_lx8CEcXb9RbDddl8jGDv-spi5qPa8qEHiK7FwV2KpRE983wGPnYsAm9BxLFb4YrLYcDFOIGULuk2FtrPS512Qea1bXASuvYXEpQNpGbnTGVsWXI9C-yjHztqyL2h8P6mlThPY9E9ue2fCqdgixfTFIF9Dm4SLHbphUS2iw7w1JgT69s7of9-I9l5lsJ9cozf1rxrXX4V1u_SotUuNB3Fp8oB4C1fLBEhSlMcUJirz1E8AziMCxS-VrRPDM-zfvpIJg3JljAh3PJHDiLu902v9w-Iplu1WyoB2aPfitxEhRN0Yw",
                                         "e": "AQAB",
                                         "kid": kid]]]

    #if WEB_AUTH_PLATFORM
    let jwk = generateRSAJWK()
    jwks = ["keys": [["alg": jwk.algorithm,
                      "kty": jwk.keyType,
                      "use": jwk.usage,
                      "n": jwk.modulus,
                      "e": jwk.exponent,
                      "kid": kid]]]
    #endif

    return apiSuccessResponse(json: jwks)
}

func multifactorChallengeResponse(challengeType: String, oobCode: String? = nil, bindingMethod: String? = nil) -> HTTPStubsResponse {
    var json: [String: Any] = ["challenge_type": challengeType]
    json["oob_code"] = oobCode
    json["binding_method"] = bindingMethod
    return apiSuccessResponse(json: json)
}
