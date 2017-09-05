// OAuth2Grant.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
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

protocol OAuth2Grant {
    var defaults: [String: String] { get }
    func credentials(from values: [String: String], callback: @escaping (Result<Credentials>) -> Void)
    func values(fromComponents components: URLComponents) -> [String: String]
}

struct ImplicitGrant: OAuth2Grant {

    let defaults: [String : String]
    let responseType: [ResponseType]

    init(responseType: [ResponseType] = [.token], nonce: String? = nil) {
        self.responseType = responseType
        if let nonce = nonce {
            self.defaults = ["nonce": nonce]
        } else {
            self.defaults = [:]
        }
    }

    func credentials(from values: [String : String], callback: @escaping (Result<Credentials>) -> Void) {
        guard validate(responseType: self.responseType, token: values["id_token"], nonce: self.defaults["nonce"]) else {
            return callback(.failure(error: WebAuthError.invalidIdTokenNonce))
        }

        guard !responseType.contains(.token) || values["access_token"] != nil else {
            return callback(.failure(error: WebAuthError.missingAccessToken))
        }

        callback(.success(result: Credentials(json: values as [String : Any])))
    }

    func values(fromComponents components: URLComponents) -> [String : String] {
        return components.a0_fragmentValues
    }

}

struct PKCE: OAuth2Grant {

    let authentication: Authentication
    let redirectURL: URL
    let defaults: [String : String]
    let verifier: String
    let responseType: [ResponseType]

    init(authentication: Authentication, redirectURL: URL, generator: A0SHA256ChallengeGenerator = A0SHA256ChallengeGenerator(), reponseType: [ResponseType] = [.code], nonce: String? = nil) {
        self.init(authentication: authentication, redirectURL: redirectURL, verifier: generator.verifier, challenge: generator.challenge, method: generator.method, responseType: reponseType, nonce: nonce)
    }

    init(authentication: Authentication, redirectURL: URL, verifier: String, challenge: String, method: String, responseType: [ResponseType], nonce: String? = nil) {
        self.authentication = authentication
        self.redirectURL = redirectURL
        self.verifier = verifier
        self.responseType = responseType

        var newDefaults: [String: String] = [
            "code_challenge": challenge,
            "code_challenge_method": method
        ]

        if let nonce = nonce {
            newDefaults["nonce"] = nonce
        }

        self.defaults = newDefaults
    }

    func credentials(from values: [String: String], callback: @escaping (Result<Credentials>) -> Void) {
        guard
            let code = values["code"]
            else {
                let string = "No code found in parameters \(values)"
                return callback(.failure(error: AuthenticationError(string: string)))
        }
        guard validate(responseType: self.responseType, token: values["id_token"], nonce: self.defaults["nonce"]) else {
            return callback(.failure(error: WebAuthError.invalidIdTokenNonce))
        }
        let clientId = self.authentication.clientId
        self.authentication
            .tokenExchange(withCode: code, codeVerifier: verifier, redirectURI: redirectURL.absoluteString)
            .start { result in
                // Special case for PKCE when the correct method for token endpoint authentication is not set (it should be None)
                if case .failure(let cause as AuthenticationError) = result, cause.description == "Unauthorized" {
                    let error = WebAuthError.pkceNotAllowed("Please go to 'https://manage.auth0.com/#/applications/\(clientId)/settings' and make sure 'Client Type' is 'Native' to enable PKCE.")
                    callback(Result.failure(error: error))
                } else {
                    callback(result)
                }
        }
    }

    func values(fromComponents components: URLComponents) -> [String : String] {
        var items = components.a0_fragmentValues
        components.a0_queryValues.forEach { items[$0] = $1 }
        return items
    }
}

private func validate(responseType: [ResponseType], token: String?, nonce: String?) -> Bool {
    guard responseType.contains(.idToken) else { return true }
    guard
        let expectedNonce = nonce,
        let token = token
        else { return false }
    let claims = decode(jwt: token)
    let actualNonce = claims?["nonce"] as? String
    return actualNonce == expectedNonce
}

private func decode(jwt: String) -> [String: Any]? {
    let parts = jwt.components(separatedBy: ".")
    guard parts.count == 3 else { return nil }
    var base64 = parts[1]
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
    let requiredLength = 4 * ceil(length / 4.0)
    let paddingLength = requiredLength - length
    if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 += padding
    }

    guard
        let bodyData = Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
        else { return nil }

    let json = try? JSONSerialization.jsonObject(with: bodyData, options: [])
    return json as? [String: Any]
}
