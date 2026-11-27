import Foundation

/// The body of an `/e/authorize` answer that completes the flow.
struct AuthorizationCodeResponse: Decodable {
    let authorizationCode: String

    enum CodingKeys: String, CodingKey {
        case authorizationCode = "authorization_code"
    }
}
