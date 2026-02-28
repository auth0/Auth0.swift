// Protocol for types that contain an ID token that can be validated.
// Conformed to by Credentials and SSOCredentials.
protocol IDTokenProtocol: Decodable {
    var idToken: String { get }
}

extension Credentials: IDTokenProtocol {}
extension SSOCredentials: IDTokenProtocol {}
