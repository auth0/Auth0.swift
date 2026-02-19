import Foundation

func authenticationDecodable<T: Decodable>(from result: Result<ResponseValue, AuthenticationError>,
                                           callback: Request<T, AuthenticationError>.Callback) {
    do {
        let response = try result.get()
        if let data = response.data {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let decodedObject = try decoder.decode(T.self, from: data)
            callback(.success(decodedObject))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }
    } catch let error as AuthenticationError {
        callback(.failure(error))
    } catch {
        callback(.failure(AuthenticationError(cause: error)))
    }
}

func authenticationObject<T: JSONObjectPayload>(from result: Result<ResponseValue, AuthenticationError>,
                                                callback: Request<T, AuthenticationError>.Callback) {
    do {
        let response = try result.get()
        if let dictionary = json(response.data) as? [String: Any],
           let object = T(json: dictionary) {
            callback(.success(object))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }
    } catch {
        callback(.failure(error))
    }
}

func authenticationDatabaseUser(from result: Result<ResponseValue, AuthenticationError>,
                                callback: Request<DatabaseUser, AuthenticationError>.Callback) {
    do {
        let response = try result.get()
        if let dictionary = json(response.data) as? [String: Any],
            let email = dictionary["email"] as? String {
            let username = dictionary["username"] as? String
            let verified = dictionary["email_verified"] as? Bool ?? false
            callback(.success((email: email, username: username, verified: verified)))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }
    } catch {
        callback(.failure(error))
    }
}

func authenticationNoBody(from result: Result<ResponseValue, AuthenticationError>,
                          callback: Request<Void, AuthenticationError>.Callback) {
    do {
        _ = try result.get()
        callback(.success(()))
    } catch let error where error.code == emptyBodyError {
        callback(.success(()))
    } catch {
        callback(.failure(error))
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
func authenticationDecodableWithIDTokenValidation<T: IDTokenProtocol>(
    issuer: String,
    leeway: Int = 60000,
    maxAge: Int? = nil,
    nonce: String? = nil,
    organization: String? = nil,
    authentication: Authentication,
    from result: Result<ResponseValue, AuthenticationError>,
    callback: @escaping Request<T, AuthenticationError>.Callback
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
                    callback(.failure(AuthenticationError(cause: error)))
                }
                callback(.success(decodedObject))
            }
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }
    } catch let error as AuthenticationError {
        callback(.failure(error))
    } catch {
        callback(.failure(AuthenticationError(cause: error)))
    }
}
