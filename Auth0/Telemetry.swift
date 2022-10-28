import Foundation

/// Generates and sets the `Auth0-Client` header.
public struct Telemetry {

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

    /// Initializer that generates a base64url-encoded value with telemetry data.
    public init() {
        self.info = Telemetry.generateValue()
    }

    mutating func wrapped(inLibrary name: String, version: String) {
        let info = Telemetry.versionInformation()
        var env = Telemetry.generateEnviroment()
        env[Telemetry.WrappedVersion] = info[Telemetry.VersionKey] as? String
        let wrapped: [String: Any] = [
            Telemetry.NameKey: name,
            Telemetry.VersionKey: version,
            Telemetry.EnvironmentKey: env
        ]
        self.info = Telemetry.generateValue(fromInfo: wrapped)
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
            Telemetry.NameKey: Telemetry.LibraryName,
            Telemetry.VersionKey: version,
            Telemetry.EnvironmentKey: Telemetry.generateEnviroment()
        ]
        return dict
    }

    static func generateEnviroment() -> [String: String] {
        let platform = Telemetry.osInfo()
        let env = [ "swift": Telemetry.swiftVersion(),
                    platform.0: platform.1
        ]
        return env
    }

    static func generateValue(fromInfo info: [String: Any] = Telemetry.versionInformation()) -> String? {
        let data = try? JSONSerialization.data(withJSONObject: info, options: [])
        return data?.a0_encodeBase64URLSafe()
    }

    static func swiftVersion() -> String {
        return "5.x"
    }

    static func osPlatform() -> String {
        #if os(iOS)
        return "iOS"
        #elseif os(OSX)
        return "macOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
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

    /// The ``Telemetry`` instance.
    var telemetry: Telemetry { get set }

}

public extension Trackable {

    /**
     Turn on/off sending the `Auth0-Client` header on every request to Auth0.
     By default we collect our libraries and SDKs versions to help us evaluate usage.
     
     - Parameter enabled: Flag to turn telemetry on/off.
     */
    mutating func tracking(enabled: Bool) {
        self.telemetry.enabled = enabled
    }

    /**
     Includes the name and version of the library/framework which has Auth0.swift as dependency.
     
     - Parameter name:    Name of library or framework that uses Auth0.swift.
     - Parameter version: Version of library or framework.
     */
    mutating func using(inLibrary name: String, version: String) {
        self.telemetry.wrapped(inLibrary: name, version: version)
    }

}
