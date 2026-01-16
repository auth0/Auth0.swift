import Foundation

func mfaDecodable<T: Decodable>(from result: Result<ResponseValue, AuthenticationError>,
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
    
func listAuthenticatorsResponseMapper(factorsAllowed: [String], result: Result<ResponseValue, AuthenticationError>, callback: Request<[Authenticator], AuthenticationError>.Callback) {
    do {
        let response = try result.get()
        if let data = response.data {
            let decoder = JSONDecoder()
            let authenticators = try decoder.decode([Authenticator].self, from: data)
            let filteredAuthenticators = authenticators.filter { authenticator in factorsAllowed.contains { $0 == authenticator.type } }
            callback(.success(filteredAuthenticators))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }
    } catch let error as AuthenticationError {
        callback(.failure(error))
    } catch {
        callback(.failure(AuthenticationError(cause: error)))
    }
}
