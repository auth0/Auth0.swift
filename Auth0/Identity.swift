import Foundation

/**
 Auth0 user identity
 */
@objc(A0Identity)
public class Identity: NSObject, JSONObjectPayload {

    @objc public let identifier: String
    @objc public let provider: String
    @objc public let connection: String

    @objc public let social: Bool
    @objc public let profileData: [String: Any]

    @objc public let accessToken: String?
    @objc public let expiresIn: Date?
    @objc public let accessTokenSecret: String?

    @objc override public var debugDescription: String {
        return "<identity: \(identifier) provider: \(provider) connection: \(connection)>"
    }

    @objc public required init(identifier: String, provider: String, connection: String, social: Bool, profileData: [String: Any], accessToken: String?, expiresIn: Date?, accessTokenSecret: String?) {
        self.identifier = identifier
        self.provider = provider
        self.connection = connection
        self.social = social
        self.profileData = profileData
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.accessTokenSecret = accessTokenSecret
    }

    @objc convenience public required init?(json: [String: Any]) {

        guard
            let identifier = json["user_id"] as? String,
            let provider = json["provider"] as? String,
            let connection = json["connection"] as? String
            else { return nil }

        let social = json["isSocial"] as? Bool ?? false
        let profileData = json["profileData"] as? [String: Any] ?? [:]

        let accessToken = json["access_token"] as? String
        let accessTokenSecret = json["access_token_secret"] as? String
        let expiresIn: Date?
        if let expiresInSeconds = json["expires_in"] as? TimeInterval {
            expiresIn = Date(timeIntervalSince1970: expiresInSeconds)
        } else {
            expiresIn = nil
        }
        self.init(identifier: identifier, provider: provider, connection: connection, social: social, profileData: profileData, accessToken: accessToken, expiresIn: expiresIn, accessTokenSecret: accessTokenSecret)
    }
}
