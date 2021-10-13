// swift-tools-version:5.2

import PackageDescription

var webAuthPlatforms: [Platform] = [.iOS, .macOS]

#if swift(>=5.5)
webAuthPlatforms.append(.macCatalyst)
#endif

let webAuthFlag = "WEB_AUTH_PLATFORM"
let webAuthCondition: BuildSettingCondition = .when(platforms: webAuthPlatforms)
let cSettings: [CSetting] = [.define(webAuthFlag, webAuthCondition)]
let swiftSettings: [SwiftSetting] = [.define(webAuthFlag, webAuthCondition)]

let package = Package(
    name: "Auth0",
    platforms: [.iOS(.v9), .macOS(.v10_11), .tvOS(.v9), .watchOS(.v2)],
    products: [.library(name: "Auth0", targets: ["Auth0"])],
    dependencies: [
        .package(name: "SimpleKeychain", url: "https://github.com/auth0/SimpleKeychain.git", .upToNextMajor(from: "0.12.0")),
        .package(name: "JWTDecode", url: "https://github.com/auth0/JWTDecode.swift.git", .upToNextMajor(from: "2.5.0")),
        .package(name: "Quick", url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "4.0.0")),
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
            dependencies: [
                "Auth0", 
                "Quick", 
                "Nimble", 
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
            ],
            path: "Auth0Tests",
            exclude: ["ObjectiveC"],
            cSettings: cSettings,
            swiftSettings: swiftSettings)
    ]
)
