import Foundation

/// Adds a utility method for encoding data to base64url.
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
