import Foundation

func plainJson(from response: Response<AuthenticationError>, callback: Request<[String: Any], AuthenticationError>.Callback) {
    do {
        if let dictionary = try response.result() as? [String: Any] {
            callback(.success(dictionary))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }

    } catch let error {
        callback(.failure(error))
    }
}

func codable<T: Codable>(from response: Response<AuthenticationError>, callback: Request<T, AuthenticationError>.Callback) {
    do {
        if let dictionary = try response.result() as? [String: Any] {
            let data = try JSONSerialization.data(withJSONObject: dictionary)
            let decoder = JSONDecoder()
            let decodedObject = try decoder.decode(T.self, from: data)
            callback(.success(decodedObject))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }

    } catch let error {
        callback(.failure(error))
    }
}

func authenticationObject<T: JSONObjectPayload>(from response: Response<AuthenticationError>, callback: Request<T, AuthenticationError>.Callback) {
    do {
        if let dictionary = try response.result() as? [String: Any], let object = T(json: dictionary) {
            callback(.success(object))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }

    } catch let error {
        callback(.failure(error))
    }
}

func databaseUser(from response: Response<AuthenticationError>, callback: Request<DatabaseUser, AuthenticationError>.Callback) {
    do {
        if let dictionary = try response.result() as? [String: Any], let email = dictionary["email"] as? String {
            let username = dictionary["username"] as? String
            let verified = dictionary["email_verified"] as? Bool ?? false
            callback(.success((email: email, username: username, verified: verified)))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }

    } catch let error {
        callback(.failure(error))
    }
}

func noBody(from response: Response<AuthenticationError>, callback: Request<Void, AuthenticationError>.Callback) {
    do {
        _ = try response.result()
        callback(.success(()))
    } catch let error as Auth0APIError where error.code == emptyBodyError {
        callback(.success(()))
    } catch let error {
        callback(.failure(error))
    }
}
