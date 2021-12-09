import Foundation

/**
 *  Represents an error during a request to Auth0 Management API.
 */
public struct ManagementError: Auth0APIError {

    public let info: [String: Any]

    public init(info: [String: Any], statusCode: Int) {
        var values = info
        values["statusCode"] = statusCode
        self.info = values
        self.statusCode = statusCode
    }

    public let statusCode: Int

    public var cause: Error? {
        return self.info["cause"] as? Error
    }

    public var code: String {
        return self.info["code"] as? String ?? unknownError
    }

    public var debugDescription: String {
        if let string = self.info["description"] as? String {
            return string
        }
        return "Failed with unknown error \(self.info)"
    }

}

extension ManagementError: Equatable {

    public static func == (lhs: ManagementError, rhs: ManagementError) -> Bool {
        return lhs.code == rhs.code
            && lhs.statusCode == rhs.statusCode
            && lhs.localizedDescription == rhs.localizedDescription
    }

}
