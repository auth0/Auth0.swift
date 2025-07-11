public protocol SenderConstraining {

    var dpop: DPoP? { get set }

}

public extension SenderConstraining {

    func useDPoP(keychainTag: String = DPoP.defaultKeychainTag) -> Self {
        var instance = self
        instance.dpop = DPoP(keychainTag: keychainTag)
        return instance
    }

}

extension SenderConstraining {

    func baseHeaders(accessToken: String, tokenType: String) -> [String: String] {
        return ["Authorization": "\(tokenType) \(accessToken)"]
    }

}
