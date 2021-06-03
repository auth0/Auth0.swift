// swift-tools-version:5.2

import PackageDescription

let webAuthFlag: (name: String, condition: BuildSettingCondition) = ("WEB_AUTH_PLATFORM",
                                                                     .when(platforms: [.iOS, .macOS]))
let cSettings: [CSetting] = [.define(webAuthFlag.name, webAuthFlag.condition)]
let swiftSettings: [SwiftSetting] = [.define(webAuthFlag.name, webAuthFlag.condition)]

let package = Package(
    name: "Auth0",
    platforms: [.iOS(.v9), .macOS(.v10_11), .tvOS(.v9), .watchOS(.v2)],
    products: [.library(name: "Auth0", targets: ["Auth0"])],
    dependencies: [
        .package(name: "SimpleKeychain", url: "https://github.com/auth0/SimpleKeychain.git", .upToNextMajor(from: "0.12.0")),
        .package(name: "JWTDecode", url: "https://github.com/auth0/JWTDecode.swift.git", .upToNextMajor(from: "2.5.0")),
        .package(name: "Quick", url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "3.0.0")),
        .package(name: "Nimble", url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0")),
        .package(name: "OHHTTPStubs", url: "https://github.com/AliSoftware/OHHTTPStubs.git", .upToNextMajor(from: "9.0.0"))
    ],
    targets: [
        .target(
            name: "Auth0", 
            dependencies: ["SimpleKeychain", "JWTDecode", "Auth0ObjectiveC"], 
            path: "Auth0",
            exclude: ["ObjectiveC"],
            cSettings: cSettings,
            swiftSettings: swiftSettings),
        .target(name: "Auth0ObjectiveC", path: "Auth0/ObjectiveC", cSettings: cSettings),
        .testTarget(
            name: "Auth0Tests",
            dependencies: ["Auth0", "Quick", "Nimble", "OHHTTPStubsSwift"],
            path: "Auth0Tests",
            exclude: ["ObjectiveC"],
            cSettings: cSettings,
            swiftSettings: swiftSettings)
    ]
)
