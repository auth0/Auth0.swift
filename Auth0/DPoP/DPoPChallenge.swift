import Foundation

struct DPoPChallenge {

    let errorCode: String
    let errorDescription: String?

    init(errorCode: String, errorDescription: String?) {
        self.errorCode = errorCode
        self.errorDescription = errorDescription
    }

    init?(from response: HTTPURLResponse) {
        guard let header = response.value(forHTTPHeaderField: "WWW-Authenticate"),
              header.range(of: "DPoP ", options: .caseInsensitive) != nil else { return nil }

        let valuePattern = #"([\x20-\x21\x23-\x5B\x5D-\x7E]+)"#
        let errorCodePattern = #"error\s?=\s?""# + valuePattern + "\""
        let errorDescriptionPattern = #"error_description\s?=\s?""# + valuePattern + "\""
        let compareOptions: String.CompareOptions = [.caseInsensitive, .regularExpression]

        guard let errorCodeRange = header.range(of: errorCodePattern, options: compareOptions) else {
            return nil
        }

        let errorCode = String(header[errorCodeRange])

        if let errorDescriptionRange = header.range(of: errorDescriptionPattern, options: compareOptions) {
            self.init(errorCode: errorCode, errorDescription: String(header[errorDescriptionRange]))
        }

        self.init(errorCode: errorCode, errorDescription: nil)
    }

}
