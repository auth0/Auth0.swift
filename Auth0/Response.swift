import Foundation

struct ResponseValue {

    let response: HTTPURLResponse
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
            if let json = json(data) as? [String: Any] {
                throw E(info: json, statusCode: response.statusCode)
            }
            throw E(from: ResponseValue(response: response, data: data))
        }
        guard let data = self.data, !data.isEmpty else {
            if response.statusCode == 204 {
                return ResponseValue(response: response, data: nil)
            }
            // Not using the custom initializer because data could be empty
            throw E(description: nil, statusCode: response.statusCode)
        }
        return ResponseValue(response: response, data: data)
    }

}

func json(_ data: Data?) -> Any? {
    guard let data = data else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: [])
}
