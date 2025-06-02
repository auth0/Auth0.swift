import Foundation

func json(_ data: Data?) -> Sendable? {
    guard let data = data else { return nil }
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

        if let dict = jsonObject as? [String: Any] {
            let sendableDict: [String: Sendable] = dict.compactMapValues { value in
                if let s = value as? String { return s }
                if let i = value as? Int { return i }
                if let d = value as? Double { return d }
                if let b = value as? Bool { return b }
                return nil
            }
            return sendableDict
        } else if let array = jsonObject as? [Any] {
            let sendableArray: [Sendable] = array.compactMap { value in
                if let s = value as? String { return s }
                if let i = value as? Int { return i }
                if let d = value as? Double { return d }
                if let b = value as? Bool { return b }
                return nil
            }
            return sendableArray
        }
        return nil
    } catch {
        return nil
    }
}

func string(_ data: Data?) -> String? {
    guard let data = data else { return nil }
    return String(data: data, encoding: .utf8)
}

typealias JSONResponse = (headers: [String: any Sendable], body: any Sendable, data: Data)

struct Response<E: Auth0APIError>: Sendable {
    let data: Data?
    let response: HTTPURLResponse?
    let error: Error?

    func result() throws(E) -> JSONResponse? {
        guard error == nil else { throw E(cause: error!, statusCode: response?.statusCode ?? 0) }
        guard let response = self.response else { throw E(description: nil) }
        guard (200...300).contains(response.statusCode) else {
            if let json = json(data) as? [String: Any] {
                throw E(info: json, statusCode: response.statusCode)
            }
            throw E(from: self)
        }
        guard let data = self.data, !data.isEmpty else {
            if response.statusCode == 204 {
                return nil
            }
            // Not using the custom initializer because data could be empty
            throw E(description: nil, statusCode: response.statusCode)
        }
        if let json = json(data) {
            return (headers: response.allHeaderFields.stringDictionary, body: json, data: data)
        }
        // This piece of code is dedicated to our friends the backend devs :)
        if response.url?.lastPathComponent == "change_password" {
            return nil
        }
        throw E(from: self)
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {

    var stringDictionary: [String: any Sendable] {
        var result: [String: any Sendable] = [:]
        for (key, value) in self {
            guard let stringKey = key as? String else {
                continue
            }
            if let str = value as? String {
                result[stringKey] = str
            } else if let num = value as? Int {
                result[stringKey] = num
            } else if let boolean = value as? Bool {
                result[stringKey] = boolean
            } else if let double = value as? Double {
                result[stringKey] = double
            } else if let array = value as? [any Sendable] {
                result[stringKey] = array
            } else if let dict = value as? [String: any Sendable] {
                result[stringKey] = dict
            } else {
                continue
            }
        }
        return result
    }

}
