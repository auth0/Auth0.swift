import Foundation

func mfaChallengeDecodable<T: Decodable>(from result: Result<ResponseValue, MfaChallengeError>,
                                         callback: Request<T, MfaChallengeError>.Callback) {
    do {
        let response = try result.get()
        if let data = response.data {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let decodedObject = try decoder.decode(T.self, from: data)
            callback(.success(decodedObject))
        } else {
            callback(.failure(MfaChallengeError(from: response)))
        }
    } catch let error as MfaChallengeError {
        callback(.failure(error))
    } catch {
        callback(.failure(MfaChallengeError(cause: error)))
    }
}

func mfaVerifyDecodable<T: Decodable>(from result: Result<ResponseValue, MFAVerifyError>,
                                      callback: Request<T, MFAVerifyError>.Callback) {
    do {
        let response = try result.get()
        if let data = response.data {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let decodedObject = try decoder.decode(T.self, from: data)
            callback(.success(decodedObject))
        } else {
            callback(.failure(MFAVerifyError(from: response)))
        }
    } catch let error as MFAVerifyError {
        callback(.failure(error))
    } catch {
        callback(.failure(MFAVerifyError(cause: error)))
    }
}

/// Factory function that creates an authentication handler with ID token validation.
/// This handler decodes the response and validates the ID token before returning.
///
/// - Parameters:
///   - issuer: The expected issuer of the ID token.
///   - leeway: The amount of leeway, in milliseconds, to accommodate potential clock skew.
///   - maxAge: The maximum authentication age, in seconds. Optional.
///   - nonce: The expected nonce value. Optional.
///   - organization: The expected organization ID or name. Optional.
///   - authentication: The Authentication instance used for JWKS retrieval.
/// - Returns: A handler function that can be used with Request initialization.
func mfaVerifyDecodableWithIDTokenValidation<T: IDTokenProtocol>(
    issuer: String,
    leeway: Int = 60000,
    maxAge: Int? = nil,
    nonce: String? = nil,
    organization: String? = nil,
    authentication: Authentication,
    from result: Result<ResponseValue, MFAVerifyError>,
    callback: @escaping Request<T, MFAVerifyError>.Callback
) {
    do {
        let response = try result.get()
        if let data = response.data {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let decodedObject = try decoder.decode(T.self, from: data)

            // Validate the decoded object (which includes ID token validation)
            guard !decodedObject.idToken.isEmpty else {
                // No ID token to validate, return as-is
                return callback(.success(decodedObject))
            }

            // Validate ID token
            let validatorContext = IDTokenValidatorContext(
                authentication: authentication,
                issuer: issuer,
                leeway: leeway,
                maxAge: maxAge,
                nonce: nonce,
                organization: organization
            )

            validate(idToken: decodedObject.idToken, with: validatorContext) { error in
                if let error = error {
                    callback(.failure(MFAVerifyError(cause: error)))
                }
                callback(.success(decodedObject))
            }
        } else {
            callback(.failure(MFAVerifyError(from: response)))
        }
    } catch let error as MFAVerifyError {
        callback(.failure(error))
    } catch {
        callback(.failure(MFAVerifyError(cause: error)))
    }
}

func mfaEnrollDecodable<T: Decodable>(from result: Result<ResponseValue, MfaEnrollmentError>,
                                      callback: Request<T, MfaEnrollmentError>.Callback) {
    do {
        let response = try result.get()
        if let data = response.data {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let decodedObject = try decoder.decode(T.self, from: data)
            callback(.success(decodedObject))
        } else {
            callback(.failure(MfaEnrollmentError(from: response)))
        }
    } catch let error as MfaEnrollmentError {
        callback(.failure(error))
    } catch {
        callback(.failure(MfaEnrollmentError(cause: error)))
    }
}

func listAuthenticatorsResponseMapper(factorsAllowed: [String],
                                      result: Result<ResponseValue, MfaListAuthenticatorsError>,
                                      callback: Request<[Authenticator], MfaListAuthenticatorsError>.Callback) {
    do {
        let response = try result.get()
        if let data = response.data {
            let decoder = JSONDecoder()
            let authenticators = try decoder.decode([Authenticator].self, from: data)
            let filteredAuthenticators = authenticators.filter { authenticator in factorsAllowed.contains { $0 == authenticator.type } }
            callback(.success(filteredAuthenticators))
        } else {
            callback(.failure(MfaListAuthenticatorsError(from: response)))
        }
    } catch let error as MfaListAuthenticatorsError {
        callback(.failure(error))
    } catch {
        callback(.failure(MfaListAuthenticatorsError(cause: error)))
    }
}
