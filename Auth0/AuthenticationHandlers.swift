import Foundation

func authenticationDecodable<T: Decodable>(from response: Response<AuthenticationError>,
                                           callback: Request<T, AuthenticationError>.Callback) {
    do {
        if let data = try response.result()?.data {
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

func authenticationObject<T: JSONObjectPayload>(from response: Response<AuthenticationError>, callback: Request<T, AuthenticationError>.Callback) {
    do {
        if let dictionary = try response.result()?.body as? [String: Any], let object = T(json: dictionary) {
            callback(.success(object))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }
    } catch {
        callback(.failure(error))
    }
}

func authenticationDatabaseUser(from response: Response<AuthenticationError>,
                                callback: Request<DatabaseUser, AuthenticationError>.Callback) {
    do {
        if let dictionary = try response.result()?.body as? [String: Any], let email = dictionary["email"] as? String {
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

func authenticationNoBody(from response: Response<AuthenticationError>,
                          callback: Request<Void, AuthenticationError>.Callback) {
    do {
        _ = try response.result()
        callback(.success(()))
    } catch let error where error.code == emptyBodyError {
        callback(.success(()))
    } catch {
        callback(.failure(error))
    }
}
