/// Protocol for types that contain an ID token that can be validated
protocol IDTokenProtocol: Codable {
    var idToken: String { get }
}

// Conformance declarations
extension Credentials: IDTokenProtocol {}
extension SSOCredentials: IDTokenProtocol {}
