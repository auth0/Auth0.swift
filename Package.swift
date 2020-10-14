// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Auth0",
    platforms: [.iOS(.v9), .macOS(.v10_11), .tvOS(.v9), .watchOS(.v2)],
    products: [.library(name: "Auth0", targets: ["Auth0"])],
    dependencies: [
        .package(url: "https://github.com/auth0/SimpleKeychain.git", .branch("chore/update-dependencies")),
        .package(url: "https://github.com/auth0/JWTDecode.swift.git", .branch("chore/update-dependencies")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0")),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .upToNextMajor(from: "9.0.0"))
    ],
    targets: [
        .target(
            name: "Auth0", 
            dependencies: ["SimpleKeychain", "JWTDecode", "Auth0ObjectiveC"], 
            path: "Auth0",
            exclude: ["ObjectiveC"],
            swiftSettings: [
                .define("WEB_AUTH_PLATFORM", .when(platforms: [.iOS, .macOS]))
            ]),
        .target(name: "Auth0ObjectiveC", path: "Auth0/ObjectiveC"),
        .testTarget(
            name: "Auth0Tests",
            dependencies: ["Auth0", "Quick", "Nimble", "OHHTTPStubsSwift"],
            path: "Auth0Tests",
            exclude: ["ObjectiveC"],
            swiftSettings: [
                .define("WEB_AUTH_PLATFORM", .when(platforms: [.iOS, .macOS]))
            ])
    ]
)