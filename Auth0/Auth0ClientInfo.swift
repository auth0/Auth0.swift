import Foundation

/// Generates and sets the `Auth0-Client` header.
public struct Auth0ClientInfo: Sendable {

    static let NameKey = "name"
    static let VersionKey = "version"
    static let WrappedVersion = "core"
    static let EnvironmentKey = "env"
    static let LibraryName = "Auth0.swift"

    var enabled: Bool = true

    var info: String?

    var value: String? {
        return self.enabled ? self.info : nil
    }

    /// Initializer that generates a base64url-encoded value with client info data.
    public init() {
        self.info = Auth0ClientInfo.generateValue()
    }

    mutating func wrapped(inLibrary name: String, version: String) {
        let info = Auth0ClientInfo.versionInformation()
        var env = Auth0ClientInfo.generateEnviroment()
        env[Auth0ClientInfo.WrappedVersion] = info[Auth0ClientInfo.VersionKey] as? String
        let wrapped: [String: Any] = [
            Auth0ClientInfo.NameKey: name,
            Auth0ClientInfo.VersionKey: version,
            Auth0ClientInfo.EnvironmentKey: env
        ]
        self.info = Auth0ClientInfo.generateValue(fromInfo: wrapped)
    }

    func addTelemetryHeader(request: NSMutableURLRequest) {
        if let value = self.value {
            request.setValue(value, forHTTPHeaderField: "Auth0-Client")
        } else {
            request.setValue(nil, forHTTPHeaderField: "Auth0-Client")
        }
    }

    func queryItemsWithTelemetry(queryItems: [URLQueryItem]) -> [URLQueryItem] {
        var items = queryItems
        if let value = self.value {
            items.append(URLQueryItem(name: "auth0Client", value: value))
        }
        return items
    }

    static func versionInformation() -> [String: Any] {
        let dict: [String: Any] = [
            Auth0ClientInfo.NameKey: Auth0ClientInfo.LibraryName,
            Auth0ClientInfo.VersionKey: version,
            Auth0ClientInfo.EnvironmentKey: Auth0ClientInfo.generateEnviroment()
        ]
        return dict
    }

    static func generateEnviroment() -> [String: String] {
        let platform = Auth0ClientInfo.osInfo()
        let env = [ "swift": Auth0ClientInfo.swiftVersion(),
                    platform.0: platform.1
        ]
        return env
    }

    static func generateValue(fromInfo info: [String: Any] = Auth0ClientInfo.versionInformation()) -> String? {
        let data = try? JSONSerialization.data(withJSONObject: info, options: [])
        return data?.a0_encodeBase64URLSafe()
    }

    static func swiftVersion() -> String {
        return "6.x"
    }

    static func osPlatform() -> String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(visionOS)
        return "visionOS"
        #else
        return "unknown"
        #endif
    }

    static func osInfo() -> (String, String) {
        return (self.osPlatform(), "\(ProcessInfo().operatingSystemVersion.majorVersion).\(ProcessInfo().operatingSystemVersion.minorVersion)")
    }
}

/// A type that can send the `Auth0-Client` header on every request to Auth0.
public protocol Trackable {

    /// The ``Auth0ClientInfo`` instance.
    var auth0ClientInfo: Auth0ClientInfo { get set }

}

public extension Trackable {

    /**
     Turn on/off sending the `Auth0-Client` header on every request to Auth0.
     By default we collect our libraries and SDKs versions to help us evaluate usage.
     
     - Parameter enabled: Flag to turn the `Auth0-Client` header on/off.
     */
    mutating func tracking(enabled: Bool) {
        self.auth0ClientInfo.enabled = enabled
    }

    /**
     Includes the name and version of the library/framework which has Auth0.swift as dependency.
     
     - Parameter name:    Name of library or framework that uses Auth0.swift.
     - Parameter version: Version of library or framework.
     */
    mutating func using(inLibrary name: String, version: String) {
        self.auth0ClientInfo.wrapped(inLibrary: name, version: version)
    }

}
