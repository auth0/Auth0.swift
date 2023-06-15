// swift-tools-version:5.7

import PackageDescription

let webAuthPlatforms: [Platform] = [.iOS, .macOS, .macCatalyst]
let swiftSettings: [SwiftSetting] = [.define("WEB_AUTH_PLATFORM", .when(platforms: webAuthPlatforms))]

let package = Package(
    name: "Auth0",
    platforms: [.iOS(.v13), .macOS(.v11), .tvOS(.v13), .watchOS(.v7)],
    products: [.library(name: "Auth0", targets: ["Auth0"])],
    dependencies: [
        .package(url: "https://github.com/auth0/SimpleKeychain.git", .upToNextMajor(from: "1.1.0")),
        .package(url: "https://github.com/auth0/JWTDecode.swift.git", .upToNextMajor(from: "3.1.0")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "12.0.0")),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .upToNextMajor(from: "9.0.0"))
    ],
    targets: [
        .target(
            name: "Auth0", 
            dependencies: [
                .product(name: "SimpleKeychain", package: "SimpleKeychain"),
                .product(name: "JWTDecode", package: "JWTDecode.swift")
            ],
            path: "Auth0",
            exclude: ["Info.plist"],
            swiftSettings: swiftSettings),
        .testTarget(
            name: "Auth0Tests",
            dependencies: [
                "Auth0",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble"),
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
            ],
            path: "Auth0Tests",
            exclude: ["Info.plist", "Auth0.plist"],
            swiftSettings: swiftSettings)
    ]
)
