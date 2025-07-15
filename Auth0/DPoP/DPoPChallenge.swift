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
              header.range(of: "DPoP ", options: .caseInsensitive) != nil else {
            return nil
        }

        let captureGroupName = "value"
        let captureGroupPattern = #"(?<"# + captureGroupName + #">[\x20-\x21\x23-\x5B\x5D-\x7E]+)"#
        let errorCodePattern = #"error\s?=\s?""# + captureGroupPattern + "\""
        let errorDescriptionPattern = #"error_description\s?=\s?""# + captureGroupPattern + "\""

        guard let errorCode = header.captureGroup(named: captureGroupName, pattern: errorCodePattern) else {
            return nil
        }

        if let errorDescription = header.captureGroup(named: captureGroupName, pattern: errorDescriptionPattern) {
            self.init(errorCode: errorCode, errorDescription: errorDescription)
        } else {
            self.init(errorCode: errorCode, errorDescription: nil)
        }
    }

}

extension String {

    func captureGroup(named name: String, pattern: String, options: NSRegularExpression.Options = []) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options),
              let firstMatch = regex.firstMatch(in: self, range: NSRange(self.startIndex ..< self.endIndex, in: self)),
              let captureGroupRange = Range(firstMatch.range(withName: name), in: self) else {
            return nil
        }

        return String(self[captureGroupRange])
    }

}
