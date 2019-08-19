// Telemetry.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

public struct Telemetry {

    static let NameKey = "name"
    static let VersionKey = "version"
    static let WrappedVersion = "core"
    static let EnvironmentKey = "env"

    static let NoVersion = "0.0.0"
    static let LibraryName = "Auth0.swift"

    var enabled: Bool = true

    var info: String?

    var value: String? {
        return self.enabled ? self.info : nil
    }

    public init() {
        self.info = Telemetry.generateValue()
    }

    mutating func wrapped(inLibrary name: String, version: String) {
        let info = Telemetry.versionInformation()
        var env = Telemetry.generateEnviroment()
        if let libVersion = info[Telemetry.VersionKey] as? String {
            env[Telemetry.WrappedVersion] = libVersion
        } else {
            env[Telemetry.WrappedVersion] =  Telemetry.NoVersion
        }
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

    static func versionInformation(bundle: Bundle = Bundle(for: Credentials.classForCoder())) -> [String: Any] {
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? Telemetry.NoVersion
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
        #if swift(>=5.0)
        return "5.x"
        #elseif swift(>=4.0)
        return "4.x"
        #elseif swift(>=3.0)
        return "3.x"
        #endif
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

public protocol Trackable {

    var telemetry: Telemetry { get set }

}

extension Trackable {
    /**
     Avoid Auth0.swift sending its version on every request to Auth0 API.
     By default we collect our libraries and SDKs versions to help us during support and evaluate usage.
     
     - parameter enabled: if Auth0.swift should send it's version on every request.
     */
    public mutating func tracking(enabled: Bool) {
        self.telemetry.enabled = enabled
    }

    /**
     Send the library/framework, that has Auth0.swift as dependency, when sending telemetry information
     
     - parameter name:    name of library or framework that uses Auth0.swift
     - parameter version: version of library or framework
     */
    public mutating func using(inLibrary name: String, version: String) {
        self.telemetry.wrapped(inLibrary: name, version: version)
    }
}
