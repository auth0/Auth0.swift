import Foundation

public enum CredentialsManagerError: Error {
    case noCredentials
    case noRefreshToken
    case failedRefresh(Error)
    case touchFailed(Error)
    case revokeFailed(Error)
}
