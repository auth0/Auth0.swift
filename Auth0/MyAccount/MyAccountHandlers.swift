import Foundation

func myAcccountDecodable<T: Decodable>(result: Result<ResponseValue, MyAccountError>,
                                       callback: @Sendable (Result<T, MyAccountError>) -> Void) {
    do {
        let response = try result.get()
        if let data = response.data {
            let decoder = JSONDecoder()
            decoder.userInfo[.locationHeaderKey] = response.value.value(forHTTPHeaderField: "Location")
            let decodedObject = try decoder.decode(T.self, from: data)
            callback(.success(decodedObject))
        } else {
            callback(.failure(MyAccountError(from: response)))
        }
    } catch let error as MyAccountError {
        callback(.failure(error))
    } catch {
        callback(.failure(MyAccountError(cause: error)))
    }
}

func myAccountDecodableNoBody(from result: Result<ResponseValue, MyAccountError>,
                              callback: @Sendable (Result<Void, MyAccountError>) -> Void) {
    do {
        _ = try result.get()
        callback(.success(()))
    } catch let error where error.code == emptyBodyError {
        callback(.success(()))
    } catch {
        callback(.failure(error))
    }
}

func getAuthMethodsDecodable(from result: Result<ResponseValue, MyAccountError>,
                             callback: @Sendable (Result<[AuthenticationMethod], MyAccountError>) -> Void) {
    do {
        let response = try result.get()
        if let data = response.data {
            let decoder = JSONDecoder()
            decoder.userInfo[.locationHeaderKey] = response.value.value(forHTTPHeaderField: "Location")
            let decodedObject = try decoder.decode(AuthenticationMethods.self, from: data)
            callback(.success(decodedObject.authenticationMethods))
        } else {
            callback(.failure(MyAccountError(from: response)))
        }
    } catch let error as MyAccountError {
        callback(.failure(error))
    } catch {
        callback(.failure(MyAccountError(cause: error)))
    }
}

func getFactorsDecodable(from result: Result<ResponseValue, MyAccountError>,
                         callback: @Sendable (Result<[Factor], MyAccountError>) -> Void) {
    do {
        let response = try result.get()
        if let data = response.data {
            let decoder = JSONDecoder()
            decoder.userInfo[.locationHeaderKey] = response.value.value(forHTTPHeaderField: "Location")
            let decodedObject = try decoder.decode(Factors.self, from: data)
            callback(.success(decodedObject.factors))
        } else {
            callback(.failure(MyAccountError(from: response)))
        }
    } catch let error as MyAccountError {
        callback(.failure(error))
    } catch {
        callback(.failure(MyAccountError(cause: error)))
    }
}


extension CodingUserInfoKey {

    static var locationHeaderKey: CodingUserInfoKey {
        // Force-unrapping it because it's never nil. See https://github.com/swiftlang/swift/issues/49302
        return CodingUserInfoKey(rawValue: "locationHeader")!
    }

}
