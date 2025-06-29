import Foundation

func myAcccountDecodable<T: Decodable>(from response: Response<MyAccountError>,
                                       callback: Request<T, MyAccountError>.Callback) {
    do {
        if let jsonResponse = try response.result() {
            let decoder = JSONDecoder()
            decoder.userInfo[.headersKey] = jsonResponse.headers
            let decodedObject = try decoder.decode(T.self, from: jsonResponse.data)
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

func myAccountDecodableNoBody(from response: Response<MyAccountError>,
                              callback: Request<Void, MyAccountError>.Callback) {
    do {
        _ = try response.result()
        callback(.success(()))
    } catch let error where error.code == emptyBodyError {
        callback(.success(()))
    } catch {
        callback(.failure(error))
    }
}

extension CodingUserInfoKey {

    static var headersKey: CodingUserInfoKey {
        // Force-unrapping it because it's never nil. See https://github.com/swiftlang/swift/issues/49302
        return CodingUserInfoKey(rawValue: "headers")!
    }

}
