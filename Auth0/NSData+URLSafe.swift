import Foundation

public extension Data {

    /// Encodes data to base64url.
    func a0_encodeBase64URLSafe() -> String? {
        return self
            .base64EncodedString(options: [])
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

}
