import Foundation

func authenticationDecodable<T: Decodable>(from result: Result<ResponseValue, AuthenticationError>,
                                           callback: @Sendable (Result<T, AuthenticationError>) -> Void) {
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

// Requests that run a RequestValidator get the error it throws wrapped in an error of its own: deliver it as it is.
func authenticationValidatedDecodable<T: Decodable>(from result: Result<ResponseValue, AuthenticationError>,
                                                    callback: @Sendable (Result<T, AuthenticationError>) -> Void) {
    if case .failure(let error) = result, let validationError = error.cause as? AuthenticationError {
        return callback(.failure(validationError))
    }

    authenticationDecodable(from: result, callback: callback)
}

func authenticationObject<T: JSONObjectPayload>(from result: Result<ResponseValue, AuthenticationError>,
                                                callback: @Sendable (Result<T, AuthenticationError>) -> Void) {
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
                                callback: @Sendable (Result<DatabaseUser, AuthenticationError>) -> Void) {
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
                          callback: @Sendable (Result<Void, AuthenticationError>) -> Void) {
    do {
        _ = try result.get()
        callback(.success(()))
    } catch let error where error.code == emptyBodyError {
        callback(.success(()))
    } catch {
        callback(.failure(error))
    }
}
