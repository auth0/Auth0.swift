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

