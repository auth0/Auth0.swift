import Foundation

func myAcccountDecodable<T: Decodable>(from response: Response<MyAccountError>,
                                       callback: Request<T, MyAccountError>.Callback) {
    do {
        if let jsonResponse = try response.result() {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
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
