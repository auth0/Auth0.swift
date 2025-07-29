import Foundation

/// A TOTP/Push enrollment challenge.
public struct TOTPPushEnrollmentChallenge {

    /// The unique identifier for the authentication method.
    public let authenticationId: String

    /// The unique session identifier for the enrollment.
    public let authenticationSession: String

    /// The URI for the QR code to be scanned by the authenticator.
    public let authenticatorQRCodeURI: String

    /// The manual input code for the authenticator in case QR codes cannot be used.
    public let authenticatorManualInputCode: String?
}

extension TOTPPushEnrollmentChallenge: Decodable {

    enum CodingKeys: String, CodingKey {
        case authenticationSession = "auth_session"
        case authenticationId = "id"
        case authenticatorQRCodeURI = "barcode_uri"
        case authenticatorManualInputCode = "manual_input_code"
    }

    /// `Decodable` initializer.
    public init(from decoder: Decoder) throws {
        guard let headers = decoder.userInfo[.headersKey] as? [String: Any],
              let locationHeader = headers["Location"] as? String,
              let authenticationMethodId = locationHeader.components(separatedBy: "/").last else {
            let errorDescription = "Missing authentication method identifier in header 'Location'"
            let errorContext = DecodingError.Context(codingPath: [],
                                                     debugDescription: errorDescription)
            throw DecodingError.dataCorrupted(errorContext)
        }

        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(authenticationId: try values.decode(String.self, forKey: .authenticationId),
                  authenticationSession: try values.decode(String.self, forKey: .authenticationSession),
                  authenticatorQRCodeURI: try values.decode(String.self, forKey: .authenticatorQRCodeURI),
                  authenticatorManualInputCode: try values.decodeIfPresent(String.self, forKey: .authenticatorManualInputCode))
    }

}
