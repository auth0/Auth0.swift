// swift-tools-version:5.3

import PackageDescription

var webAuthPlatforms: [Platform] = [.iOS, .macOS]

#if swift(>=5.5)
webAuthPlatforms.append(.macCatalyst)
#endif

let webAuthFlag = "WEB_AUTH_PLATFORM"
let webAuthCondition: BuildSettingCondition = .when(platforms: webAuthPlatforms)
let swiftSettings: [SwiftSetting] = [.define(webAuthFlag, webAuthCondition)]

let package = Package(
    name: "Auth0",
    platforms: [.iOS(.v12), .macOS(.v10_15), .tvOS(.v12), .watchOS("6.2")],
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
            dependencies: ["SimpleKeychain", "JWTDecode"], 
            path: "Auth0",
            exclude: ["Info.plist", "Info-tvOS.plist"],
            swiftSettings: swiftSettings),
        .testTarget(
            name: "Auth0Tests",
            dependencies: [
                "Auth0", 
                "Quick", 
                "Nimble", 
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
            ],
            path: "Auth0Tests",
            exclude: ["Info.plist", "Auth0.plist"],
            swiftSettings: swiftSettings)
    ]
)
