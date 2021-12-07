#if WEB_AUTH_PLATFORM
import Foundation
import JWTDecode

extension JWT {

    var algorithm: JWTAlgorithm? {
        guard let alg = header["alg"] as? String, let algorithm = JWTAlgorithm(rawValue: alg) else { return nil }
        return algorithm
    }

    var kid: String? {
        return header["kid"] as? String
    }

}
#endif
