import Foundation

struct ResponseValue {

    let value: HTTPURLResponse
    let data: Data?

}

struct Response<E: Auth0APIError> {

    let data: Data?
    let response: HTTPURLResponse?
    let error: Error?

    func result() throws(E) -> ResponseValue {
        guard error == nil else { throw E(cause: error!, statusCode: response?.statusCode ?? 0) }
        guard let response = self.response else { throw E(description: nil) }
        guard (200...300).contains(response.statusCode) else {
            throw E(from: ResponseValue(value: response, data: data))
        }
        guard let data = self.data, !data.isEmpty else {
            if response.statusCode == 200 || response.statusCode == 204 {
                return ResponseValue(value: response, data: nil)
            }
            // Not using the custom initializer because data could be empty
            throw E(description: nil, statusCode: response.statusCode)
        }

        return ResponseValue(value: response, data: data)
    }

}
