#if WEB_AUTH_PLATFORM
import Foundation

extension URLComponents {

    var fragmentValues: [String: String] {
        var dict: [String: String] = [:]
        let items = fragment?.components(separatedBy: "&")
        items?.forEach { item in
            let parts = item.components(separatedBy: "=")
            guard parts.count == 2, let key = parts.first, let value = parts.last else { return }
            dict[key] = value
        }
        return dict
    }

    var queryValues: [String: String] {
        var dict: [String: String] = [:]
        self.queryItems?.forEach { dict[$0.name] = $0.value }
        return dict
    }

}
#endif
