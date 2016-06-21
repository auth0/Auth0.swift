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

class Telemetry: NSObject {

    static let NameKey = "name"
    static let VersionKey = "version"
    static let WrappedVersion = "lib_version"

    static let NoVersion = "0.0.0"
    static let LibraryName = "Auth0.swift"

    static let sharedInstance = Telemetry()

    var enabled: Bool = true

    var info: String?

    var value: String? {
        get {
            return self.enabled ? self.info : nil
        }
    }

    override init() {
        self.info = Telemetry.generateValue()
    }

    func wrapped(inLibrary name: String, version: String) {
        let info = Telemetry.versionInformation()
        let wrapped = [
            Telemetry.NameKey: name,
            Telemetry.VersionKey: version,
            Telemetry.WrappedVersion: info[Telemetry.VersionKey] ?? Telemetry.NoVersion
        ]
        self.info = Telemetry.generateValue(fromInfo: wrapped)
    }

    func addTelemetryHeader(request request: NSMutableURLRequest) {
        if let value = self.value {
            request.setValue(value, forHTTPHeaderField: "Auth0-Client")
        } else {
            request.setValue(nil, forHTTPHeaderField: "Auth0-Client")
        }
    }

    func queryItemsWithTelemetry(queryItems queryItems: [NSURLQueryItem]) -> [NSURLQueryItem] {
        var items = queryItems
        if let value = self.value {
            items.append(NSURLQueryItem(name: "auth0Client", value: value))
        }
        return items
    }

    static func versionInformation(bundle bundle: NSBundle = NSBundle(forClass: Telemetry.classForCoder())) -> [String: String] {
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? Telemetry.NoVersion
        let dict = [
            Telemetry.NameKey: Telemetry.LibraryName,
            Telemetry.VersionKey: version,
            ]
        return dict
    }

    static func generateValue(fromInfo info: [String: String] = Telemetry.versionInformation()) -> String? {
        let data = try? NSJSONSerialization.dataWithJSONObject(info, options: [])
        return data?.a0_encodeBase64URLSafe()
    }
}