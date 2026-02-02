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

func listAuthenticatorsResponseMapper(factorsAllowed: [String], result: Result<ResponseValue, MfaListAuthenticatorsError>, callback: Request<[Authenticator], MfaListAuthenticatorsError>.Callback) {
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
